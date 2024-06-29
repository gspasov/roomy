defmodule RoomyWeb.RoomLive do
  alias Roomy.Crypto
  alias Roomy.Bus
  use RoomyWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-col h-full">
      <%= if is_nil(@name) do %>
        <div class="py-10 px-24">
          <h1 class="text-xl pb-8">Welcome to room <span class="italic"><%= @room_id %></span></h1>

          <form class="flex-col justify-between gap-4" phx-submit="name:submit">
            <label for="name">Choose your name</label>
            <div class="flex relative">
              <input
                type="text"
                name="name"
                class="w-full h-12 rounded-3xl border-slate-300 border pr-12 px-5 focus:border-indigo-700"
                placeholder="My name is..."
                phx-debounce="100"
                autocomplete="off"
              />
              <button class="absolute right-1 top-1 h-10 w-10 rounded-full bg-indigo-600 text-stone-100 hover:bg-indigo-500">
                >
              </button>
            </div>
          </form>
        </div>
      <% else %>
        <div class="flex grow h-full">
          <div class="bg-slate-300">
            <h2 class="px-8 bg-slate-400">Participants</h2>
            <div :for={name <- Map.keys(@participants)} class="px-4 py-2">
              <%= name <> if(name == @name, do: " (You)", else: "") %>
            </div>
          </div>
          <div class="flex flex-col grow">
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
              class="relative flex justify-between pb-4 px-4 gap-4 mt-2"
              phx-submit="message_box:submit"
              phx-change="message_box:change"
            >
              <input
                id="message_box"
                type="text"
                name="message"
                class="w-full h-12 rounded-3xl border-slate-300 border pr-12 px-5 focus:border-indigo-700"
                placeholder="Type your message..."
                phx-debounce="50"
                autocomplete="off"
                value={@message_input}
              />
              <button class="absolute right-5 top-1 h-10 w-10 rounded-full bg-indigo-600 text-stone-100 hover:bg-indigo-500">
                >
              </button>
            </form>
          </div>
        </div>
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
        participants: %{},
        public_key: nil,
        private_key: nil,
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
        %{
          assigns: %{
            name: name,
            message_input: message,
            room_id: room_id,
            participants: participants
          }
        } = socket
      ) do
    Enum.each(participants, fn {receiver_name, aes_key} ->
      encrypted_message = Crypto.encrypt_message(aes_key, message)
      topic = participant_topic(room_id, receiver_name)
      Bus.publish(topic, {:message, name, encrypted_message})
    end)

    {:noreply, assign(socket, message_input: "")}
  end

  @impl true
  def handle_event("name:submit", %{"name" => name}, %{assigns: %{room_id: room_id}} = socket) do
    {public_key, private_key} = Crypto.generate_key_pair()
    room_id |> room_topic() |> Bus.subscribe()
    room_id |> participant_topic(name) |> Bus.subscribe()
    room_id |> room_topic() |> Bus.publish({:join, name, public_key})

    {:noreply, assign(socket, name: name, public_key: public_key, private_key: private_key)}
  end

  @impl true
  def handle_info(
        {Bus, {:message, name, message}},
        %{assigns: %{chat_history: history, participants: participants}} = socket
      ) do
    decrypted_message =
      participants
      |> Map.fetch!(name)
      |> Crypto.decrypt_message(message)

    new_socket =
      socket
      |> assign(chat_history: ["#{name}: #{decrypted_message}" | history])
      |> push_event("message:new", %{is_sender: true})

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(
        {Bus, {action, name, public_key}},
        %{
          assigns: %{
            room_id: room_id,
            participants: participants,
            name: my_name,
            public_key: my_public_key,
            private_key: private_key
          }
        } = socket
      )
      when action in [:join, :introduce] do
    aes_key =
      private_key
      |> Crypto.generate_shared_secret(public_key)
      |> Crypto.derive_aes_key()

    if action == :join do
      room_id |> participant_topic(name) |> Bus.publish({:introduce, my_name, my_public_key})
    end

    {:noreply, assign(socket, participants: Map.put(participants, name, aes_key))}
  end

  @impl true
  def handle_info({Bus, {:leave, name}}, %{assigns: %{participants: participants}} = socket) do
    {:noreply, assign(socket, participants: Map.delete(participants, name))}
  end

  defp room_topic(room_id) do
    "/room/#{room_id}"
  end

  defp participant_topic(room_id, participant_name) do
    "/room/#{room_id}/participant/#{participant_name}"
  end
end
