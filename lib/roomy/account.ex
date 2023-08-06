defmodule Roomy.Account do
  @moduledoc false

  import Ecto.Query

  alias Roomy.Models.FriendRequestStatus
  alias Roomy.Repo
  alias Roomy.Request
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.Message
  alias Roomy.Models.FriendRequest
  alias Roomy.Models.UsersFriends
  alias Roomy.Models.UsersRooms

  require FriendRequestStatus

  @spec register_user(Request.RegisterUser.t()) ::
          {:ok, User.t()} | {:error, Ecto.Changeset.t()}
  def register_user(%Request.RegisterUser{
        username: username,
        display_name: d_name,
        password: password
      }) do
    %User{}
    |> User.registration_changeset(%{username: username, display_name: d_name, password: password})
    |> Repo.insert()
  end

  def send_friend_request(%Request.SendFriendRequest{
        sender_id: sender_id,
        username: username,
        message: message
      }) do
    with {:ok, %User{id: receiver_id}} <- User.get_by(username: username),
         {:ok, %FriendRequest{}} = result <-
           FriendRequest.create(%FriendRequest.Create{
             sender_id: sender_id,
             receiver_id: receiver_id,
             message: message
           }) do
      result
    end
  end

  def list_friend_requests(user_id) do
    Repo.all(FriendRequest, receiver_id: user_id)
  end

  def answer_friend_request(friend_request_id, accepted?) do
    status =
      if accepted?, do: FriendRequestStatus.accepted(), else: FriendRequestStatus.rejected()

    with {:ok, %FriendRequest{sender_id: sender_id, receiver_id: receiver_id}} = result <-
           FriendRequest.update(friend_request_id, %FriendRequest.Update{status: status}),
         {:ok, _} <- maybe_make_friends(accepted?, sender_id, receiver_id),
         {:ok, _} <- maybe_create_room(accepted?, sender_id, receiver_id) do
      result
    end
  end

  def maybe_make_friends(accepted?, sender_id, receiver_id)

  def maybe_make_friends(false, _, _), do: {:ok, nil}

  def maybe_make_friends(true, sender_id, receiver_id) do
    with {:ok, %UsersFriends{}} <-
           UsersFriends.create(%UsersFriends.Create{
             user1_id: sender_id,
             user2_id: receiver_id
           }),
         {:ok, %UsersFriends{}} <-
           UsersFriends.create(%UsersFriends.Create{
             user1_id: receiver_id,
             user2_id: sender_id
           }) do
      {:ok, nil}
    end
  end

  def maybe_create_room(accepted?, sender_id, receiver_id)

  def maybe_create_room(false, _, _), do: {:ok, nil}

  def maybe_create_room(true, sender_id, receiver_id) do
    room_name = build_room_name(sender_id, receiver_id)

    with {:ok, %Room{id: room_id} = room} <- Room.create(%Room.Create{name: room_name}),
         {:ok, %UsersRooms{}} <-
           UsersRooms.add_user_to_room(%UsersRooms.AddUserToRoom{
             user_id: sender_id,
             room_id: room_id
           }),
         {:ok, %UsersRooms{}} <-
           UsersRooms.add_user_to_room(%UsersRooms.AddUserToRoom{
             user_id: receiver_id,
             room_id: room_id
           }) do
      {:ok, room}
    end
  end

  def build_room_name(sender_id, receiver_id) do
    [first, second] = Enum.sort([sender_id, receiver_id])
    "#{first}#{second}"
  end
end
