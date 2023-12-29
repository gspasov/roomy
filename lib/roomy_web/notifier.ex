defmodule RoomyWeb.Notifier do
  @moduledoc """
  Hook for handling Bus.Event messages and handle notifications in the system
  """
  import Phoenix.LiveView

  alias Roomy.Bus.Event.SubscribeTo
  alias Roomy.Account
  alias Roomy.Bus
  alias Roomy.Models.Invitation
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.Message

  require Bus.Topic
  require Logger

  def on_mount(_name, _params, _session, %{assigns: %{current_user: %User{id: user_id}}} = socket) do
    rooms = Account.get_user_chat_rooms(user_id)

    Bus.subscribe(Bus.Topic.user(user_id))
    Bus.subscribe(Bus.Topic.system())
    Bus.subscribe(Bus.Topic.invitation_all(user_id))

    Enum.each(rooms, fn %Room{id: room_id} ->
      room_id
      |> Bus.Topic.room()
      |> Bus.subscribe()
    end)

    new_socket =
      socket
      |> Phoenix.Component.assign_new(:current_room, fn -> nil end)
      |> attach_hook(:message_handler, :handle_info, &maybe_handle_message/2)

    {:cont, new_socket}
  end

  defp maybe_handle_message({Bus, %Bus.Event.UserJoin{display_name: name}}, socket) do
    new_socket = put_flash(socket, :info, "New user by the name of '#{name}' has joined Roomy!")

    {:cont, new_socket}
  end

  defp maybe_handle_message(
         {Bus, %Bus.Event.FriendInvitationRequest{sender_id: sender_id}},
         socket
       ) do
    {:ok, %User{display_name: name}} = User.get(sender_id, [])

    new_socket = put_flash(socket, :info, "#{name} sent you a friend request!")

    {:cont, new_socket}
  end

  defp maybe_handle_message(
         {Bus,
          %Bus.Event.FriendInvitationResponse{sender_id: sender_id, invitation_id: invitation_id}},
         socket
       ) do
    {:ok, %User{display_name: name}} = User.get(sender_id, [])
    {:ok, %Invitation{room_id: room_id}} = Invitation.get(invitation_id, [])

    room_id
    |> Bus.Topic.room()
    |> Bus.subscribe()

    new_socket =
      put_flash(
        socket,
        :info,
        "#{name} accepted your friend request! Now you can chat together."
      )

    {:cont, new_socket}
  end

  defp maybe_handle_message(
         {Bus, %Message{sender: %User{id: sender_id}}},
         %{assigns: %{current_user: %User{id: sender_id}}} = socket
       ) do
    # Don't show notification message to the sender
    {:cont, socket}
  end

  defp maybe_handle_message(
         {Bus, %Message{room: %Room{id: room_id}}},
         %{assigns: %{current_room: %Room{id: room_id}}} = socket
       ) do
    # Don't show notification if User is currently in the Room
    {:cont, socket}
  end

  defp maybe_handle_message(
         {Bus, %Message{content: message, sender: %User{display_name: user_name}}},
         socket
       ) do
    {:cont, put_flash(socket, :info, "#{user_name}: #{message}")}
  end

  defp maybe_handle_message({Bus, %SubscribeTo{topic: topic}}, socket) do
    Bus.subscribe(topic)
    {:cont, socket}
  end

  defp maybe_handle_message({Bus, unhandled_message}, socket) do
    Logger.warn("#{__MODULE__} Unhandled message: #{inspect(unhandled_message)}")
    {:cont, socket}
  end
end
