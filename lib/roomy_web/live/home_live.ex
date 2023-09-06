defmodule RoomyWeb.HomeLive do
  use RoomyWeb, :live_view

  alias Roomy.Bus
  alias Roomy.Account
  alias Roomy.Request
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.Message

  require Bus.Topic

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        shadow:
          "shadow-[rgba(50,_50,_105,_0.15)_0px_2px_5px_0px,_rgba(0,_0,_0,_0.05)_0px_1px_1px_0px]"
      )

    ~H"""
    <div class="flex h-full gap-2 p-2 bg-neutral-50">
      <!-- Sidebar -->
      <div class={"min-w-18 border rounded-xl border-gray-200 " <> @shadow}>
        <h1 class="p-4 text-2xl font-bold border-b border-gray-400">roomy.fun</h1>

        <div class="flex flex-col gap-2 p-2">
          <form class="flex p-1 mt-2 border border-gray-400 rounded-md focus:outline-none focus:ring focus:border-blue-300">
            <input
              type="text"
              class="h-8 w-full bg-neutral-50 border-none focus:outline-none focus:ring-0"
              placeholder="Find friend..."
            />
          </form>
          <ul>
            <p :if={map_size(@rooms) === 0}>You have no chats :(</p>
            <li
              :for={{id, room} <- @rooms}
              key={id}
              class="cursor-pointer rounded-md mb-1"
              phx-click="select_room"
              phx-value-room_id={id}
            >
              <div class={"flex py-2 px-2 gap-2 items-center rounded-md hover:bg-gray-200 " <> if @selected_room && @selected_room.id == id, do: "bg-gray-200", else: ""}>
                <div class="flex items-end">
                  <div class="w-10 h-10 rounded-full bg-gray-500" />
                  <%!-- <div :if={user.is_online} class="w-2.5 h-2.5 rounded-full bg-green-700" /> --%>
                  <%!-- <div :if={not user.is_online} class="w-2.5 h-2.5 rounded-full bg-red-700" /> --%>
                </div>
                <div>
                  <span><%= room.name %></span>
                  <div class={"text-sm font-normal truncate " <> unless seen?(room.messages, @current_user.id), do: "font-medium", else: ""}>
                    <%= get_last_message(room.messages, @current_user.id) %>
                  </div>
                </div>
              </div>
            </li>
          </ul>
        </div>
      </div>
      <!-- Chat Area -->
      <div class={"flex flex-col w-full border rounded-xl border-gray-200 " <> @shadow}>
        <%= if @selected_room == nil do %>
          <div class="flex items-center justify-center">
            <div class="text-gray-600 text-center">
              <h2 class="text-2xl font-bold mb-4">
                No Conversation selected
              </h2>
              <p class="text-lg">
                Click on a name to start a conversation with your friend!
              </p>
            </div>
          </div>
        <% else %>
          <h1 class="text-2xl p-4 font-bold border-b border-gray-400">
            <%= @selected_room.name %>
          </h1>
          <div
            id={"room-#{@selected_room.id}"}
            class="overflow-y-scroll flex-grow px-4 pt-2"
            phx-hook="ScrollBack"
            phx-click={JS.dispatch("phx:focus_element", to: "#message_box")}
          >
            <div
              :for={message <- Enum.reverse(@chat_history || [])}
              class={"flex mb-2 " <> if message.sender_id == @current_user.id, do: "justify-end", else: "justify-start"}
            >
              <div class={"rounded-xl px-4 py-2 max-w-prose " <>
                    if message.sender_id == @current_user.id, do: "bg-blue-500 text-white", else: "bg-gray-300"
                  }>
                <p><%= message.content %></p>
                <div class={"text-xs " <>
                  if message.sender_id == @current_user.id, do: "text-right text-gray-300", else: "text-gray-600"
                }>
                  <%= extract_time(message.sent_at) %>
                </div>
              </div>
            </div>
          </div>
          <form
            class="flex m-4 mt-2 p-1 gap-2 border border-gray-400 rounded-lg focus:outline-none focus:ring focus:border-blue-300"
            phx-submit="message_box:send"
            phx-change="message_box:change"
          >
            <input
              id="message_box"
              type="text"
              name="content"
              class="w-full bg-neutral-50 border-none focus:outline-none focus:ring-0"
              placeholder="Type your message..."
              phx-debounce="100"
              value={@message_box_content}
              autofocus
            />
            <button
              type="submit"
              class="px-7 text-white font-bold text-sm rounded-lg bg-blue-500 hover:bg-blue-600 focus:outline-none focus:ring focus:border-blue-300"
            >
              Send
            </button>
          </form>
        <% end %>
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

    {chat_history, selected_room} =
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

    Enum.each(rooms, fn {room_id, _} ->
      room_id
      |> Bus.Topic.room()
      |> Bus.subscribe()
    end)

    new_socket =
      assign(socket,
        rooms: rooms,
        chat_history: chat_history,
        selected_room: selected_room,
        message_box_content: ""
      )

    {:ok, new_socket}
  end

  @impl true
  def handle_event(
        "select_room",
        %{"room_id" => id},
        %{assigns: %{rooms: rooms, current_user: %User{id: user_id}}} = socket
      ) do
    {room_id, ""} = Integer.parse(id)
    chat_history = Message.paginate(%Message.Paginate{room_id: room_id})
    Account.mark_room_messages_as_read(user_id, room_id)

    new_socket =
      assign(socket,
        selected_room: Map.get(rooms, room_id),
        chat_history: chat_history
      )

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "message_box:send",
        %{"content" => content},
        %{assigns: %{current_user: %User{id: user_id}, selected_room: %Room{id: room_id}}} =
          socket
      ) do
    {:ok, %Message{}} =
      Account.send_message(%Request.SendMessage{
        content: content,
        sender_id: user_id,
        room_id: room_id,
        sent_at: DateTime.utc_now()
      })

    new_socket = assign(socket, message_box_content: "")

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("message_box:change", %{"content" => content}, socket) do
    new_socket = assign(socket, message_box_content: content)
    {:noreply, new_socket}
  end

  @impl true
  def handle_info(
        {Roomy.Bus, %Message{room_id: room_id, sender_id: sender_id} = message},
        %{
          assigns: %{
            rooms: rooms,
            chat_history: chat_history,
            current_user: %User{id: current_user_id}
          }
        } = socket
      ) do
    new_rooms = %{rooms | room_id => %{rooms[room_id] | messages: [message]}}

    new_chat_history =
      with %Scrivener.Page{entries: entries} <- chat_history do
        %Scrivener.Page{chat_history | entries: [message | entries]}
      end

    new_socket =
      socket
      |> assign(rooms: new_rooms, chat_history: new_chat_history)
      |> push_event("message:new", %{is_sender: sender_id == current_user_id})

    {:noreply, new_socket}
  end

  @spec get_last_message([Message.t()], pos_integer()) :: String.t()
  defp get_last_message(messages, current_user_id)

  defp get_last_message([], _), do: ""

  defp get_last_message([%Message{content: content, sender_id: current_user_id}], current_user_id) do
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
end
