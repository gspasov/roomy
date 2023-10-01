defmodule Roomy.Models.InvitationTest do
  use Roomy.DataCase, async: true

  alias Roomy.Account
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.Invitation
  alias Roomy.Constants.InvitationStatus
  alias Roomy.Constants.RoomType

  require InvitationStatus
  require RoomType

  test "When an invitation is sent a room with type 'dm' is created", %{
    user1: user1,
    user2: user2
  } do
    sender_id = user1.id
    receiver_id = user2.id

    %Invitation{} =
      send_friend_request(
        sender_id,
        receiver_id,
        "It's a me, Mario!"
      )

    {:ok, %Room{name: room_name, type: room_type}} =
      Room.get_by(name: Account.build_room_name(sender_id, receiver_id))

    assert room_name == "#{user1.id}##{user2.id}"
    assert room_type == RoomType.dm()
  end

  test "Friend request cannot be updated with status 'pending'", %{user1: user1, user2: user2} do
    sender_id = user1.id
    receiver_id = user2.id

    %Invitation{id: invitation_id} =
      send_friend_request(
        sender_id,
        receiver_id,
        "It's a me, Mario!"
      )

    {:ok, %Invitation{}} = Account.answer_invitation(invitation_id, true)

    {:error, %Ecto.Changeset{errors: errors}} =
      Invitation.update(%Invitation.Update{
        id: invitation_id,
        status: InvitationStatus.pending()
      })

    assert errors[:status] ==
             {"cannot_be_pending",
              [error: "Status can only be changed to 'accepted' or 'rejected'."]}
  end

  test "User should have Invitations equal to the number of requests sent to him", %{
    user1: user1,
    user2: user2
  } do
    sender_id = user1.id
    receiver_id = user2.id

    send_friend_request(
      sender_id,
      receiver_id,
      "It's a me, Mario!"
    )

    invitations = Account.list_invitations(receiver_id)

    assert length(invitations) == 1
    [%Invitation{sender_id: request_sender_id}] = invitations
    assert request_sender_id == sender_id
  end

  test "If a friend request is accepted, users become friends", %{user1: user1, user2: user2} do
    sender_id = user1.id
    receiver_id = user2.id

    %Invitation{id: invitation_id} =
      send_friend_request(
        sender_id,
        receiver_id,
        "It's a me, Mario!"
      )

    {:ok, %Invitation{}} = Account.answer_invitation(invitation_id, true)
    {:ok, %Invitation{status: invitation_status}} = Invitation.get(invitation_id)

    assert invitation_status == InvitationStatus.accepted()

    {:ok, %User{friends: [%User{id: friend_id1}]}} = User.get(sender_id, [:friends, :rooms])
    {:ok, %User{friends: [%User{id: friend_id2}]}} = User.get(receiver_id, [:friends, :rooms])

    assert friend_id1 == receiver_id
    assert friend_id2 == sender_id
  end

  test "If a friend request is rejected, users do not become friends", %{
    user1: user1,
    user2: user2
  } do
    sender_id = user1.id
    receiver_id = user2.id

    %Invitation{id: invitation_id} =
      send_friend_request(
        sender_id,
        receiver_id,
        "It's a me, Mario!"
      )

    {:ok, %Invitation{}} = Account.answer_invitation(invitation_id, false)
    {:ok, %Invitation{status: invitation_status}} = Invitation.get(invitation_id)

    assert invitation_status == InvitationStatus.rejected()

    {:ok, %User{friends: friends1, rooms: rooms1}} = User.get(sender_id, [:friends, :rooms])
    {:ok, %User{friends: friends2, rooms: rooms2}} = User.get(receiver_id, [:friends, :rooms])

    assert friends1 == friends2
    assert friends1 == []

    assert rooms1 != []
    assert rooms2 == []
  end

  test "If a friend request is accepted invited User is added to the Room", %{
    user1: user1,
    user2: user2
  } do
    sender_id = user1.id
    receiver_id = user2.id

    %Invitation{id: invitation_id} =
      send_friend_request(
        sender_id,
        receiver_id,
        "It's a me, Mario!"
      )

    {:ok, %Invitation{status: invitation_status}} = Account.answer_invitation(invitation_id, true)

    assert invitation_status == InvitationStatus.accepted()

    {:ok, %User{rooms: [%Room{name: room_1}]}} = User.get(sender_id, [:rooms])
    {:ok, %User{rooms: [%Room{name: room_2}]}} = User.get(receiver_id, [:rooms])

    assert room_1 == "#{sender_id}##{receiver_id}"
    assert room_2 == "#{sender_id}##{receiver_id}"
  end
end
