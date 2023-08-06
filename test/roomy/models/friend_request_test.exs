defmodule Roomy.Models.FriendRequestTest do
  use Roomy.DataCase, async: true

  alias Roomy.TestUtils
  alias Roomy.Account
  alias Roomy.Models.User
  alias Roomy.Models.FriendRequest
  alias Roomy.Models.FriendRequestStatus

  require FriendRequestStatus

  test "Friend request cannot be updated with status 'pending'" do
    %User{id: sender_id} = TestUtils.create_user("gspasov", "Georgi Spasov", "123456")
    %User{username: receiver_username} = TestUtils.create_user("toshko", "Todor Penev", "123456")

    %FriendRequest{id: friend_request_id} =
      TestUtils.send_friend_request(sender_id, receiver_username, "It's a me, Georgi!")

    {:ok, %FriendRequest{}} = Account.answer_friend_request(friend_request_id, true)

    {:error, %Ecto.Changeset{errors: errors}} =
      FriendRequest.update(friend_request_id, %FriendRequest.Update{
        status: FriendRequestStatus.pending()
      })

    assert errors[:status] ==
             {"cannot_be_pending",
              [error: "Status can only be changed to 'accepted' or 'rejected'."]}
  end
end
