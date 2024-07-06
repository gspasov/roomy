defmodule RoomyWeb.RoomLive do
  use RoomyWeb, :live_view

  alias Roomy.Giphy
  alias Roomy.Message
  alias Roomy.Crypto
  alias Roomy.Bus

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
            <div
              id="chat_history"
              class="flex flex-col gap-2 grow overflow-y-auto"
              phx-hook="ScrollToBottom"
            >
              <div
                :for={
                  {%Message{sender: sender_name, sent_at: sent_at} = message, index} <-
                    @chat_history |> Enum.reverse() |> Enum.with_index()
                }
                key={"message-#{index}"}
                class="flex flex-col gap-1"
              >
                <div class="flex flex-col gap-1 px-4">
                  <div class="text-xs">
                    <span class="font-semibold"><%= sender_name %></span>
                    <span><%= Calendar.strftime(sent_at, "%Y/%m/%d %I:%M %p") %></span>
                  </div>

                  <p class="max-w-prose break-words"><%= render_message(message) %></p>
                </div>
              </div>
            </div>
            <form
              class="relative pb-4 px-4 gap-4 mt-2"
              phx-submit="message_box:submit"
              phx-change="message_box:change"
            >
              <div class={[
                "absolute p-2 m-2 columns-2 gap-2 rounded bottom-full right-0 bg-slate-300 overflow-y-auto",
                if(@gif_dialog_open, do: "", else: "hidden")
              ]}>
                <img
                  :for={
                    %Giphy{
                      preview_url: preview_url,
                      preview_width: preview_width,
                      preview_height: preview_height,
                      medium_url: medium_url,
                      medium_width: medium_width,
                      medium_height: medium_height
                    } <- @gifs
                  }
                  class="rounded mb-2 box-border cursor-pointer hover:border-2 hover:border-indigo-500"
                  src={preview_url}
                  height={to_string(preview_height)}
                  width={to_string(preview_width)}
                  phx-click="send_gif"
                  phx-value-gif={render_gif(medium_url, medium_width, medium_height)}
                />
              </div>
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
              <button
                class={[
                  "absolute right-16 top-2 p-2 text-xs rounded-md border border-indigo-500 text-indigo-500 hover:bg-indigo-100",
                  if(@gif_dialog_open, do: "bg-indigo-200", else: "")
                ]}
                type="button"
                phx-click="gif_dialog:toggle"
              >
                GIF
              </button>
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
        room_id: room_id,
        gif_dialog_open: false,
        gifs: [],
        giphy_client: Giphy.client()
      )

    {:ok, new_socket}
  end

  @impl true
  def handle_params(_params, _session, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "gif_dialog:toggle",
        _,
        %{assigns: %{gifs: gifs, giphy_client: client, gif_dialog_open: opened?}} = socket
      ) do
    new_socket =
      with false <- opened?,
           a when a == [] <- gifs,
           {:ok, gifs} <- Giphy.trending_gifs(client, %{limit: 5}) do
        assign(socket, gifs: gifs)
      else
        _ -> socket
      end
      |> assign(gif_dialog_open: not opened?)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("message_box:change", %{"message" => message}, socket) do
    {:noreply, assign(socket, message_input: message)}
  end

  @impl true
  def handle_event(
        "send_gif",
        %{"gif" => gif_img},
        %{assigns: %{name: name, room_id: room_id, participants: participants}} = socket
      ) do
    submit_message(%Message{type: :render, sender: name, content: gif_img}, room_id, participants)

    {:noreply, assign(socket, gif_dialog_open: false)}
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
    submit_message(%Message{sender: name, content: message}, room_id, participants)

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
        {Bus, {:message, name, encrypted_message}},
        %{assigns: %{chat_history: history, participants: participants}} = socket
      ) do
    decrypted_message =
      participants
      |> Map.fetch!(name)
      |> Crypto.decrypt_message(encrypted_message)
      |> :erlang.binary_to_term()

    new_socket =
      socket
      |> assign(chat_history: [decrypted_message | history])
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

  defp submit_message(%Message{sender: name} = message, room_id, participants) do
    Enum.each(participants, fn {receiver_name, aes_key} ->
      encrypted_message = Crypto.encrypt_message(aes_key, :erlang.term_to_binary(message))

      topic = participant_topic(room_id, receiver_name)
      Bus.publish(topic, {:message, name, encrypted_message})
    end)
  end

  defp render_message(%Message{type: :normal, content: content}) do
    content
  end

  defp render_message(%Message{type: :render, content: content}) do
    raw(content)
  end

  defp room_topic(room_id) do
    "/room/#{room_id}"
  end

  defp participant_topic(room_id, participant_name) do
    "/room/#{room_id}/participant/#{participant_name}"
  end

  defp render_gif(url, width, height) do
    "<img src=\"#{url}\" width=\"#{width}\" height=\"#{height}\" class=\"rounded\"/>"
  end
end
