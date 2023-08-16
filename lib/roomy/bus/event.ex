defmodule Roomy.Bus.Event do
  @moduledoc """
  Events that are allowed to be send via the BUS
  """
  use TypedStruct

  alias Roomy.Bus
  alias Roomy.Bus.Topic
  alias Roomy.Bus.Event
  alias Roomy.Constants.InvitationStatus

  require Topic
  require InvitationStatus

  typedstruct module: Message do
    field(:message_id, pos_integer())
    field(:sender_id, pos_integer())
    field(:room_id, pos_integer())
    field(:content, String.t())
    field(:sent_at, DateTime.t())
  end

  typedstruct module: UserStatusChange do
    field(:user_id, pos_integer())
    field(:status, String.t())
  end

  typedstruct module: UserJoin do
    field(:user_id, pos_integer())
    field(:username, String.t())
    field(:display_name, String.t())
  end

  typedstruct module: SendFriendRequest do
    field(:user_id, pos_integer())
    field(:request_id, pos_integer())
  end

  @spec new_user_join(event :: UserJoin.t()) :: :ok
  def new_user_join(e) do
    Bus.publish(Topic.system(), e)
  end

  @spec user_status_change(event :: Event.UserStatusChange.t()) :: :ok
  def user_status_change(%Event.UserStatusChange{user_id: user_id, status: status} = e)
      when InvitationStatus.is_allowed_status(status) do
    Bus.publish(Topic.user(user_id), e)
  end

  @spec send_friend_request(event :: Event.SendFriendRequest.t()) :: :ok
  def send_friend_request(%Event.SendFriendRequest{user_id: user_id} = e) do
    Bus.publish(Topic.user(user_id), e)
  end

  @spec send_message(event :: Event.Message.t()) :: :ok
  def send_message(%Event.Message{room_id: room_id} = e) do
    Bus.publish(Topic.message(room_id), e)
  end
end
