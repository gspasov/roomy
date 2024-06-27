defmodule RoomyWeb.RoomLive do
  alias Roomy.Bus
  use RoomyWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <%= if is_nil(@name) do %>
        <div>
          <form class="flex justify-between gap-4" phx-submit="name:submit">
            <input
              type="text"
              name="name"
              class="w-full rounded-3xl border-slate-300 border px-5 focus:border-indigo-700"
              placeholder="My name is.."
              phx-debounce="100"
              autocomplete="off"
            />
            <button class="bg-indigo-300 rounded p-3">
              Join
            </button>
          </form>
        </div>
      <% else %>
        <div id="chat_history" class="grow overflow-y-auto" phx-hook="ScrollToBottom">
          <div
            :for={{message, index} <- @chat_history |> Enum.reverse() |> Enum.with_index()}
            class="flex mb-3"
          >
            <div key={"message-#{index}"} class="flex flex-col gap-1">
              <div class="rounded-xl relative px-3 py-2">
                <p class="max-w-prose break-words"><%= message %></p>
              </div>
            </div>
          </div>
        </div>
        <form
          class="flex justify-between gap-4 mt-2"
          phx-submit="message_box:submit"
          phx-change="message_box:change"
        >
          <input
            id="message_box"
            type="text"
            name="message"
            class="w-full rounded-3xl border-slate-300 border px-5 focus:border-indigo-700"
            placeholder="Type your message..."
            phx-debounce="50"
            autocomplete="off"
            value={@message_input}
          />
          <button class="bg-indigo-300 rounded p-3">
            Send
          </button>
        </form>
      <% end %>
    </div>
    """
  end

  @impl true
  def mount(%{"room_id" => room_id} = _params, _session, socket) do
    new_socket =
      assign(socket,
        name: nil,
        name_input: "",
        message_input: "",
        chat_history: [],
        room_id: room_id
      )

    {:ok, new_socket}
  end

  @impl true
  def handle_params(_params, _session, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("message_box:change", %{"message" => message}, socket) do
    {:noreply, assign(socket, message_input: message)}
  end

  @impl true
  def handle_event(
        "message_box:submit",
        _params,
        %{assigns: %{name: name, message_input: message, room_id: room_id}} = socket
      ) do
    whole_message = "#{name}: #{message}"

    room_id
    |> room_topic()
    |> Bus.publish(whole_message)

    {:noreply, assign(socket, message_input: "")}
  end

  @impl true
  def handle_event("name:submit", %{"name" => name}, %{assigns: %{room_id: room_id}} = socket) do
    room_id |> room_topic() |> Bus.subscribe()

    {:noreply, assign(socket, name: name)}
  end

  @impl true
  def handle_info({Bus, message}, %{assigns: %{chat_history: history}} = socket) do
    new_socket =
      socket
      |> assign(chat_history: [message | history])
      |> push_event("message:new", %{is_sender: true})

    {:noreply, new_socket}
  end

  defp room_topic(room_id) do
    "/room/#{room_id}"
  end
end
