defmodule Roomy.Factory do
  use ExMachina.Ecto, repo: Roomy.Repo

  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.UserRoom
  alias Roomy.Models.UserFriend
  alias Roomy.Models.UserToken
  alias Roomy.Models.Message
  alias Roomy.Models.UserMessage
  alias Roomy.Models.Invitation

  require Roomy.Constants.RoomType, as: RoomType
  require Roomy.Constants.MessageType, as: MessageType
  require Roomy.Constants.InvitationStatus, as: InvitationStatus

  def user_factory do
    password = build(:password)

    %User{
      display_name: "Peter Pan",
      hashed_password: User.hash_password(password || valid_user_password()),
      password: password,
      username: sequence("username")
    }
  end

  def password_factory(attrs) do
    Map.get(attrs, :value, nil)
  end

  def room_factory do
    %Room{
      name: "room_name",
      type: RoomType.dm()
    }
  end

  def user_room_factory do
    %UserRoom{
      user: build(:user),
      room: build(:room)
    }
  end

  def user_friend_factory do
    %UserFriend{
      user1: build(:user),
      user2: build(:user)
    }
  end

  def invitation_factory do
    %Invitation{
      room: build(:room),
      message: sequence("invitation_message"),
      seen: false,
      status:
        sequence(:status, [
          InvitationStatus.pending(),
          InvitationStatus.accepted(),
          InvitationStatus.rejected()
        ])
    }
  end

  def message_factory do
    %Message{
      content: "some message",
      deleted: false,
      edited: false,
      room: build(:room),
      sender: build(:user),
      type: MessageType.normal(),
      sent_at: DateTime.utc_now()
    }
  end

  def user_message_factory do
    %UserMessage{
      message: build(:message),
      user: build(:user),
      seen: false
    }
  end

  def user_token_factory do
    %UserToken{
      token: "token",
      user: build(:user),
      context: "session"
    }
  end

  def unique_user_username do
    unique_id = System.unique_integer() |> to_string() |> String.slice(-10..-1)
    "user_" <> unique_id
  end

  def valid_user_password, do: "valid_password"
end
