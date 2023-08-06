defmodule Roomy.TestUtils do
  @moduledoc """
  Helper functions for the tests
  """

  alias Roomy.Account
  alias Roomy.Request
  alias Roomy.Models.User
  alias Roomy.Models.FriendRequest

  def create_user(username, display_name, password) do
    request = %Request.RegisterUser{
      username: username,
      display_name: display_name,
      password: password
    }

    {:ok, %User{} = user} = Account.register_user(request)

    user
  end

  def send_friend_request(sender_id, username, message) do
    friend_request = %Request.SendFriendRequest{
      sender_id: sender_id,
      username: username,
      message: message
    }

    {:ok, %FriendRequest{} = result} = Account.send_friend_request(friend_request)
    result
  end
end
