defmodule Roomy.Bus.Event do
  @moduledoc """
  Events that are allowed to be send via the BUS
  """
  use TypedStruct

  alias Roomy.Bus
  alias Roomy.Bus.Topic
  alias Roomy.Bus.Event
  alias Roomy.Models.Message
  alias Roomy.Constants.InvitationStatus

  require Topic
  require InvitationStatus

  typedstruct module: UserStatusChange do
    field(:user_id, pos_integer())
    field(:status, String.t())
  end

  typedstruct module: UserJoin do
    field(:display_name, String.t())
  end

  typedstruct module: SubscribeTo do
    field(:topic, String.t())
    field(:user_id, pos_integer())
  end

  typedstruct module: FriendInvitationRequest do
    field(:receiver_id, pos_integer())
    field(:sender_id, pos_integer())
    field(:invitation_id, pos_integer())
  end

  typedstruct module: FriendInvitationResponse do
    field(:receiver_id, pos_integer())
    field(:sender_id, pos_integer())
    field(:invitation_id, pos_integer())
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

  @spec invitation_request(event :: Event.FriendInvitationRequest.t()) :: :ok
  def invitation_request(
        %Event.FriendInvitationRequest{
          receiver_id: receiver_id,
          invitation_id: invitation_id
        } = e
      ) do
    Bus.publish(Topic.invitation_request(receiver_id, invitation_id), e)
  end

  @spec invitation_response(event :: Event.FriendInvitationResponse.t()) :: :ok
  def invitation_response(
        %Event.FriendInvitationResponse{
          receiver_id: receiver_id,
          invitation_id: invitation_id
        } = e
      ) do
    Bus.publish(Topic.invitation_response(receiver_id, invitation_id), e)
  end

  @spec send_message(message :: Message.t()) :: :ok
  def send_message(%Message{room_id: room_id} = e) do
    Bus.publish(Topic.room(room_id), e)
  end

  @spec subscribe_to(event :: SubscribeTo.t()) :: :ok
  def subscribe_to(%SubscribeTo{user_id: user_id} = e) do
    Bus.publish(Topic.user(user_id), e)
  end
end
