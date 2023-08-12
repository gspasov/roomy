defmodule Roomy.Request do
  use TypedStruct

  typedstruct module: RegisterUser, enforce: true do
    field(:username, String.t())
    field(:display_name, String.t())
    field(:password, String.t())
  end

  typedstruct module: SendFriendRequest do
    field(:receiver_username, String.t(), enforce: true)
    field(:message, String.t())
    field(:sender_id, pos_integer())
  end

  typedstruct module: SendMessage do
    field(:content, String.t(), enforce: true)
    field(:sender_id, pos_integer(), enforce: true)
    field(:sent_at, DateTime.t(), enforce: true)
    field(:room_id, pos_integer())
  end

  typedstruct module: ReadMessage do
    field(:message_id, String.t(), enforce: true)
    field(:reader_id, pos_integer(), enforce: true)
  end
end
