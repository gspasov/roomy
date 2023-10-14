defmodule RoomyWeb.FriendsLive do
  use RoomyWeb, :live_view

  alias Roomy.Bus
  alias Roomy.Account
  alias Roomy.Request
  alias Roomy.Models.User
  alias Roomy.Models.Invitation

  require Logger
  require Bus.Topic

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full relative">
      <div :if={@visible_dialog == dialog_invite_request()}>
        <div class="absolute h-screen w-screen flex items-center justify-center z-10 bg-[#00000055]">
          <div class="p-2 mb-16 bg-dialog_info">
            <fieldset class="border border-gray-800 min-w-[32rem]">
              <legend class="px-2 text-center text-nav_text_dark font-bold">
                <%= @selected_user && @selected_user.display_name %>
              </legend>

              <form
                class="flex flex-col content-center focus:outline-none focus:ring focus:border-blue-300"
                phx-submit="dialog:invite_request:submit"
              >
                <fieldset class="m-2 pb-2 px-2 border border-gray-800">
                  <legend class="px-2 text-sm text-nav_text_dark font-bold">
                    Invitation message
                  </legend>
                  <input
                    id="dialog_friend_message_box"
                    type="text"
                    name="request_message"
                    minlength="2"
                    class="w-full px-2 py-1 bg-neutral-50 border-none text-white bg-default_background placeholder:text-slate-300 focus:outline-none focus:ring-0"
                    placeholder="Introduce yourself.."
                    phx-debounce="150"
                    autofocus
                  />
                </fieldset>
                <div class="flex gap-2 justify-end px-2 py-2">
                  <button
                    type="button"
                    class="border px-2 py-1 border-nav_text_dark shadow-sm min-w-[7rem] hover:bg-gray-500 active:bg-gray-600"
                    phx-click="dialog:cancel"
                  >
                    Cancel
                  </button>
                  <button class="border px-2 py-1 border-nav_text_dark shadow-sm min-w-[7rem] hover:bg-gray-500 active:bg-gray-600">
                    Send
                  </button>
                </div>
              </form>
            </fieldset>
          </div>
        </div>
      </div>
      <div :if={@visible_dialog == dialog_error()}>
        <div class="absolute h-screen w-screen flex items-center justify-center z-10 bg-[#00000055]">
          <div class="p-2 mb-16 bg-dialog_error">
            <fieldset class="border border-white min-w-[28rem]">
              <legend class="px-2 text-center text-highlight font-bold">
                Error
              </legend>
              <div class="flex flex-col p-4 gap-5 items-center">
                <p class="text-white font-medium"><%= @dialog_error_message %></p>
                <button
                  class="border px-2 py-1 text-highlight border-nav_text_dark shadow-sm min-w-[7rem] hover:bg-nav_text_dark active:bg-gray-600"
                  phx-click="dialog:cancel"
                >
                  Close
                </button>
              </div>
            </fieldset>
          </div>
        </div>
      </div>
      <div :if={@visible_dialog == dialog_invite_answer()}>
        <div class="absolute h-screen w-screen flex items-center justify-center z-10 bg-[#00000055]">
          <div class="p-2 mb-16 bg-dialog_info min-w-[32rem] max-w-[40rem]">
            <fieldset class="border border-gray-800 ">
              <legend class="px-2 text-center text-nav_text_dark font-bold">
                Would you like to become friends with <%= @selected_invitation.sender.display_name %>?
              </legend>
              <div :if={@selected_invitation.message} class="p-2">
                <p><%= @selected_invitation.message %></p>
              </div>
              <div class="flex gap-2 justify-end px-2 py-2">
                <button
                  type="button"
                  class="border px-2 py-1 border-nav_text_dark shadow-sm min-w-[7rem] hover:bg-gray-500 active:bg-gray-600"
                  phx-click="dialog:cancel"
                >
                  Ignore
                </button>
                <button
                  type="button"
                  class="border px-2 py-1 border-nav_text_dark shadow-sm min-w-[7rem] hover:bg-gray-500 active:bg-gray-600"
                  phx-click="dialog:invite_answer:reject"
                >
                  Decline
                </button>
                <button
                  type="button"
                  class="border px-2 py-1 border-nav_text_dark shadow-sm min-w-[7rem] hover:bg-gray-500 active:bg-gray-600"
                  phx-click="dialog:invite_answer:accept"
                >
                  Accept
                </button>
              </div>
            </fieldset>
          </div>
        </div>
      </div>
      <div class="h-full flex px-2 pb-2">
        <fieldset class="border border-gray-200 w-[25%]">
          <legend class="px-2 text-sm text-center text-nav_text_light font-bold">Friends</legend>
          <ul class="overflow-y-auto p-2 text-white font-semibold">
            <li
              :for={%User{id: user_id, display_name: display_name} <- @friends}
              key={user_id}
              class="flex justify-between px-2 hover:bg-nav_text_dark rounded-sm hover:text-highlight"
            >
              <span><%= display_name %></span>
            </li>
          </ul>
        </fieldset>
        <div class="w-[75%] pl-2 relative">
          <fieldset class="flex flex-col border border-gray-200 h-[40%]">
            <legend class="px-2 text-sm text-center text-nav_text_light font-bold">
              Find friends
            </legend>

            <fieldset class="m-2 pb-2 px-2 border border-gray-200">
              <legend class="px-2 text-sm text-nav_text_light font-bold">
                Friend name/username
              </legend>
              <form
                class="flex content-center focus:outline-none focus:ring focus:border-blue-300"
                phx-change="friend_box:change"
                onkeydown="return event.key != 'Enter';"
              >
                <input
                  id="friend_box"
                  type="text"
                  name="friend_name"
                  minlength="2"
                  class="grow px-2 py-1 bg-neutral-50 border-none text-white bg-default_background placeholder:text-slate-300 focus:outline-none focus:ring-0"
                  placeholder="Type a name.."
                  value={@friend_box}
                  autofocus
                />
              </form>
            </fieldset>
            <ul class="overflow-y-auto p-2 text-white font-semibold">
              <li
                :for={
                  %User{id: user_id, display_name: display_name, username: username} <- @found_users
                }
                id={"friend-#{user_id}"}
                key={user_id}
                phx-hook="MouseEvent"
                class="flex justify-between px-2 hover:bg-nav_text_dark rounded-sm hover:text-highlight"
              >
                <span><%= display_name %> <span class="text-xs">(<%= username %>)</span></span>
                <button
                  :if={@show_button_id == "friend-#{user_id}"}
                  class="flex items-center gap-2 text-white hover:text-green-500"
                  phx-click="open_dialog:create_friend_invitation"
                  phx-value-user_id={user_id}
                >
                  Request friendship <.icon name="hero-envelope" />
                </button>
              </li>
            </ul>
          </fieldset>
          <fieldset class="border border-gray-200 h-[60%]">
            <legend class="px-2 text-sm text-center text-nav_text_light font-bold">
              Pending invitations
            </legend>
            <ul class="overflow-y-auto p-2 text-white">
              <li
                :for={
                  %Invitation{
                    id: invitation_id,
                    seen: seen,
                    inserted_at: sent_at,
                    sender: %User{display_name: sender_name}
                  } <- @invitations
                }
                key={invitation_id}
                class={[
                  "flex justify-between px-2 hover:bg-nav_text_dark rounded-sm cursor-pointer hover:text-highlight",
                  if(seen, do: "", else: "font-semibold")
                ]}
                phx-click="open_dialog:answer_friend_invitation"
                phx-value-invitation_id={invitation_id}
              >
                <div class="flex gap-2 items-center">
                  <i :if={not seen} class="bi bi-envelope"></i>
                  <i :if={seen} class="bi bi-envelope-open"></i>
                  <p>Friend invitation from <%= sender_name %></p>
                </div>
                <span><%= format_date(sent_at, @timezone) %></span>
              </li>
            </ul>
          </fieldset>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, %{assigns: %{current_user: %User{id: user_id}}} = socket) do
    Bus.subscribe(Bus.Topic.invitation(user_id))

    new_socket =
      assign(socket,
        friend_box: "",
        dialog_error_message: "",
        found_users: [],
        friends: Account.get_user_friends(user_id),
        invitations: Account.get_user_invitations(user_id),
        show_button_id: nil,
        selected_user: nil,
        visible_dialog: nil,
        selected_invitation: nil
      )

    {:ok, new_socket}
  end

  @impl true
  def handle_event("friend_box:change", %{"friend_name" => name}, socket) do
    new_socket =
      if byte_size(name) >= 2 do
        found_users = Account.find_users_by_name(name)
        assign(socket, found_users: found_users, friend_box: name)
      else
        assign(socket, found_users: [], friend_box: name)
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "open_dialog:create_friend_invitation",
        %{"user_id" => user_id},
        %{assigns: %{current_user: %User{id: sender_id}, found_users: users}} = socket
      ) do
    receiver_id = String.to_integer(user_id)
    selected_user = Enum.find(users, fn %User{id: id} -> id == receiver_id end)

    new_socket =
      case Account.can_send_friend_invitation?(sender_id, receiver_id) do
        :ok ->
          assign(socket, visible_dialog: dialog_invite_request(), selected_user: selected_user)

        {:error, :already_friends} ->
          assign(socket,
            visible_dialog: dialog_error(),
            dialog_error_message: "You are already friends with #{selected_user.display_name}.",
            selected_user: selected_user
          )

        {:error, :invitation_already_sent} ->
          assign(socket,
            visible_dialog: dialog_error(),
            dialog_error_message: "Friend request has already been sent.",
            selected_user: selected_user
          )
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "open_dialog:answer_friend_invitation",
        %{"invitation_id" => id},
        %{assigns: %{current_user: %User{id: user_id}}} = socket
      ) do
    {:ok, %Invitation{} = invitation} = Invitation.update(id)

    new_socket =
      assign(socket,
        selected_invitation: invitation,
        visible_dialog: dialog_invite_answer(),
        invitations: Account.get_user_invitations(user_id)
      )

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("dialog:cancel", _params, socket) do
    {:noreply, assign(socket, visible_dialog: nil)}
  end

  @impl true
  def handle_event(
        "dialog:invite_request:submit",
        %{"request_message" => message},
        %{
          assigns: %{
            current_user: %User{id: sender_id},
            selected_user: %User{id: receiver_id}
          }
        } = socket
      ) do
    {:ok, %Invitation{}} =
      Account.send_friend_request(%Request.SendFriendRequest{
        invitation_message: message,
        receiver_id: receiver_id,
        sender_id: sender_id
      })

    {:noreply, assign(socket, visible_dialog: nil)}
  end

  @impl true
  def handle_event(
        "dialog:invite_answer:" <> answer,
        _params,
        %{
          assigns: %{
            friends: friends,
            current_user: %User{id: user_id},
            selected_invitation: %Invitation{id: invitation_id}
          }
        } = socket
      ) do
    accepted? =
      case answer do
        "accept" -> true
        "reject" -> false
      end

    {:ok, %Invitation{}} = Account.answer_invitation(invitation_id, accepted?)

    updated_friends =
      if accepted? do
        Account.get_user_friends(user_id)
      else
        friends
      end

    new_socket =
      assign(socket,
        visible_dialog: nil,
        selected_invitation: nil,
        friends: updated_friends,
        invitations: Account.get_user_invitations(user_id)
      )

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("hook:mouse_over", %{"id" => id}, socket) do
    {:noreply, assign(socket, show_button_id: id)}
  end

  @impl true
  def handle_event("hook:mouse_out", _params, socket) do
    {:noreply, assign(socket, show_button_id: nil)}
  end

  @impl true
  def handle_info(
        {Bus, %Bus.Event.FriendInvitationRequest{sender_id: sender_id}},
        %{assigns: %{current_user: %User{id: user_id}}} = socket
      ) do
    {:ok, %User{display_name: name}} = User.get(sender_id, [])

    new_socket =
      socket
      |> put_flash(:info, "#{name} sent you a friend request!")
      |> assign(invitations: Account.get_user_invitations(user_id))

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(
        {Bus, %Bus.Event.FriendInvitationAnswer{sender_id: sender_id}},
        %{assigns: %{current_user: %User{id: user_id}}} = socket
      ) do
    {:ok, %User{display_name: name}} = User.get(sender_id, [])

    new_socket =
      socket
      |> put_flash(:info, "#{name} accepted your friend request! Now you can chat together.")
      |> assign(friends: Account.get_user_friends(user_id))

    {:noreply, new_socket}
  end

  defp dialog_invite_answer, do: "dialog_invite_answer"
  defp dialog_invite_request, do: "dialog_invite_request"
  defp dialog_error, do: "dialog_error"

  defp format_date(date_time, timezone) do
    date_time
    |> Timex.Timezone.convert(timezone)
    |> Timex.format("%-H:%M / %d %B", :strftime)
    |> case do
      {:ok, formatted_date} ->
        formatted_date

      {:error, reason} ->
        Logger.warn("#{__MODULE__} Failed to format datetime with #{inspect(reason)}")
        Calendar.strftime(date_time, "%d %B")
    end
  end
end
