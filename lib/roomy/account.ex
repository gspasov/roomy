defmodule Roomy.Account do
  @moduledoc false

  alias Roomy.Models.UserMessage
  alias Roomy.Bus
  alias Roomy.Models.Message
  alias Roomy.Repo
  alias Roomy.Request
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.FriendRequest
  alias Roomy.Models.UserFriend
  alias Roomy.Models.UserRoom
  alias Roomy.Constants.FriendRequestStatus

  require FriendRequestStatus

  @spec register_user(Request.RegisterUser.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def register_user(%Request.RegisterUser{
        username: username,
        display_name: display_name,
        password: password
      }) do
    User.create(%User.Register{
      username: username,
      display_name: display_name,
      password: password
    })
  end

  @spec send_friend_request(Roomy.Request.SendFriendRequest.t()) ::
          {:ok, FriendRequest.t()} | {:error, Ecto.Changeset.t()}
  def send_friend_request(%Request.SendFriendRequest{
        sender_id: sender_id,
        receiver_username: receiver_username,
        message: message
      }) do
    with {:ok, %User{id: receiver_id}} <- User.get_by(username: receiver_username),
         {:ok, %FriendRequest{}} = result <-
           FriendRequest.create(%FriendRequest.Create{
             sender_id: sender_id,
             receiver_id: receiver_id,
             message: message
           }) do
      result
    end
  end

  @spec list_friend_requests(user_id: pos_integer()) :: [FriendRequest.t()]
  def list_friend_requests(user_id) do
    FriendRequest.all(user_id)
  end

  @spec answer_friend_request(request_id :: pos_integer(), is_accepted :: boolean()) ::
          {:ok, FriendRequest.t()} | {:error, Ecto.Changeset.t()}
  def answer_friend_request(friend_request_id, accepted?) do
    status =
      if accepted? do
        FriendRequestStatus.accepted()
      else
        FriendRequestStatus.rejected()
      end

    Repo.transaction(fn ->
      with {:ok, %FriendRequest{sender_id: sender_id, receiver_id: receiver_id} = result} <-
             FriendRequest.update(friend_request_id, %FriendRequest.Update{status: status}),
           {:ok, _} <- maybe_make_friends(accepted?, sender_id, receiver_id),
           {:ok, _} <- maybe_create_room(accepted?, sender_id, receiver_id) do
        result
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @spec send_message(Request.SendMessage.t()) :: {:ok, Message.t()} | {:error, Ecto.Changeset.t()}
  def send_message(%Request.SendMessage{
        content: content,
        room_id: room_id,
        sender_id: sender_id,
        sent_at: sent_at
      }) do
    message = %Message.Create{
      content: content,
      room_id: room_id,
      sender_id: sender_id,
      sent_at: sent_at
    }

    Repo.transaction(fn ->
      with {:ok, %Room{users: users}} <- Room.get(room_id, :users),
           {:ok, %Message{id: message_id} = result} <- Message.create(message),
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

        result
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @spec fetch_unread_messages(pos_integer(), pos_integer()) :: [Message.t()]
  def fetch_unread_messages(reader_id, room_id) do
    UserMessage.all_unread(reader_id, room_id)
  end

  @spec read_message(Request.ReadMessage.t()) :: :ok | {:error, any()}
  def read_message(%Request.ReadMessage{message_id: message_id, reader_id: reader_id}) do
    with {:ok, %UserMessage{}} <-
           UserMessage.read(%UserMessage.Read{message_id: message_id, user_id: reader_id}) do
      :ok
    end
  end

  def build_room_name(sender_id, receiver_id) do
    [first, second] = Enum.sort([sender_id, receiver_id])
    "#{first}#{second}"
  end

  defp maybe_make_friends(accepted?, sender_id, receiver_id)

  defp maybe_make_friends(false, _, _), do: {:ok, nil}

  defp maybe_make_friends(true, sender_id, receiver_id) do
    with {:ok, %UserFriend{}} <-
           UserFriend.create(%UserFriend.Create{
             user1_id: sender_id,
             user2_id: receiver_id
           }),
         {:ok, %UserFriend{}} <-
           UserFriend.create(%UserFriend.Create{
             user1_id: receiver_id,
             user2_id: sender_id
           }) do
      {:ok, nil}
    end
  end

  defp maybe_create_room(accepted?, sender_id, receiver_id)

  defp maybe_create_room(false, _, _), do: {:ok, nil}

  defp maybe_create_room(true, sender_id, receiver_id) do
    room_name = build_room_name(sender_id, receiver_id)

    with {:ok, %Room{id: room_id} = room} <- Room.create(%Room.Create{name: room_name}),
         {:ok, %UserRoom{}} <-
           UserRoom.add_user_to_room(%UserRoom.AddUserToRoom{
             user_id: sender_id,
             room_id: room_id
           }),
         {:ok, %UserRoom{}} <-
           UserRoom.add_user_to_room(%UserRoom.AddUserToRoom{
             user_id: receiver_id,
             room_id: room_id
           }) do
      {:ok, room}
    end
  end
end
