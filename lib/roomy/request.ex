defmodule Roomy.Request do
  use TypedStruct

  typedstruct module: RegisterUser, enforce: true do
    field(:username, String.t())
    field(:display_name, String.t())
    field(:password, String.t())
  end

  typedstruct module: LoginUser, enforce: true do
    field(:username, String.t())
    field(:password, String.t())
  end

  typedstruct module: SendFriendRequest do
    field(:receiver_id, pos_integer(), enforce: true)
    field(:sender_id, pos_integer(), enforce: true)
    field(:invitation_message, String.t())
  end

  typedstruct module: SendMessage do
    field(:content, String.t(), enforce: true)
    field(:sender_id, pos_integer(), enforce: true)
    field(:sent_at, DateTime.t(), enforce: true)
    field(:room_id, pos_integer())
  end

  typedstruct module: ReadMessage, enforce: true do
    field(:message_id, pos_integer())
    field(:reader_id, pos_integer())
  end

  typedstruct module: FetchUnreadMessages do
    field(:reader_id, pos_integer(), enforce: true)
    field(:room_id, pos_integer())
  end

  typedstruct module: EditMessage, enforce: true do
    field(:message_id, pos_integer())
    field(:content, String.t())
    field(:edited_at, DateTime.t())
  end

  typedstruct module: CreateGroupChat do
    field(:participants_usernames, [String.t()], enforce: true)
    field(:sender_id, pos_integer(), enforce: true)
    field(:name, String.t(), enforce: true)
    field(:invitation_message, String.t())
  end

  typedstruct module: LeaveRoom, enforce: true do
    field(:user_id, pos_integer())
    field(:room_id, pos_integer())
  end
end
