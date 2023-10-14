defmodule Roomy.TestUtils do
  @moduledoc """
  Helper functions for the tests
  """

  alias Roomy.Bus
  alias Roomy.Request
  alias Roomy.Account
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.Message
  alias Roomy.Models.Invitation

  def send_friend_request(sender_id, receiver_id, message) do
    invitation = %Request.SendFriendRequest{
      sender_id: sender_id,
      receiver_id: receiver_id,
      invitation_message: message
    }

    {:ok, %Invitation{} = result} = Account.send_friend_request(invitation)
    result
  end

  def subscribe_to_topic(topic) do
    Task.async(fn ->
      Bus.subscribe(topic)

      receive do
        {Bus, _} = message -> message
      end
    end)
  end

  def strip_unnecessary_fields(model)

  def strip_unnecessary_fields(%Message{} = message) do
    message
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> Map.delete(:inserted_at)
    |> Map.delete(:updated_at)
    |> Map.delete(:users_messages)
    |> Map.delete(:room)
    |> Map.delete(:sender)
  end

  def strip_unnecessary_fields(%User{} = user) do
    user
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> Map.delete(:id)
    |> Map.delete(:hashed_password)
    |> Map.delete(:rooms)
    |> Map.delete(:password)
    |> Map.delete(:messages)
    |> Map.delete(:invitations)
    |> Map.delete(:friends)
    |> Map.delete(:tokens)
    |> Map.delete(:inserted_at)
    |> Map.delete(:updated_at)
  end

  def strip_unnecessary_fields(%Room{} = entry) do
    entry
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> Map.delete(:inserted_at)
    |> Map.delete(:updated_at)
    |> Map.delete(:users)
    |> Map.delete(:messages)
    |> Map.delete(:invitation)
  end

  def strip_unnecessary_fields(%Invitation{} = entry) do
    invitation =
      entry
      |> Map.from_struct()
      |> Map.delete(:id)
      |> Map.delete(:__meta__)
      |> Map.delete(:sender)
      |> Map.delete(:receiver)
      |> Map.delete(:receiver_id)
      |> Map.delete(:updated_at)
      |> Map.delete(:inserted_at)

    %{
      invitation
      | room:
          entry.room
          |> Map.from_struct()
          |> Map.delete(:__meta__)
          |> Map.delete(:inserted_at)
          |> Map.delete(:updated_at)
          |> Map.delete(:users)
          |> Map.delete(:messages)
          |> Map.delete(:invitation)
    }
  end
end
