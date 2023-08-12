defmodule Roomy.Models.FriendRequestTest do
  use Roomy.DataCase, async: true

  alias Roomy.TestUtils
  alias Roomy.Account
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.FriendRequest
  alias Roomy.Constants.FriendRequestStatus

  require FriendRequestStatus

  test "Friend request cannot be updated with status 'pending'", %{user1: user1, user2: user2} do
    sender_id = user1.id
    receiver_username = user2.username

    %FriendRequest{id: friend_request_id} =
      TestUtils.send_friend_request(sender_id, receiver_username, "It's a me, Mario!")

    {:ok, %FriendRequest{}} = Account.answer_friend_request(friend_request_id, true)

    {:error, %Ecto.Changeset{errors: errors}} =
      FriendRequest.update(friend_request_id, %FriendRequest.Update{
        status: FriendRequestStatus.pending()
      })

    assert errors[:status] ==
             {"cannot_be_pending",
              [error: "Status can only be changed to 'accepted' or 'rejected'."]}
  end

  test "User should have FriendRequests equal to the number of requests sent to him", %{
    user1: user1,
    user2: user2
  } do
    sender_id = user1.id
    receiver_id = user2.id
    receiver_username = user2.username

    TestUtils.send_friend_request(sender_id, receiver_username, "It's a me, Mario!")

    friend_requests = Account.list_friend_requests(receiver_id)

    assert length(friend_requests) == 1
    [%FriendRequest{sender_id: request_sender_id}] = friend_requests
    assert request_sender_id == sender_id
  end

  test "A friend request can be sent and confirmed", %{user1: user1, user2: user2} do
    sender_id = user1.id
    receiver_username = user2.username

    %FriendRequest{id: friend_request_id} =
      TestUtils.send_friend_request(sender_id, receiver_username, "It's a me, Mario!")

    {:ok, %FriendRequest{status: friend_request_status}} =
      Account.answer_friend_request(friend_request_id, true)

    assert friend_request_status == FriendRequestStatus.accepted()
  end

  test "A friend request can be sent and rejected", %{user1: user1, user2: user2} do
    sender_id = user1.id
    receiver_username = user2.username

    %FriendRequest{id: friend_request_id} =
      TestUtils.send_friend_request(sender_id, receiver_username, "It's a me, Mario!")

    {:ok, %FriendRequest{status: friend_request_status}} =
      Account.answer_friend_request(friend_request_id, false)

    assert friend_request_status == FriendRequestStatus.rejected()
  end

  test "If a friend request is accepted Users become friends and a room is created", %{
    user1: user1,
    user2: user2
  } do
    sender_id = user1.id
    receiver_id = user2.id
    receiver_username = user2.username

    %FriendRequest{id: friend_request_id} =
      TestUtils.send_friend_request(sender_id, receiver_username, "It's a me, Mario!")

    {:ok, %FriendRequest{status: friend_request_status}} =
      Account.answer_friend_request(friend_request_id, true)

    assert friend_request_status == FriendRequestStatus.accepted()

    {:ok, %User{friends: [%User{id: friend_id1}], rooms: [%Room{name: room_name}]}} =
      User.get(sender_id, [:friends, :rooms])

    {:ok, %User{friends: [%User{id: friend_id2}], rooms: [%Room{name: ^room_name}]}} =
      User.get(receiver_id, [:friends, :rooms])

    assert friend_id1 == receiver_id
    assert friend_id2 == sender_id

    assert room_name == "#{sender_id}#{receiver_id}"
  end

  test "If a friend request is rejected Users do not become friends and no Room is created", %{
    user1: user1,
    user2: user2
  } do
    sender_id = user1.id
    receiver_id = user2.id
    receiver_username = user2.username

    %FriendRequest{id: friend_request_id} =
      TestUtils.send_friend_request(sender_id, receiver_username, "It's a me, Mario!")

    {:ok, %FriendRequest{status: friend_request_status}} =
      Account.answer_friend_request(friend_request_id, false)

    assert friend_request_status == FriendRequestStatus.rejected()

    {:ok, %User{friends: friends, rooms: rooms}} = User.get(sender_id, [:friends, :rooms])
    {:ok, %User{friends: ^friends, rooms: ^rooms}} = User.get(receiver_id, [:friends, :rooms])

    assert friends == []
    assert rooms == []
  end
end
