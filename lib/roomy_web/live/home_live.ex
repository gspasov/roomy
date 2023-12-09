defmodule RoomyWeb.HomeLive do
  use RoomyWeb, :live_view

  alias Roomy.Bus
  alias Roomy.Account
  alias Roomy.Request
  alias Roomy.Constants.RoomType
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.Message
  alias RoomyWeb.Components.Svg
  alias RoomyWeb.Components.ContextMenu
  alias WarmFuzzyThing.Maybe

  require Bus.Topic
  require RoomType

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex max-h-full">
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
              <:item title="New Group" href={~p"/"}>
                <Svg.people_fill class="w-5 h-5" />
              </:item>
              <:item title="Friends" href={~p"/users/friends"}>
                <Svg.search class="w-5 h-5" />
              </:item>
              <:item title="Profile" href={~p"/users/settings"}>
                <Svg.person_circle class="w-5 h-5" />
              </:item>
              <:item border={true} />
              <:item title="Logout" href={~p"/users/log_out"} method="delete">
                <Svg.box_arrow_right class="w-5 h-5" />
              </:item>
            </ContextMenu.menu>
          </div>

          <form class="relative">
            <Svg.search class="absolute left-5 top-1/3 text-slate-500" />
            <input
              id="search_input"
              type="text"
              name="search"
              value=""
              placeholder="Search or start new chat"
              phx-debounce="100"
              class="w-full rounded-3xl pl-12 pr-4 py-2 border-slate-300 border focus:border-indigo-400"
            />
          </form>
        </div>
        <ul class="overflow-y-auto">
          <li
            :for={{id, room} <- @rooms}
            key={id}
            class="flex justify-between items-center gap-4 py-5 px-8 border-b hover:bg-blue-50 h-20 cursor-pointer"
            phx-click="select_room"
            phx-value-room_id={id}
          >
            <div class="relative">
              <img
                src={avatar_src(get_room_name(room, @current_user.id))}
                class="rounded-full h-10 w-10"
              />
              <%!-- @TODO: Add condition to show the dot --%>
              <span class="absolute bg-indigo-600 rounded-full h-3 w-3 border-[3px] border-white right-0 bottom-[-2px]" />
            </div>
            <div class="flex flex-col w-36 grow">
              <span class="font-medium text-slate-600">
                <%= get_room_name(room, @current_user.id) %>
              </span>
              <span class="truncate">
                <%= get_last_message(
                  room.messages,
                  @current_user.id
                ) %>
              </span>
            </div>
            <div class="flex flex-col text-xs justify-between h-full">
              <span>26/04/2021</span>
              <span></span>
            </div>
          </li>
        </ul>
      </div>
      <!-- Chat Area -->
      <div class="flex flex-col grow">
        <%!-- Chat header --%>
        <div class="flex justify-between items-center bg-gray-50 py-4 px-6 gap-3">
          <div class="flex items-center gap-2">
            <img src={avatar_src(@current_user.display_name)} class="rounded-full h-10 w-10" />
            <span class="font-medium text-slate-600"><%= @current_user.display_name %></span>
          </div>
          <button class="flex items-center justify-center hover:bg-slate-200 aspect-square w-10 h-10 rounded-full">
            <Svg.dots_vertical />
          </button>
        </div>

        <%!-- Chat --%>
        <div
          id={"room-#{@current_room.id}"}
          class="overflow-y-scroll flex-grow px-6 pt-2 border-y"
          phx-hook="ScrollBack"
          phx-click={JS.dispatch("phx:focus_element", to: "#message_box")}
        >
          <div
            :for={message <- Enum.reverse(@chat_history || [])}
            class={"flex mb-3 " <> if(message.sender_id == @current_user.id, do: "justify-end", else: "justify-start")}
          >
            <div class="flex flex-col gap-1">
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

              <div class={"text-xs text-slate-400 font-semibold " <> if message.sender_id == @current_user.id, do: "text-right mr-2", else: "ml-2"}>
                <%= extract_time(message.sent_at) %>
              </div>
            </div>
          </div>
        </div>

        <%!-- Text input --%>
        <div class="p-4">
          <form
            class="flex justify-between gap-4"
            phx-submit="message_box:send"
            phx-change="message_box:change"
          >
            <input
              id="message_box"
              type="text"
              name="content"
              class="w-full rounded-3xl border-slate-300 border-2 focus:border-indigo-400"
              placeholder="Type your message..."
              phx-debounce="100"
              value={Map.get(@message_box, @current_room.id, "")}
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
      rooms
      |> Enum.into([])
      |> List.first()
      |> case do
        {room_id, %Room{} = room} ->
          chat_history = Message.paginate(%Message.Paginate{room_id: room_id})
          {chat_history, room}

        _ ->
          {nil, nil}
      end

    new_socket =
      assign(socket,
        rooms: rooms,
        chat_history: chat_history,
        current_room: current_room,
        message_box: %{}
      )

    {:ok, new_socket}
  end

  @impl true
  def handle_params(
        %{"room" => id} = _params,
        _session,
        %{assigns: %{rooms: rooms, current_user: %User{id: user_id}}} = socket
      ) do
    available_room_ids = Enum.map(rooms, &elem(&1, 0))
    {room_id, ""} = Integer.parse(id)

    new_socket =
      if room_id in available_room_ids do
        Account.mark_room_messages_as_read(user_id, room_id)
        chat_history = Message.paginate(%Message.Paginate{room_id: room_id})
        rooms = Account.get_user_chat_rooms(user_id)

        socket
        |> assign(
          current_room: Map.get(rooms, room_id),
          chat_history: chat_history,
          rooms: rooms
        )
        |> push_event("focus_element", %{id: "message_box"})
      else
        socket
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_params(_params, _session, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("select_room", %{"room_id" => id}, socket) do
    {:noreply, push_patch(socket, to: ~p"/?#{%{room: id}}")}
  end

  @impl true
  def handle_event(
        "message_box:send",
        %{"content" => content},
        %{
          assigns: %{
            current_user: %User{id: user_id},
            current_room: %Room{id: room_id},
            message_box: message_box
          }
        } = socket
      ) do
    trimmed_content = String.trim(content)

    new_socket =
      if byte_size(trimmed_content) > 0 do
        {:ok, %Message{}} =
          Account.send_message(%Request.SendMessage{
            content: trimmed_content,
            sender_id: user_id,
            room_id: room_id,
            sent_at: DateTime.utc_now()
          })

        assign(socket, message_box: Map.put(message_box, room_id, ""))
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
    new_socket = assign(socket, message_box: Map.put(message_box, room_id, content))
    {:noreply, new_socket}
  end

  @impl true
  def handle_info(
        {Roomy.Bus, %Message{id: message_id, room_id: room_id, sender_id: sender_id} = message},
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

    new_rooms = %{
      rooms
      | room_id => %Room{rooms[room_id] | messages: [seen_message]}
    }

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
        {Roomy.Bus, %Message{room_id: room_id} = message},
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
        {Roomy.Bus, %Bus.Event.FriendInvitationResponse{}},
        %{assigns: %{current_user: %User{id: user_id}}} = socket
      ) do
    new_socket = assign(socket, rooms: Account.get_user_chat_rooms(user_id))

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({Roomy.Bus, _unhandled_message}, socket) do
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

  defp seen?([], _), do: true
  defp seen?([%Message{sender_id: current_user_id}], current_user_id), do: true
  defp seen?([%Message{seen: seen}], _), do: seen

  defp extract_time(%{hour: hour, minute: minute}) do
    "#{hour}:#{minute |> to_string() |> String.pad_leading(2, "0")}"
  end

  defp get_room_name(%Room{type: RoomType.group(), name: name}, _) do
    name
  end

  defp get_room_name(%Room{type: RoomType.dm(), users: users}, current_user_id) do
    users
    |> Enum.find(fn %User{id: user_id} -> user_id != current_user_id end)
    |> Maybe.pure()
    |> Maybe.fold("error :(", fn %User{display_name: name} -> name end)
  end

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
end
