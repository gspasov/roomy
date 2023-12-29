defmodule RoomyWeb.HomeLive do
  use RoomyWeb, :live_view

  alias Roomy.Bus
  alias Roomy.Account
  alias Roomy.Request
  alias Roomy.Constants.RoomType
  alias Roomy.Constants.InvitationStatus
  alias Roomy.Models.Invitation
  alias Roomy.Models.Message
  alias Roomy.Models.Room
  alias Roomy.Models.User
  alias RoomyWeb.Components.Svg
  alias RoomyWeb.Components.ContextMenu

  require Bus.Topic
  require RoomType
  require InvitationStatus

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-full">
      <%!-- Sidebar Menu --%>
      <div class={[
        "fixed top-0 left-0 w-96 h-full z-10 border-r transform transition-all duration-300",
        if(@sidebar_menu_open, do: "translate-x-0", else: "-translate-x-full")
      ]}>
        <%!-- Sidebar Menu header --%>
        <div class="flex items-center gap-2 px-4 py-4 bg-gray-50 border-b">
          <button
            phx-click="sidebar_menu:close"
            class="flex items-center justify-center hover:bg-slate-200 aspect-square w-10 h-10 rounded-full"
          >
            <Svg.arrow_left />
          </button>
          <h2 class="font-bold text-xl">
            <%= @sidebar_menu &&
              @sidebar_menu
              |> String.split("_")
              |> Enum.join(" ")
              |> String.capitalize() %>
          </h2>
        </div>
        <%!-- Sidebar Menu body --%>
        <div :if={@sidebar_menu == "profile"} class="h-full bg-red-100">profile</div>
        <div :if={@sidebar_menu == "new_group"} class="h-full bg-yellow-100">new group</div>
        <div :if={@sidebar_menu == "invitations"} class="h-full bg-white">
          <ul class="overflow-y-auto">
            <li
              :for={invitation <- @invitations}
              key={"message-request-#{invitation.id}"}
              phx-click="select_invitation"
              phx-value-invitation_id={invitation.id}
              class={[
                "flex justify-between items-center gap-4 py-5 px-8 border-b hover:bg-blue-50 h-20 cursor-pointer",
                if(invitation == @selected_invitation, do: "bg-blue-50", else: "")
              ]}
            >
              <img
                src={avatar_src(get_room_name(invitation.room, @current_user))}
                class="rounded-full h-10 w-10"
              />
              <div class="flex flex-col w-36 grow">
                <span class="font-medium text-slate-600">
                  <%= get_room_name(invitation.room, @current_user) %>
                </span>
              </div>
            </li>
          </ul>
        </div>
      </div>
      <%!-- Sidebar --%>
      <div class="flex flex-col w-96 border-r">
        <div class="flex flex-col bg-gray-50 py-4 px-8 gap-3 border-b">
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-2">
              <img src={avatar_src(@current_user.display_name)} class="rounded-full h-10 w-10" />
              <span class="font-medium text-slate-600"><%= @current_user.display_name %></span>
            </div>

            <ContextMenu.menu>
              <button class="flex items-center justify-center hover:bg-slate-200 aspect-square w-10 h-10 rounded-full">
                <Svg.dots_vertical />
              </button>
              <:item title="New Group" type="button" click="sidebar_menu:new_group">
                <Svg.people_fill class="w-5 h-5" />
              </:item>
              <:item title="Message requests" type="button" click="sidebar_menu:invitations">
                <Svg.chat_dots class="w-5 h-5" />
              </:item>
              <:item title="Profile" type="button" click="sidebar_menu:profile">
                <Svg.person_circle class="w-5 h-5" />
              </:item>
              <:item border={true} />
              <:item title="Logout" type="link" href={~p"/users/log_out"} method="delete">
                <Svg.box_arrow_right class="w-5 h-5" />
              </:item>
            </ContextMenu.menu>
          </div>

          <form
            class="relative"
            phx-change="find_people:change"
            onkeydown="return event.key != 'Enter';"
          >
            <Svg.search class="absolute left-5 top-[13px] text-slate-500 h-4 w-4" />
            <input
              id="search_input"
              type="text"
              name="search_text"
              value={@find_people.search_input}
              placeholder="Find people"
              phx-debounce="100"
              autocomplete="off"
              class="w-full rounded-3xl pl-12 pr-4 py-2 border-slate-300 border focus:border-indigo-400"
            />
            <button
              :if={String.length(@find_people.search_input) > 0}
              class="absolute right-2 top-2"
              phx-click="find_people:clean_search"
              type="button"
            >
              <Svg.close class="text-slate-700 cursor-pointer font-extrabold rounded-full h-7 w-7 p-2 hover:bg-slate-200 active:bg-slate-300" />
            </button>
          </form>
        </div>
        <ul class="overflow-y-auto flex-grow">
          <%= if length(@find_people.found_users) > 0 or length(@find_people.found_rooms) > 0 do %>
            <%!-- Found rooms from Search bar --%>
            <li
              :for={room <- @find_people.found_rooms}
              key={"found-room-#{room.id}"}
              class="flex items-center gap-4 py-3 px-8 border-b hover:bg-blue-50 cursor-pointer"
              phx-click="select_room"
              phx-value-room_id={room.id}
            >
              <img
                src={avatar_src(get_room_name(room, @current_user))}
                class="rounded-full h-10 w-10"
              />
              <span class="font-medium text-slate-600">
                <%= get_room_name(room, @current_user) %>
              </span>
            </li>
            <%!-- Found users from Search bar --%>
            <span
              :if={length(@find_people.found_users) > 0}
              class="py-1 px-8 block text-slate-700 font-bold bg-slate-300"
            >
              More People
            </span>
            <li
              :for={user <- @find_people.found_users}
              key={"found-user-#{user.id}"}
              class="flex items-center gap-4 py-3 px-8 border-b hover:bg-blue-50 cursor-pointer"
              phx-click="select_found_user"
              phx-value-user_id={user.id}
            >
              <img src={avatar_src(user.display_name)} class="rounded-full h-10 w-10" />
              <span class="font-medium text-slate-600">
                <%= user.display_name %>
              </span>
            </li>
          <% else %>
            <%= if String.length(@find_people.search_input) >= 2 do %>
              <h2 class="flex w-full h-full justify-center items-center text-slate-700">
                Can't find any users
              </h2>
            <% else %>
              <%!-- Current User rooms --%>
              <li
                :for={room <- @rooms}
                key={"room-#{room.id}"}
                class={[
                  "flex justify-between items-center gap-4 py-4 px-8 border-b hover:bg-blue-50 cursor-pointer",
                  if(@current_room.id == room.id, do: "bg-blue-50", else: "")
                ]}
                phx-click="select_room"
                phx-value-room_id={room.id}
              >
                <div class="relative">
                  <img
                    src={avatar_src(get_room_name(room, @current_user))}
                    class="rounded-full h-10 w-10"
                  />
                  <%!-- @TODO: Add condition to show the dot --%>
                  <span class="absolute bg-indigo-600 rounded-full h-3 w-3 border-[3px] border-white right-0 bottom-[-2px]" />
                </div>
                <div class="flex flex-col w-36 grow">
                  <span class="font-medium text-slate-600">
                    <%= get_room_name(room, @current_user) %>
                  </span>
                  <span class="truncate">
                    <%= get_last_message(room.messages, @current_user.id) %>
                  </span>
                </div>
                <div class="text-xs">
                  <%= get_last_message_date(room.messages) %>
                </div>
              </li>
            <% end %>
          <% end %>
        </ul>
      </div>
      <!-- Chat Area -->
      <div
        :if={@current_room || @find_people.selected_user || @selected_invitation}
        class="flex flex-col grow"
      >
        <%!-- Chat header --%>
        <div class="flex justify-between items-center bg-gray-50 py-4 px-6 gap-3">
          <div class="flex items-center gap-2">
            <img
              src={
                avatar_src(
                  (@selected_invitation && get_room_name(@selected_invitation.room, @current_user)) ||
                    (@find_people.selected_user && @find_people.selected_user.display_name) ||
                    get_room_name(@current_room, @current_user)
                )
              }
              class="rounded-full h-10 w-10"
            />
            <span class="font-medium text-slate-600">
              <%= (@selected_invitation && get_room_name(@selected_invitation.room, @current_user)) ||
                (@find_people.selected_user && @find_people.selected_user.display_name) ||
                get_room_name(@current_room, @current_user) %>
            </span>
          </div>
          <button class="flex items-center justify-center hover:bg-slate-200 aspect-square w-10 h-10 rounded-full">
            <Svg.dots_vertical />
          </button>
        </div>
        <div
          :if={
            not friend?(@current_room, @current_user) and is_nil(@find_people.selected_user) and
              is_nil(@selected_invitation)
          }
          class="bg-gray-500 text-white text-center text-sm"
        >
          Friend request is pending..
        </div>
        <div
          :if={@selected_invitation}
          class="bg-indigo-500 text-white font-semibold text-center py-1 text-sm"
        >
          Message request
        </div>

        <%!-- Chat Messages --%>
        <div
          id="chat-place"
          class="overflow-y-auto flex-grow px-4 pt-2 border-t"
          phx-hook="ScrollBack"
        >
          <%!-- Discover person screen --%>
          <div
            :if={@find_people.selected_user}
            class="flex flex-col h-full items-center justify-between"
          >
            <div class="flex flex-col items-center gap-2">
              <img
                src={avatar_src(@find_people.selected_user.display_name)}
                class="rounded-full h-16 w-16"
              />
              <span class="font-medium text-lg text-slate-600">
                <%= @find_people.selected_user.display_name %>
              </span>
              <span class="text-sm text-slate-500">
                Send a message to introduce yourself. Remember to be kind and respectful.
              </span>
            </div>
            <div class="flex flex-col items-center">
              <button
                type="button"
                phx-click="send_friend_request"
                phx-value-user_id={@find_people.selected_user.id}
                class="block rounded-full text-sm px-4 py-2 mb-4 bg-indigo-600 text-white drop-shadow-lg hover:bg-indigo-500 active:bg-indigo-700"
              >
                Send request without a message
              </button>
              <span class="text-sm text-slate-500">
                After sending a friend request you can't send another message until your friend request is accepted!
              </span>
            </div>
          </div>

          <%!-- Chat area --%>
          <div
            :for={message <- Enum.reverse(@chat_history)}
            :if={is_nil(@find_people.selected_user) && is_nil(@selected_invitation)}
            class={[
              "flex mb-3",
              if(message.sender_id == @current_user.id, do: "justify-end", else: "justify-start")
            ]}
          >
            <div key={"message-#{message.id}"} class="flex flex-col gap-1">
              <span
                :if={@current_room.type == RoomType.group() and message.sender.id != @current_user.id}
                class="text-xs pl-1"
              >
                <%= message.sender.display_name %>
              </span>
              <div class={"rounded-xl relative px-3 py-2 text-gray-50 " <> if message.sender_id == @current_user.id, do: "bg-blue-500", else: "bg-gray-500"}>
                <p class="max-w-prose break-words"><%= message.content %></p>
                <div class={"absolute bottom-0 w-3 " <> if message.sender_id == @current_user.id, do: "-right-1 text-blue-500", else: "-left-1 text-gray-500 -scale-x-100"}>
                  <Svg.bubble_tail />
                </div>
              </div>

              <div class={"text-xs text-slate-500 font-semibold " <> if message.sender_id == @current_user.id, do: "text-right mr-2", else: "ml-2"}>
                <%= extract_time(message.sent_at) %>
              </div>
            </div>
          </div>

          <%!-- Invitation messages area --%>
          <div :if={@selected_invitation}>
            <div
              :for={message <- Enum.reverse(@selected_invitation_messages)}
              class={[
                "flex mb-3",
                if(message.sender_id == @current_user.id, do: "justify-end", else: "justify-start")
              ]}
            >
              <div key={"message-#{message.id}"} class="flex flex-col gap-1">
                <span
                  :if={
                    @current_room.type == RoomType.group() and message.sender.id != @current_user.id
                  }
                  class="text-xs pl-1"
                >
                  <%= message.sender.display_name %>
                </span>
                <div class={"rounded-xl relative px-3 py-2 text-gray-50 " <> if message.sender_id == @current_user.id, do: "bg-blue-500", else: "bg-gray-500"}>
                  <p class="max-w-prose break-words"><%= message.content %></p>
                  <div class={"absolute bottom-0 w-3 " <> if message.sender_id == @current_user.id, do: "-right-1 text-blue-500", else: "-left-1 text-gray-500 -scale-x-100"}>
                    <Svg.bubble_tail />
                  </div>
                </div>

                <div class={"text-xs text-slate-500 font-semibold " <> if message.sender_id == @current_user.id, do: "text-right mr-2", else: "ml-2"}>
                  <%= extract_time(message.sent_at) %>
                </div>
              </div>
            </div>
            <p class="text-center py-2">
              Do you wish to accept this message request and become friends with <%= get_room_name(
                @selected_invitation.room,
                @current_user
              ) %>?
            </p>
            <div class="flex items-center gap-4 w-full justify-center">
              <button
                type="button"
                phx-click="invitation_answer"
                phx-value-accept_invitation="false"
                phx-value-invitation_id={@selected_invitation.id}
                class="px-12 py-2 rounded-full text-white bg-red-500 hover:bg-red-600 active:bg-red-700"
              >
                No
              </button>
              <button
                type="button"
                phx-click="invitation_answer"
                phx-value-accept_invitation="true"
                phx-value-invitation_id={@selected_invitation.id}
                class="px-16 py-2 rounded-full text-white bg-indigo-500 hover:bg-indigo-600 active:bg-indigo-700"
              >
                Yes
              </button>
            </div>
          </div>
        </div>

        <%!-- Text input --%>
        <div :if={is_nil(@selected_invitation)} class="p-4">
          <form
            class="flex justify-between gap-4"
            phx-submit="message_box:send"
            phx-change="message_box:change"
          >
            <input
              id="message_box"
              type="text"
              name="content"
              class="w-full rounded-3xl border-slate-300 border px-5 focus:border-indigo-700"
              placeholder="Type your message..."
              phx-debounce="100"
              autocomplete="off"
              value={Map.get(@message_box, @current_room && @current_room.id, "")}
            />
            <button class="flex items-center hover:bg-slate-200 focus:bg-slate-300 rounded-full w-11 h-10">
              <Svg.send class="text-indigo-600 rotate-45 w-5 h-5 ml-2" />
            </button>
          </form>
        </div>
      </div>
    </div>
    """
  end

  @impl true
  def mount(
        _params,
        _session,
        %{assigns: %{current_user: %User{id: user_id}}} = socket
      ) do
    rooms = Account.get_user_chat_rooms(user_id)

    {chat_history, current_room} =
      case List.first(rooms) do
        %Room{id: room_id} = room ->
          chat_history = Message.paginate(%Message.Paginate{room_id: room_id})
          {chat_history, room}

        _ ->
          {[], nil}
      end

    new_socket =
      assign(socket,
        rooms: rooms,
        found_users: [],
        invitations: [],
        selected_invitation: nil,
        selected_invitation_messages: [],
        chat_history: chat_history,
        current_room: current_room,
        message_box: %{},
        sidebar_menu: nil,
        sidebar_menu_open: false,
        find_people: empty_find_people()
      )

    {:ok, new_socket}
  end

  @impl true
  def handle_params(
        %{"room" => id} = _params,
        _session,
        %{assigns: %{current_user: %User{id: user_id}}} = socket
      ) do
    room_id = String.to_integer(id)

    new_socket =
      if Account.valid_room_id?(room_id, user_id) do
        Account.mark_room_messages_as_read(user_id, room_id)
        chat_history = Message.paginate(%Message.Paginate{room_id: room_id})
        rooms = Account.get_user_chat_rooms(user_id)

        socket
        |> assign(
          current_room: Enum.find(rooms, fn %Room{id: id} -> id == room_id end),
          chat_history: chat_history,
          rooms: rooms
        )
        |> push_event("focus_element", %{id: "message_box"})
      else
        socket
      end
      |> assign(sidebar_menu_open: false)

    {:noreply, new_socket}
  end

  @impl true
  def handle_params(_params, _session, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_room", %{"room_id" => id}, socket) do
    new_socket =
      socket
      |> assign(find_people: empty_find_people())
      |> push_patch(to: ~p"/?#{%{room: id}}")

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "message_box:send",
        _,
        %{
          assigns: %{
            current_user: %User{id: sender_id},
            find_people: %{
              friend_request_message: message,
              selected_user: %User{id: receiver_id}
            }
          }
        } = socket
      ) do
    {:ok, %Room{id: room_id}} =
      Account.send_friend_request(%Request.SendFriendRequest{
        invitation_message: message,
        receiver_id: receiver_id,
        sender_id: sender_id
      })

    new_socket =
      socket
      |> assign(find_people: empty_find_people())
      |> push_navigate(to: ~p"/?#{%{room: room_id}}")

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("select_invitation", %{"invitation_id" => id}, socket) do
    %Invitation{room_id: room_id} = invitation = Invitation.get!(id)

    new_socket =
      assign(socket,
        selected_invitation: invitation,
        selected_invitation_messages: Message.all_by(filter: [room_id: room_id])
      )

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "invitation_answer",
        %{"accept_invitation" => answer, "invitation_id" => id},
        %{assigns: %{current_user: %User{id: user_id}}} = socket
      ) do
    accepted? = String.to_atom(answer)

    {:ok, %Invitation{room_id: room_id}} =
      Account.answer_invitation(String.to_integer(id), accepted?)

    new_socket =
      if accepted? do
        socket
        |> assign(selected_invitation: nil, selected_invitation_messages: [])
        |> push_navigate(to: ~p"/?#{%{room: room_id}}")
      else
        [%Invitation{room_id: room_id} = invitation | _] =
          invitations = Account.get_user_invitations(user_id)

        socket
        |> assign(
          selected_invitation: invitation,
          selected_invitation_messages: Message.all_by(filter: [room_id: room_id]),
          invitations: invitations
        )
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "message_box:send",
        _,
        %{
          assigns: %{
            current_user: %User{id: user_id},
            current_room: %Room{id: room_id},
            message_box: message_box
          }
        } = socket
      ) do
    {:ok, %Message{}} =
      Account.send_message(%Request.SendMessage{
        content: Map.get(message_box, room_id),
        sender_id: user_id,
        room_id: room_id,
        sent_at: DateTime.utc_now()
      })

    new_socket = assign(socket, message_box: Map.put(message_box, room_id, ""))
    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "message_box:change",
        %{"content" => content},
        %{assigns: %{find_people: %{selected_user: %User{}} = find_people}} = socket
      ) do
    trimmed_content = String.trim(content)

    new_socket =
      if byte_size(trimmed_content) > 0 do
        assign(socket, find_people: %{find_people | friend_request_message: trimmed_content})
      else
        socket
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "message_box:change",
        %{"content" => content},
        %{assigns: %{current_room: %Room{id: room_id}, message_box: message_box}} = socket
      ) do
    trimmed_content = String.trim(content)

    new_socket =
      if byte_size(trimmed_content) > 0 do
        assign(socket, message_box: Map.put(message_box, room_id, trimmed_content))
      else
        socket
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "find_people:change",
        %{"search_text" => input},
        %{assigns: %{find_people: find_people, current_user: %User{id: user_id}}} = socket
      ) do
    trim_input = String.trim(input)

    new_socket =
      if byte_size(trim_input) >= 2 do
        assign(socket,
          find_people: %{
            find_people
            | search_input: trim_input,
              found_users: Account.find_unknown_users_by_name(input, user_id),
              found_rooms: Account.find_rooms_by_name(input, user_id)
          }
        )
      else
        assign(socket,
          find_people: %{find_people | search_input: trim_input, found_users: [], found_rooms: []}
        )
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "find_people:clean_search",
        _,
        %{assigns: %{find_people: find_people}} = socket
      ) do
    new_socket =
      assign(socket,
        find_people: %{find_people | search_input: "", found_users: [], found_rooms: []}
      )

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "select_found_user",
        %{"user_id" => user_id},
        %{assigns: %{find_people: find_people}} = socket
      ) do
    new_socket =
      assign(socket,
        find_people: %{
          find_people
          | selected_user: User.get!(String.to_integer(user_id))
        }
      )

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "send_friend_request",
        %{"user_id" => receiver_id},
        %{assigns: %{current_user: %User{id: sender_id}}} = socket
      ) do
    {:ok, %Room{id: room_id}} =
      Account.send_friend_request(%Request.SendFriendRequest{
        receiver_id: String.to_integer(receiver_id),
        sender_id: sender_id
      })

    new_socket =
      socket
      |> assign(find_people: empty_find_people())
      |> push_navigate(to: ~p"/?#{%{room: room_id}}")

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("sidebar_menu:close", _, socket) do
    new_socket = assign(socket, sidebar_menu_open: false, selected_invitation: nil)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("sidebar_menu:profile", %{"value" => context_menu_id}, socket) do
    new_socket =
      socket
      |> assign(sidebar_menu_open: true, sidebar_menu: "profile")
      |> push_event("hide_element", %{id: context_menu_id})

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("sidebar_menu:new_group", %{"value" => context_menu_id}, socket) do
    new_socket =
      socket
      |> assign(sidebar_menu_open: true, sidebar_menu: "new_group")
      |> push_event("hide_element", %{id: context_menu_id})

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "sidebar_menu:invitations",
        %{"value" => context_menu_id},
        %{assigns: %{current_user: %User{id: user_id}}} = socket
      ) do
    new_socket =
      socket
      |> assign(
        sidebar_menu_open: true,
        sidebar_menu: "invitations",
        invitations: Account.get_user_invitations(user_id)
      )
      |> push_event("hide_element", %{id: context_menu_id})

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(
        {Bus, %Message{id: message_id, room_id: room_id, sender_id: sender_id} = message},
        %{
          assigns: %{
            rooms: rooms,
            chat_history: chat_history,
            current_room: %Room{id: room_id},
            current_user: %User{id: current_user_id}
          }
        } = socket
      ) do
    if sender_id != current_user_id do
      :ok =
        Account.read_message(%Request.ReadMessage{
          message_id: message_id,
          reader_id: current_user_id
        })
    end

    seen_message = %Message{message | seen: true}
    room = Enum.find(rooms, fn %Room{id: id} -> id == room_id end)
    room_index = Enum.find_index(rooms, fn %Room{id: id} -> id == room_id end)
    new_rooms = List.replace_at(rooms, room_index, %Room{room | messages: [seen_message]})

    new_chat_history =
      with %Scrivener.Page{entries: entries} <- chat_history do
        %Scrivener.Page{chat_history | entries: [seen_message | entries]}
      end

    new_socket =
      socket
      |> assign(rooms: new_rooms, chat_history: new_chat_history)
      |> push_event("message:new", %{is_sender: sender_id == current_user_id})

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(
        {Bus, %Message{room_id: room_id} = message},
        %{assigns: %{rooms: rooms}} = socket
      ) do
    new_rooms = %{
      rooms
      | room_id => %Room{rooms[room_id] | messages: [message]}
    }

    new_socket = assign(socket, rooms: new_rooms)

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(
        {Bus, %Bus.Event.FriendInvitationRequest{}},
        %{assigns: %{current_user: %User{id: user_id}}} = socket
      ) do
    new_socket = assign(socket, invitations: Account.get_user_invitations(user_id))

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({Bus, %Bus.Event.FriendInvitationResponse{invitation_id: id}}, socket) do
    %Invitation{room_id: room_id} = Invitation.get!(id)
    new_socket = push_patch(socket, to: ~p"/?#{%{room: room_id}}")

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({Bus, _unhandled_message}, socket) do
    {:noreply, socket}
  end

  @spec get_last_message([Message.t()], pos_integer()) :: String.t()
  defp get_last_message(messages, current_user_id)

  defp get_last_message([], _), do: ""

  defp get_last_message(
         [%Message{content: content, sender_id: current_user_id}],
         current_user_id
       ) do
    "You: " <> content
  end

  defp get_last_message([%Message{content: content}], _) do
    content
  end

  defp get_last_message_date([]), do: ""

  defp get_last_message_date([%Message{sent_at: sent_at}]) do
    Calendar.strftime(sent_at, "%Y-%m-%d")
  end

  defp seen?([], _), do: true
  defp seen?([%Message{sender_id: current_user_id}], current_user_id), do: true
  defp seen?([%Message{seen: seen}], _), do: seen

  defp extract_time(%{hour: hour, minute: minute}) do
    "#{hour}:#{minute |> to_string() |> String.pad_leading(2, "0")}"
  end

  defp get_room_name(%Room{type: RoomType.group(), name: name}, _) do
    name
  end

  defp get_room_name(
         %Room{
           type: RoomType.dm(),
           invitations: [
             %Invitation{
               receiver: %User{display_name: sender_name},
               sender: %User{display_name: receiver_name}
             }
             | _
           ]
         },
         %User{display_name: current_user_name}
       ) do
    if current_user_name == sender_name do
      receiver_name
    else
      sender_name
    end
  end

  defp friend?(%Room{type: RoomType.dm(), invitations: [%Invitation{status: status}]}, %User{}) do
    case status do
      InvitationStatus.accepted() -> true
      _ -> false
    end
  end

  defp friend?(_, _), do: true

  defp avatar_src(name) do
    attrs =
      %{
        name: name |> String.split(" ") |> Enum.join("+"),
        background: "0D8ABC",
        color: "FFFFFF",
        "font-size": 0.35,
        bold: true
      }
      |> Enum.map(fn {k, v} -> to_string(k) <> "=" <> to_string(v) end)
      |> Enum.join("&")

    "https://ui-avatars.com/api/?#{attrs}"
  end

  defp empty_find_people do
    %{
      found_users: [],
      found_rooms: [],
      selected_user: nil,
      friend_request_message: "",
      search_input: ""
    }
  end
end
