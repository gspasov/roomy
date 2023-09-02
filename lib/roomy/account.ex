defmodule Roomy.Account do
  @moduledoc false

  alias Roomy.Models.UserMessage
  alias Roomy.Bus
  alias Roomy.Models.Message
  alias Roomy.Repo
  alias Roomy.Utils
  alias Roomy.Request
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.Invitation
  alias Roomy.Models.UserFriend
  alias Roomy.Models.UserRoom
  alias Roomy.Models.UserToken
  alias Roomy.Constants.InvitationStatus
  alias Roomy.Constants.RoomType
  alias Roomy.Constants.MessageType

  require InvitationStatus
  require RoomType
  require MessageType
  require Logger

  def get_user_by_session_token(token) do
    User.get_by_session_token(token)
  end

  def create_session_token(%User{} = user) do
    UserToken.create_session_token(user)
  end

  def delete_user_session_token(token) do
    Repo.delete_all(UserToken.token_and_context_query(token, "session"))
    :ok
  end

  def get_user_by_username_and_password(username, password) do
    with {:ok, %User{} = user} <- User.get_by(username: username),
         true <- User.valid_password?(user, password) do
      {:ok, user}
    else
      _ -> {:error, :not_found}
    end
  end

  def change_user_registration(%User{} = user, attrs \\ %{}) do
    User.registration_changeset(user, attrs, hash_password: false)
  end

  def change_user_username(%User{} = user, attrs \\ %{}) do
    User.username_changeset(user, attrs)
  end

  def change_user_password(%User{} = user, attrs \\ %{}) do
    User.password_changeset(user, attrs, hash_password: false)
  end

  def apply_user_username(%User{} = user, password, attrs) do
    user
    |> User.username_changeset(attrs)
    |> User.validate_current_password(password)
    |> Ecto.Changeset.apply_action(:update)
  end

  def update_user_username(%User{} = user, password, attrs) do
    changeset =
      user
      |> User.username_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, ["session"]))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: %User{} = user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  def update_user_password(%User{} = user, password, attrs) do
    changeset =
      user
      |> User.password_changeset(attrs)
      |> User.validate_current_password(password)

    Ecto.Multi.new()
    |> Ecto.Multi.update(:user, changeset)
    |> Ecto.Multi.delete_all(:tokens, UserToken.user_and_contexts_query(user, :all))
    |> Repo.transaction()
    |> case do
      {:ok, %{user: user}} -> {:ok, user}
      {:error, :user, changeset, _} -> {:error, changeset}
    end
  end

  @spec register_user(map()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def register_user(register_params) do
    User.create(register_params)
  end

  @spec login_user(Request.LoginUser.t()) :: {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def login_user(%Request.LoginUser{username: username, password: password}) do
    with {:ok, %User{} = user} = result <- User.get_by(username: username),
         :ok <- Utils.check(User.valid_password?(user, password), :invalid_password) do
      result
    end
  end

  @spec send_friend_request(Roomy.Request.SendFriendRequest.t()) ::
          {:ok, Invitation.t()} | {:error, Ecto.Changeset.t()}
  def send_friend_request(%Request.SendFriendRequest{
        sender_id: sender_id,
        invitation_message: message,
        receiver_username: receiver_username
      }) do
    room_params =
      &%Room.New{
        name: build_room_name(sender_id, &1),
        type: RoomType.dm()
      }

    user_room_params =
      &%UserRoom.New{
        room_id: &1,
        user_id: sender_id
      }

    invitation_params =
      &%Invitation.New{
        message: message,
        sender_id: sender_id,
        room_id: &1,
        receiver_id: &2
      }

    Repo.tx(fn ->
      with {:ok, %User{id: receiver_id}} <-
             User.get_by(username: receiver_username),
           {:ok, %Room{id: room_id}} <- Room.create(room_params.(receiver_id)),
           {:ok, %UserRoom{}} <-
             UserRoom.add_user_to_room(user_room_params.(room_id)),
           {:ok, %Invitation{}} = invitation <-
             Invitation.create(invitation_params.(room_id, receiver_id)) do
        invitation
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @spec list_invitations(user_id: pos_integer()) :: [Invitation.t()]
  def list_invitations(user_id) do
    Invitation.all(user_id)
  end

  @spec answer_invitation(request_id :: pos_integer(), is_accepted :: boolean()) ::
          {:ok, Invitation.t()} | {:error, Ecto.Changeset.t()}
  def answer_invitation(invitation_id, accepted?) do
    status =
      if accepted? do
        InvitationStatus.accepted()
      else
        InvitationStatus.rejected()
      end

    Repo.tx(fn ->
      with {:ok,
            %Invitation{
              sender_id: sender_id,
              receiver_id: receiver_id,
              receiver: receiver,
              room: %Room{id: room_id, type: room_type}
            }} <- Invitation.get(invitation_id, [:room, :receiver]),
           {:ok, %Invitation{}} = invitation <-
             Invitation.update(%Invitation.Update{
               id: invitation_id,
               status: status
             }),
           {:ok, _} <-
             maybe_become_friends(accepted?, room_type, sender_id, receiver_id),
           {:ok, _} <- maybe_join_room(accepted?, receiver_id, room_id),
           {:ok, _} <- maybe_add_system_message(accepted?, room_type, receiver, room_id) do
        invitation
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @spec send_message(Request.SendMessage.t()) ::
          {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def send_message(%Request.SendMessage{
        content: content,
        room_id: room_id,
        sender_id: sender_id,
        sent_at: sent_at
      }) do
    create_params = %Message.New{
      content: content,
      room_id: room_id,
      sender_id: sender_id,
      sent_at: sent_at
    }

    Repo.tx(fn ->
      with {:ok, %Room{users: users}} <- Room.get(room_id, :users),
           {:ok, %Message{id: message_id}} = message <-
             Message.create(create_params),
           UserMessage.create(%UserMessage.Multi{
             user_ids: Enum.map(users, fn %User{id: id} -> id end) -- [sender_id],
             message_id: message_id
           }) do
        Bus.Event.send_message(%Bus.Event.Message{
          content: content,
          room_id: room_id,
          sender_id: sender_id,
          sent_at: sent_at,
          message_id: message_id
        })

        message
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @spec fetch_unread_messages(Request.FetchUnreadMessages.t()) :: [Message.t()]
  def fetch_unread_messages(%Request.FetchUnreadMessages{reader_id: reader_id, room_id: room_id}) do
    Message.all_unread(%Message.Where{reader_id: reader_id, room_id: room_id})
  end

  @spec read_message(Request.ReadMessage.t()) :: :ok | {:error, any()}
  def read_message(%Request.ReadMessage{
        message_id: message_id,
        reader_id: reader_id
      }) do
    with {:ok, %UserMessage{}} <-
           UserMessage.read(%UserMessage.Read{
             message_id: message_id,
             user_id: reader_id
           }) do
      :ok
    end
  end

  @spec edit_message(Request.EditMessage.t()) :: :ok | {:error, any()}
  def edit_message(%Request.EditMessage{
        message_id: message_id,
        content: new_content,
        edited_at: edited_at
      }) do
    edit_message_params = %Message.Edit{
      id: message_id,
      content: new_content,
      edited_at: edited_at
    }

    Repo.tx(fn ->
      with [_ | _] = user_messages <- UserMessage.all(message_id),
           :ok <-
             user_messages
             |> message_is_unread_by_everyone()
             |> Utils.check(:message_is_read),
           {:ok, %Message{}} <- Message.edit(edit_message_params) do
        :ok
      end
    end)
  end

  @spec delete_message(pos_integer()) ::
          {:ok, Message.t()} | {:error, Ecto.Changeset.t(Message.t())}
  def delete_message(message_id) do
    Message.delete(message_id)
  end

  @spec create_group_chat(Request.CreateGroupChat.t()) ::
          {:ok, Room.t()} | {:error, {:user_not_found, String.t()} | Ecto.Changeset.t(any())}
  def create_group_chat(
        %Request.CreateGroupChat{
          name: group_name,
          sender_id: sender_id,
          invitation_message: message,
          participants_usernames: participants_usernames
        } = request
      ) do
    room_params = %Room.New{
      name: group_name,
      type: RoomType.group()
    }

    find_participants = fn usernames ->
      Enum.reduce_while(usernames, {:ok, []}, fn username, {:ok, users} ->
        case User.get_by(username: username) do
          {:ok, %User{} = user} -> {:cont, {:ok, [user | users]}}
          {:error, _} -> {:halt, {:error, {:user_not_found, username}}}
        end
      end)
    end

    filter_participants = fn %User{friends: sender_friends}, participants ->
      Enum.reduce(participants, {[], []}, fn %User{id: user_id} = user,
                                             {friends, invited_users} ->
        sender_friends
        |> Enum.any?(fn %User{id: id} -> id == user_id end)
        |> case do
          true -> {[user | friends], invited_users}
          false -> {friends, [user | invited_users]}
        end
      end)
    end

    add_users_to_room = fn users, room_id ->
      Enum.each(users, fn %User{id: user_id} ->
        {:ok, %UserRoom{}} =
          UserRoom.add_user_to_room(%UserRoom.New{
            room_id: room_id,
            user_id: user_id
          })
      end)
    end

    create_invitations = fn users, room_id ->
      Enum.each(users, fn %User{id: user_id} ->
        {:ok, %Invitation{}} =
          Invitation.create(%Invitation.New{
            message: message,
            sender_id: sender_id,
            room_id: room_id,
            receiver_id: user_id
          })
      end)
    end

    Repo.tx(fn ->
      with {:ok, participants} <- find_participants.(participants_usernames),
           {:ok, %User{} = sender} <- User.get(sender_id, [:friends]),
           {:ok, %Room{id: room_id}} = room <- Room.create(room_params),
           {sender_friends, invited_users} <-
             filter_participants.(sender, participants),
           :ok <- add_users_to_room.([sender | sender_friends], room_id),
           :ok <- create_invitations.(invited_users, room_id) do
        room
      else
        {:error, reason} ->
          Logger.error(
            "Failed to create group chat for #{inspect(request)} with #{inspect(reason)}"
          )

          Repo.rollback(reason)
      end
    end)
  end

  @spec leave_room(Request.LeaveRoom.t()) ::
          {:ok, UserRoom.t()} | {:error, Ecto.Changeset.t(any())}
  def leave_room(%Request.LeaveRoom{user_id: user_id, room_id: room_id} = request) do
    user_room_params = %UserRoom.New{user_id: user_id, room_id: room_id}

    system_message_params =
      &%Message.New{
        content: "User #{&1} has left the group",
        room_id: room_id,
        type: MessageType.system_group_leave(),
        sent_at: DateTime.utc_now()
      }

    Repo.tx(fn ->
      with {:ok, %Room{type: RoomType.group()}} <- Room.get(room_id),
           {:ok, %UserRoom{}} = user_room <- UserRoom.delete(user_room_params),
           {:ok, %User{display_name: name}} <- User.get(user_id),
           {:ok, %Message{}} <- Message.create(system_message_params.(name)) do
        user_room
      else
        {:error, reason} ->
          Logger.error("Failed to leave room for #{inspect(request)} with #{inspect(reason)}")
          Repo.rollback(reason)
      end
    end)
  end

  @spec build_room_name(pos_integer(), pos_integer()) :: String.t()
  def build_room_name(sender_id, receiver_id) do
    [first, second] = Enum.sort([sender_id, receiver_id])
    "#{first}#{second}"
  end

  defp message_is_unread_by_everyone(user_messages) do
    Enum.all?(user_messages, fn %UserMessage{seen: seen} -> seen == false end)
  end

  defp maybe_become_friends(accepted?, invitation_type, sender_id, receiver_id)

  defp maybe_become_friends(true, RoomType.dm(), sender_id, receiver_id) do
    params_1 = %UserFriend.New{
      user1_id: sender_id,
      user2_id: receiver_id
    }

    params_2 = %UserFriend.New{
      user1_id: receiver_id,
      user2_id: sender_id
    }

    with {:ok, %UserFriend{}} <- UserFriend.create(params_1),
         {:ok, %UserFriend{}} <- UserFriend.create(params_2) do
      {:ok, nil}
    end
  end

  defp maybe_become_friends(_, _, _, _), do: {:ok, nil}

  defp maybe_join_room(accepted?, receiver_id, room_id)

  defp maybe_join_room(true, receiver_id, room_id) do
    params = %UserRoom.New{
      user_id: receiver_id,
      room_id: room_id
    }

    with {:ok, %UserRoom{}} <- UserRoom.add_user_to_room(params) do
      {:ok, nil}
    end
  end

  defp maybe_join_room(_, _, _), do: {:ok, nil}

  defp maybe_add_system_message(accepted?, room_type, receiver, room_id)

  defp maybe_add_system_message(true, RoomType.group(), %User{display_name: name}, room_id) do
    system_message_params = %Message.New{
      content: "User #{name} has joined the group",
      room_id: room_id,
      type: MessageType.system_group_join(),
      sent_at: DateTime.utc_now()
    }

    with {:ok, %Message{}} <- Message.create(system_message_params) do
      {:ok, nil}
    end
  end

  defp maybe_add_system_message(_, _, _, _), do: {:ok, nil}
end
