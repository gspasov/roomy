defmodule RoomyWeb.HomeLive do
  use RoomyWeb, :live_view

  alias Roomy.Bus
  alias Roomy.Account
  alias Roomy.Request
  alias Roomy.Constants.RoomType
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.Message
  alias WarmFuzzyThing.Maybe

  require Bus.Topic
  require RoomType

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex h-full gap-2 px-2 pb-2">
      <!-- Sidebar -->
      <fieldset class="border border-gray-200 w-[25%]">
        <legend class="px-2 text-sm text-center text-nav_text_light font-bold">Rooms</legend>
        <ul class="px-2">
          <p :if={map_size(@rooms) === 0} class="text-highlight">You have no chats :(</p>
          <li
            :for={{id, room} <- @rooms}
            key={id}
            class="cursor-pointer mb-1"
            phx-click="select_room"
            phx-value-room_id={id}
          >
            <div class={"flex flex-col border-2 border-default_background rounded p-2 items-start text-nav_text_light " <> if @current_room && @current_room.id == id, do: "!border-navigation bg-navigation", else: "hover:border-dotted hover:border-navigation"}>
              <span class={"font-bold " <> if @current_room && @current_room.id == id, do: "text-highlight", else: ""}>
                <%= get_room_name(room, @current_user.id) %>
              </span>
              <div class={"text-sm max-w-full font-normal truncate w-64 " <> unless seen?(room.messages, @current_user.id), do: "font-medium text-highlight", else: ""}>
                <%= get_last_message(room.messages, @current_user.id) %>
              </div>
            </div>
          </li>
        </ul>
      </fieldset>
      <!-- Chat Area -->
      <fieldset class="flex flex-col w-full border border-gray-200 w-[75%]">
        <%= if @current_room == nil do %>
          <div class="flex items-center justify-center h-full">
            <div class="text-highlight text-center">
              <h2 class="text-2xl font-bold mb-4">
                No Conversation selected
              </h2>
              <p class="text-lg">
                Click on a name to start a conversation with your friend!
              </p>
            </div>
          </div>
        <% else %>
          <legend class="px-2 text-sm text-center text-nav_text_light font-bold">
            <%= get_room_name(@current_room, @current_user.id) %>
          </legend>
          <div
            id={"room-#{@current_room.id}"}
            class="overflow-y-scroll flex-grow px-2 pt-2"
            phx-hook="ScrollBack"
            phx-click={JS.dispatch("phx:focus_element", to: "#message_box")}
          >
            <div
              :for={message <- Enum.reverse(@chat_history || [])}
              class={[
                "flex mb-3",
                if(message.sender_id == @current_user.id, do: "justify-end", else: "justify-start")
              ]}
            >
              <div class="flex flex-col gap-1">
                <span
                  :if={
                    @current_room.type == RoomType.group() and message.sender.id != @current_user.id
                  }
                  class="text-xs pl-1 text-white"
                >
                  <%= message.sender.display_name %>
                </span>
                <div class={"rounded-md px-2 py-1 " <> if message.sender_id == @current_user.id, do: "bg-bubble_me text-white", else: "bg-bubble_you text-nav_text_dark"}>
                  <p class="max-w-prose break-words"><%= message.content %></p>
                  <div class={"text-xs " <> if message.sender_id == @current_user.id, do: "text-right text-gray-300", else: "text-gray-600"}>
                    <%= extract_time(message.sent_at) %>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <fieldset class="m-2 mt-2 p-1 border border-gray-200">
            <legend class="px-2 text-sm text-center text-nav_text_light font-bold">Prompt</legend>
            <form
              class="focus:outline-none focus:ring focus:border-blue-300"
              phx-submit="message_box:send"
              phx-change="message_box:change"
            >
              <input
                id="message_box"
                type="text"
                name="content"
                class="w-full pt-0 bg-neutral-50 border-none text-white bg-default_background placeholder:text-slate-300 focus:outline-none focus:ring-0"
                placeholder="Type your message..."
                phx-debounce="100"
                value={Map.get(@message_box, @current_room.id, "")}
                autofocus
              />
            </form>
          </fieldset>
        <% end %>
      </fieldset>
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
end
