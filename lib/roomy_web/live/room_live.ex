defmodule RoomyWeb.RoomLive do
  alias Roomy.Emoji
  alias RoomyWeb.Icon
  use RoomyWeb, :live_view

  alias Roomy.Giphy
  alias Roomy.Crypto
  alias Roomy.Bus
  alias Phoenix.LiveView.AsyncResult

  defmodule Participant do
    use TypedStruct

    typedstruct required: true do
      field(:id, String.t())
      field(:name, String.t())
      field(:aes_key, binary())
      field(:typing, boolean(), default: false)
      field(:avatar, String.t(), required: false)
      field(:online?, boolean(), default: true)
      field(:left?, boolean(), default: false)
    end

    def compare(%__MODULE__{name: name_1}, %__MODULE__{name: name_2}) do
      n1 = String.downcase(name_1) |> String.normalize(:nfkd)
      n2 = String.downcase(name_2) |> String.normalize(:nfkd)

      cond do
        n1 > n2 ->
          :gt

        n1 < n2 ->
          :lt

        true ->
          :eq
      end
    end
  end

  defmodule Message do
    use TypedStruct

    typedstruct required: true do
      field(:id, String.t())
      field(:type, :text | :render | :system, default: :text)

      field(:kind, :text | :destroy_after | :send_after | :join | :leave | :gif | :image,
        default: :text
      )

      field(:sender_id, String.t())
      field(:content, binary(), required: false)
      field(:execute_at, DateTime.t(), required: false)
      field(:sent_at, DateTime.t())
    end
  end

  defmodule LocalStorage do
    use TypedStruct

    typedstruct required: true do
      field(:id, String.t())
      field(:name, String.t())
      field(:message_input, String.t())
      field(:chat_history, [Message.t()])
      field(:participants, [Participant.t()])
      field(:public_key, String.t())
      field(:private_key, String.t())
      field(:room_id, String.t())
    end
  end

  # GIF related todos
  # @TODO: Store in DB all Gifs so that we don't use that much the API
  # @TODO: Add scroll for Gifs
  # @TODO: Add search bar for Gifs
  # @TODO: Add GIPHY name in the gifs corner (for brand recognition)

  # Emoji related
  # @TODO: User can type/search emojies with `:` prompt

  # Overall functionality
  # @TODO: Store encrypted messages in DB. Figure out how to encrypt/decrypt them efficiently for a group chat
  # @TODO: Pasting image url should display the image in the chat instead
  # @TODO: Ability to react to messages
  # @TODO: Ability to reply to a message
  # @TODO: Make the UI prettier

  @impl true
  def render(assigns) do
    ~H"""
    <div class="h-full" id="local_storage" phx-hook="Parent">
      <.modal id="confirm_modal">
        <h2 class="text-xl font-semibold text-gray-800">Leave Room</h2>
        <p class="text-gray-600 mt-2">
          Are you sure you want to leave this room? Doing so will delete your chat history. <br />
          This cannot be undone.
        </p>
        <div class="flex justify-end space-x-3 mt-6">
          <button
            class="px-4 py-2 bg-gray-200 text-gray-800 rounded-md hover:bg-gray-300 transition"
            phx-click={hide_modal("confirm_modal")}
          >
            Cancel
          </button>
          <button
            class="px-4 py-2 bg-indigo-500 text-white rounded-md hover:bg-indigo-600 transition"
            phx-click="leave_room"
          >
            Confirm
          </button>
        </div>
      </.modal>
      <.async_result :let={name} assign={@name}>
        <%= if is_nil(name) do %>
          <div
            class="bg-gray-100 flex items-center h-full justify-center"
            phx-remove={JS.focus(to: "#message_box")}
          >
            <div class="flex flex-col bg-white p-8 items-center gap-3 rounded-lg shadow-lg w-full max-w-md">
              <div>
                <h1 class="text-2xl font-semibold text-center text-gray-800 mb-6">
                  Welcome to Room {@room_id}
                </h1>
              </div>
              <.form :let={f} class="flex flex-col gap-3" for={%{}} phx-submit="name:submit">
                <.input
                  field={f[:name]}
                  type="text"
                  maxlength="24"
                  label="Name"
                  placeholder="Your name"
                  autofocus
                  required
                />
                <.button class="bg-indigo-500 text-white py-2 px-4 rounded-lg shadow-md hover:bg-indigo-600 focus:outline-none">
                  Enter
                </.button>
              </.form>
              <.link navigate={~p"/"} class="underline text-indigo-500 hover:text-indigo-600 text-xs">
                Back
              </.link>
            </div>
          </div>
        <% else %>
          <div id="notify" class="flex flex-col h-full" phx-hook="BrowserNotification">
            <%!-- <header class="flex items-center justify-between px-4 h-12 flex-shrink-0 shadow">
              <h1 class="text-xl">Roomy</h1>
              <button
                id="copy_room_invite_button"
                class="px-3 py-1 border rounded-lg border-slate-700 text-slate-700 hover:bg-slate-300 active:bg-slate-400"
                phx-hook="Clipboard"
                value={build_room_join_url(@room_id)}
              >
                Copy invite
              </button>
            </header> --%>
            <div class="flex grow overflow-y-auto">
              <%!-- Participants area --%>
              <div class="flex flex-col items-center justify-between px-4 text-white bg-purple">
                <div>
                  <h2 class="text-3xl py-4 font-bold">Roomy</h2>
                  <div class="columns-2 gap-2">
                    <div
                      :for={
                        %Participant{id: id, name: name, online?: online?} <-
                          @participants
                          |> Map.values()
                          |> Enum.reject(fn %Participant{left?: left?} -> left? end)
                          |> Enum.sort(Participant)
                      }
                      class={[
                        "flex flex-col items-center gap-1 max-w-20 p-2 mb-2 rounded-xl cursor-default break-inside-avoid",
                        if(online?, do: "hover:bg-slate-600", else: "opacity-50"),
                        if(id == @id, do: "bg-yellow-900", else: "bg-slate-700")
                      ]}
                    >
                      <div class="w-14 h-14 overflow-hidden rounded-2xl">
                        {raw(fetch_sender(@participants, id).avatar)}
                      </div>
                      <div class="text-center">{name}</div>
                    </div>
                  </div>
                </div>
                <button
                  class="mx-4 my-4 px-4 py-1.5 py-1 border rounded-md border-red-600 text-red-600 hover:text-red-700 hover:border-red-700"
                  phx-click={show_modal("confirm_modal")}
                >
                  Leave
                </button>
              </div>

              <%!-- Chat area --%>
              <div class="flex flex-col relative grow bg-my_gray text-purple">
                <%!-- Chat header --%>
                <div class="absolute w-full h-24 px-8 py-4 bg-opacity-50 backdrop-blur">
                  <div class="text-2xl text-dark font-semibold">Office chat</div>
                  <div class="text-xs font-semibold">{map_size(@participants)} members</div>
                </div>
                <%!-- Chat body --%>
                <div
                  id="chat_history"
                  class="flex flex-col gap-2 pt-24 pb-2 grow overflow-y-auto"
                  phx-hook="ScrollToBottom"
                >
                  <%!-- Messages --%>
                  <div
                    :for={
                      {%Message{
                         type: type,
                         kind: kind,
                         sender_id: sender_id,
                         sent_at: sent_at,
                         execute_at: execute_at
                       } = message, index} <- Enum.with_index(@chat_history)
                    }
                    key={"message-#{index}"}
                  >
                    <%= if type == :system do %>
                      <div class="flex justify-center">
                        <div class="flex items-center gap-2 py-2 px-4 text-xs text-white font-medium rounded-full bg-purple opacity-75">
                          <div class="w-6 h-6 overflow-hidden rounded-2xl">
                            {raw(fetch_sender(@participants, sender_id).avatar)}
                          </div>
                          <span :if={kind == :join}>
                            {format_message(message, fetch_sender(@participants, sender_id).name)}
                          </span>
                          <span :if={kind == :leave}>
                            {format_message(message, fetch_sender(@participants, sender_id).name)}
                          </span>
                        </div>
                      </div>
                    <% else %>
                      <div class="px-4 py-2 hover:bg-slate-300">
                        <div class={["flex gap-2", if(sender_id == @id, do: "justify-end")]}>
                          <div :if={sender_id != @id} class="w-14 h-14 overflow-hidden rounded-2xl">
                            {raw(fetch_sender(@participants, sender_id).avatar)}
                          </div>
                          <div>
                            <div class={[
                              "font-semibold text-dark",
                              if(sender_id == @id, do: "text-right")
                            ]}>
                              {fetch_sender(@participants, sender_id).name}
                              <span :if={kind == :destroy_after}>
                                Self destroy in {DateTime.diff(execute_at, DateTime.utc_now())} seconds
                              </span>
                            </div>

                            <div class={[
                              "max-w-prose break-words p-4 mt-1 rounded-3xl",
                              if(sender_id == @id,
                                do: "rounded-tr-sm bg-bubble_2",
                                else: "rounded-tl-sm bg-bubble_1"
                              )
                            ]}>
                              <p>{render_message(message)}</p>
                              <div class="text-xs text-slate-600 text-right">
                                {sent_at
                                |> DateTime.shift_zone!(@timezone)
                                |> Calendar.strftime("%H:%M")}
                              </div>
                            </div>
                          </div>
                          <div :if={sender_id == @id} class="w-14 h-14 overflow-hidden rounded-2xl">
                            {raw(fetch_sender(@participants, sender_id).avatar)}
                          </div>
                        </div>
                      </div>
                    <% end %>
                  </div>
                </div>

                <%!-- Participant typing visualization section --%>
                <div class="absolute w-full bottom-16 flex gap-2 px-6 bg-opacity-50 backdrop-blur">
                  <div
                    :for={
                      {_, %Participant{avatar: avatar}} <-
                        Enum.filter(@participants, fn {_, %Participant{typing: typing}} ->
                          typing
                        end)
                    }
                    class="flex items-center gap-2 text-xs font-medium py-1"
                  >
                    <div class="w-6 h-6 overflow-hidden rounded-2xl">
                      {raw(avatar)}
                    </div>
                    <div class="flex gap-1 justify-center items-center">
                      <span>is typing</span>
                      <div class="h-1.5 w-1.5 bg-black rounded-full animate-bounce [animation-delay:-0.25s]">
                      </div>
                      <div class="h-1.5 w-1.5 bg-black rounded-full animate-bounce [animation-delay:-0.10s]">
                      </div>
                      <div class="h-1.5 w-1.5 bg-black rounded-full animate-bounce"></div>
                    </div>
                  </div>
                </div>
                <%!-- Message Input --%>
                <form
                  class="relative pb-4 px-4 gap-4"
                  phx-submit="message_box:submit"
                  phx-change="message_box:change"
                >
                  <%!-- Gif Dialog --%>
                  <div
                    id="gif_dialog"
                    class={[
                      "absolute m-2 w-96 min-h-96 max-h-[500px] overflow-y-auto rounded bottom-full right-0 bg-slate-500 hidden",
                      if(not Enum.empty?(@gifs), do: "p-2")
                    ]}
                    phx-click-away={hide("#gif_dialog") |> JS.push("gif_dialog:toggle")}
                  >
                    <div class="columns-2 gap-2">
                      <span
                        :if={Enum.empty?(@gifs)}
                        class="absolute w-full h-full flex items-center justify-center"
                      >
                        <Icon.loading class="h-10 w-10 animate-spin bg-slate-500 text-slate-200" />
                      </span>
                      <img
                        :for={
                          %Giphy{
                            title: title,
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
                        alt={title}
                        height={to_string(preview_height)}
                        width={to_string(preview_width)}
                        phx-click="send_gif"
                        phx-value-gif={render_gif(medium_url, medium_width, medium_height)}
                      />
                    </div>
                  </div>

                  <%!-- Emojis Dialog --%>
                  <div
                    id="emoji_dialog"
                    class={[
                      "absolute m-2 flex rounded bottom-full right-0 bg-slate-500 hidden"
                    ]}
                    phx-click-away={hide("#emoji_dialog")}
                  >
                    <h2 class="font-semibold text-3xl text-white px-4 pt-2">Emojis</h2>
                    <div class="w-96 h-96 m-2 mb-0 flex flex-col gap-10 overflow-y-auto">
                      <div :for={{_group, emojis} <- @emoji_groups} class="p-2 grid grid-cols-7 gap-4">
                        <span
                          :for={%Emoji{unicode: unicode} <- emojis}
                          class="text-3xl cursor-pointer transition ease-in-out delay-50 duration-300 hover:-translate-1 hover:scale-110"
                          phx-click="add_emoji"
                          phx-value-unicode={unicode}
                        >
                          {unicode}
                        </span>
                      </div>
                    </div>
                  </div>

                  <%!-- Message type dialog --%>
                  <div
                    id="message_type_dialog"
                    class="absolute px-4 py-2 m-2 flex flex-col gap-4 rounded bottom-full right-0 bg-slate-500 overflow-y-auto hidden"
                    phx-click-away={hide("#message_type_dialog")}
                  >
                    <p class="text-md font-semibold">Message Type</p>
                    <div class="flex flex-col gap-1">
                      <div class="flex items-center gap-2">
                        <Icon.chat />
                        <span>Normal</span>
                      </div>
                      <button
                        class={[
                          "rounded-full h-10 w-10 text-white",
                          if(@message_type == :text, do: "bg-indigo-500", else: "bg-gray-500")
                        ]}
                        type="button"
                        phx-click="message_type:select"
                        phx-value-type="text"
                      >
                        <Icon.chat class="m-auto" />
                      </button>
                    </div>
                    <div class="flex flex-col gap-1">
                      <div class="flex items-center gap-2">
                        <Icon.clock_history />
                        <span>Send after</span>
                      </div>
                      <div class="flex items-center gap-2">
                        <button
                          :for={{variant, text, time} <- send_after_values()}
                          class={[
                            "rounded-full h-10 w-10 text-white text-xs",
                            if(@message_type == :send_after and @message_variant == variant,
                              do: "bg-indigo-500",
                              else: "bg-gray-500"
                            )
                          ]}
                          type="button"
                          phx-click="message_type:select"
                          phx-value-type="send_after"
                          phx-value-variant={variant}
                          phx-value-milliseconds={time}
                        >
                          {text}
                        </button>
                      </div>
                    </div>
                    <div class="flex flex-col gap-1">
                      <div class="flex items-center gap-2">
                        <Icon.stopwatch />
                        <span>Self destroy after</span>
                      </div>
                      <div class="flex items-center gap-2">
                        <button
                          :for={{variant, text, time} <- send_after_values()}
                          class={[
                            "rounded-full h-10 w-10 text-white text-xs",
                            if(@message_type == :destroy_after and @message_variant == variant,
                              do: "bg-indigo-500",
                              else: "bg-gray-500"
                            )
                          ]}
                          type="button"
                          phx-click="message_type:select"
                          phx-value-type="destroy_after"
                          phx-value-variant={variant}
                          phx-value-milliseconds={time}
                        >
                          {text}
                        </button>
                      </div>
                    </div>
                  </div>

                  <input
                    id="message_box"
                    type="text"
                    name="message"
                    class="w-full h-12 rounded-3xl border-slate-300 border pr-12 px-5 focus:border-indigo-700"
                    placeholder="Type your message..."
                    phx-debounce="50"
                    phx-hook="PasteScreenshot"
                    autocomplete="off"
                    value={@message_input}
                  />
                  <button
                    class={[
                      "absolute right-28 top-2 p-2 font-semibold text-xs rounded-md border border-indigo-500 text-indigo-500 transition ease-in-out delay-50 duration-300 hover:-translate-1 hover:scale-110 hover:bg-indigo-100",
                      if(@gif_dialog_open, do: "bg-indigo-200", else: "")
                    ]}
                    type="button"
                    phx-click={show("#gif_dialog") |> JS.push("gif_dialog:toggle")}
                  >
                    GIF
                  </button>
                  <button
                    id="emoji_button"
                    class={[
                      "absolute right-16 top-1 text-indigo-500 text-3xl transition ease-in-out delay-50 duration-300 hover:-translate-1 hover:scale-110"
                    ]}
                    type="button"
                    phx-hook="MouseEnter"
                    phx-click={show("#emoji_dialog")}
                  >
                    {@emoji_button_unicode}
                  </button>
                  <button
                    class="absolute right-5 top-1 h-10 w-10 rounded-full bg-indigo-600 text-stone-100 hover:bg-indigo-500"
                    type="button"
                    phx-click={show("#message_type_dialog")}
                  >
                    <Icon.chat :if={@message_type == :text} class="m-auto" />
                    <Icon.clock_history :if={@message_type == :send_after} class="m-auto" />
                    <Icon.stopwatch :if={@message_type == :destroy_after} class="m-auto" />
                  </button>
                </form>
              </div>
            </div>
          </div>
        <% end %>
      </.async_result>
    </div>
    """
  end

  @impl true
  def mount(%{"room_id" => room_id} = _params, _session, socket) do
    emoji_groups = Emoji.get_groups()
    gifs = Roomy.GiphyScrapper.get_gifs() |> Enum.take(100)

    new_socket =
      assign(socket,
        id: nil,
        name: AsyncResult.loading(),
        message_input: "",
        chat_history: [],
        participants: %{},
        public_key: nil,
        private_key: nil,
        room_id: room_id,
        gif_dialog_open: false,
        message_type: :text,
        message_variant: nil,
        message_timer: nil,
        gifs: gifs,
        giphy_client: Giphy.client(),
        emoji_groups: emoji_groups,
        emoji_button_unicode: get_random_emoji_unicode(emoji_groups),
        timezone: socket.private[:connect_params]["timezone"],
        typing_refs: %{}
      )

    {:ok, new_socket}
  end

  @impl true
  def handle_params(_params, _session, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("restore_from_local_storage", %{"value" => value}, socket) do
    new_socket =
      if value do
        %LocalStorage{
          id: id,
          name: name,
          message_input: message_input,
          chat_history: chat_history,
          participants: participants,
          public_key: public_key,
          private_key: private_key,
          room_id: room_id
        } = value |> Base.decode64!() |> :erlang.binary_to_term()

        room_id |> room_topic() |> Bus.subscribe()
        participant_topic = participant_topic(room_id, id)
        Bus.subscribe(participant_topic)

        participant_topic
        |> Bus.get_subscribers()
        |> length()
        |> Kernel.==(1)
        |> if do
          room_id |> room_topic() |> Bus.publish({:join, id, name, public_key})
        end

        assign(socket,
          id: id,
          name: AsyncResult.ok(name),
          message_input: message_input,
          chat_history: chat_history,
          participants: participants,
          public_key: public_key,
          private_key: private_key,
          room_id: room_id
        )
      else
        assign(socket, name: AsyncResult.ok(nil))
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_event("name:submit", %{"name" => name}, %{assigns: %{room_id: room_id}} = socket) do
    trimmed_name = String.trim(name)

    new_socket =
      if String.length(trimmed_name) == 0 do
        socket
      else
        id = UUID.uuid4()
        {public_key, private_key} = Crypto.generate_key_pair()
        room_id |> room_topic() |> Bus.subscribe()
        room_id |> participant_topic(id) |> Bus.subscribe()
        room_id |> room_topic() |> Bus.publish({:join, id, trimmed_name, public_key})

        assign(socket,
          id: id,
          name: AsyncResult.ok(trimmed_name),
          public_key: public_key,
          private_key: private_key
        )
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "message_box:change",
        %{"message" => message},
        %{assigns: %{room_id: room_id, participants: participants, id: id}} = socket
      ) do
    room_id |> room_topic() |> Bus.publish({:typing, Map.fetch!(participants, id)})
    {:noreply, assign(socket, message_input: message)}
  end

  @impl true
  def handle_event(
        "message_box:submit",
        _params,
        %{
          assigns: %{
            id: id,
            message_input: message,
            room_id: room_id,
            participants: participants,
            message_type: message_type,
            message_variant: message_variant
          }
        } = socket
      ) do
    execute_at =
      case message_variant do
        1 -> DateTime.utc_now() |> DateTime.add(10, :second)
        2 -> DateTime.utc_now() |> DateTime.add(30, :second)
        3 -> DateTime.utc_now() |> DateTime.add(1, :minute)
        _ -> nil
      end

    if String.trim(message) != "" do
      message = %Message{
        id: UUID.uuid4(),
        sender_id: id,
        content: message,
        kind: message_type,
        execute_at: execute_at
      }

      case message_type do
        :send_after ->
          Process.send_after(
            self(),
            {:send_delayed_message, message},
            DateTime.diff(execute_at, DateTime.utc_now(), :millisecond)
          )

        _ ->
          publish_message_to_all(message, room_id, participants)
      end
    end

    {:noreply, assign(socket, message_input: "")}
  end

  @impl true
  def handle_event(
        "gif_dialog:toggle",
        _,
        %{assigns: %{gifs: _gifs, giphy_client: _client, gif_dialog_open: opened?}} = socket
      ) do
    # new_socket =
    #   with false <- opened?,
    #        a when a == [] <- gifs,
    #        {:ok, gifs} <- Giphy.trending_gifs(client, %{limit: 5}) do
    #     assign(socket, gifs: gifs)
    #   else
    #     _ -> socket
    #   end
    #   |> assign(gif_dialog_open: not opened?)

    new_socket = assign(socket, gif_dialog_open: not opened?)

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "send_gif",
        %{"gif" => gif_img},
        %{assigns: %{id: id, room_id: room_id, participants: participants}} = socket
      ) do
    publish_message_to_all(
      %Message{
        type: :render,
        kind: :gif,
        sender_id: id,
        content: gif_img
      },
      room_id,
      participants
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "add_emoji",
        %{"unicode" => unicode},
        %{assigns: %{message_input: input}} = socket
      ) do
    {:noreply, assign(socket, message_input: input <> "#{unicode} ")}
  end

  @impl true
  def handle_event("message_type:select", %{"type" => message_type} = params, socket) do
    variant = params |> Map.get("variant", "1") |> String.to_integer()
    milliseconds = params |> Map.get("milliseconds", "1") |> String.to_integer()

    new_socket =
      case message_type do
        "text" ->
          assign(socket, message_type: :text)

        "send_after" ->
          assign(socket,
            message_type: :send_after,
            message_variant: variant,
            message_timer: milliseconds
          )

        "destroy_after" ->
          assign(socket,
            message_type: :destroy_after,
            message_variant: variant,
            message_timer: milliseconds
          )
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_event(
        "mouse_enter",
        %{"id" => "emoji_button"},
        %{assigns: %{emoji_groups: groups}} = socket
      ) do
    {:noreply, assign(socket, emoji_button_unicode: get_random_emoji_unicode(groups))}
  end

  @impl true
  def handle_event(
        "upload_screenshot",
        %{"image" => base64_image},
        %{assigns: %{id: sender_id, room_id: room_id, participants: participants}} = socket
      ) do
    publish_message_to_all(
      %Message{
        id: UUID.uuid4(),
        type: :render,
        kind: :image,
        sender_id: sender_id,
        content: "<img src=\"#{base64_image}\" alt=\"Screenshot\" class=\"rounded\" />"
      },
      room_id,
      participants
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "leave_room",
        _params,
        %{assigns: %{id: id, room_id: room_id, participants: participants}} = socket
      ) do
    Bus.publish(room_topic(room_id), {:leave, id})

    publish_message_to_all(
      %Message{type: :system, kind: :leave, sender_id: id},
      room_id,
      participants
    )

    {:noreply, socket}
  end

  @impl true
  def handle_event(
        "generated_avatar",
        %{"id" => id, "svg" => svg},
        %{assigns: %{participants: participants}} = socket
      ) do
    updated_participants =
      Map.update!(participants, id, fn %Participant{} = p -> %Participant{p | avatar: svg} end)

    new_socket =
      socket
      |> assign(participants: updated_participants)
      |> to_storage()

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(
        {Bus, {:message, id, encrypted_message}},
        %{assigns: %{chat_history: history, id: my_id, participants: participants}} =
          socket
      ) do
    %Participant{aes_key: aes_key} = Map.fetch!(participants, id)

    %Message{type: type, kind: kind, sender_id: sender_id, execute_at: execute_at} =
      decrypted_message =
      encrypted_message
      |> Crypto.decrypt_message(aes_key)
      |> :erlang.binary_to_term()

    case {type, kind} do
      {:text, :destroy_after} ->
        Process.send_after(
          self(),
          {:self_destroy, decrypted_message},
          DateTime.diff(execute_at, DateTime.utc_now(), :millisecond)
        )

      _ ->
        nil
    end

    new_socket =
      socket
      |> assign(
        chat_history:
          Enum.sort_by(
            [decrypted_message | history],
            fn %Message{sent_at: sent_at} -> sent_at end,
            DateTime
          )
      )
      |> push_event("message:new", %{is_sender: true})
      |> then(fn new_socket ->
        if sender_id != my_id do
          %Participant{name: sender_name} = fetch_sender(participants, sender_id)

          {title, body} =
            case {type, kind} do
              {:system, :join} ->
                {"🔥 #{sender_name} joined the room!", "Come to say hi."}

              {:system, :leave} ->
                {"😔 #{sender_name} left the room!", nil}

              {:render, :gif} ->
                {"👀 #{sender_name} send a GIF!", "Come check it out!"}

              {_, _} ->
                {"💬 #{sender_name} send a new message!", "Open the app to see the message"}
            end

          push_event(new_socket, "trigger_notification", %{
            title: title,
            body: body
          })
        else
          new_socket
        end
      end)

    {:noreply, to_storage(new_socket)}
  end

  @impl true
  def handle_info(
        {Bus, {:join, id, name, public_key}},
        %{
          assigns: %{
            id: my_id,
            name: %AsyncResult{result: my_name},
            room_id: room_id,
            public_key: my_public_key,
            participants: participants,
            private_key: my_private_key
          }
        } = socket
      ) do
    aes_key =
      my_private_key
      |> Crypto.generate_shared_secret(public_key)
      |> Crypto.derive_aes_key()

    already_know_participant? = Map.has_key?(participants, id)

    updated_participants =
      Map.put(participants, id, %Participant{id: id, name: name, aes_key: aes_key})

    if id != my_id and not already_know_participant? do
      room_id
      |> participant_topic(id)
      |> Bus.publish({:handshake, my_id, my_name, my_public_key})
    end

    new_socket =
      socket
      |> assign(participants: updated_participants)
      |> push_event("generate_avatar", %{name: name, id: id})
      |> to_storage()

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(
        {Bus, {:handshake, id, name, public_key}},
        %{
          assigns: %{
            id: my_id,
            room_id: room_id,
            participants: participants,
            private_key: my_private_key
          }
        } = socket
      ) do
    aes_key =
      my_private_key
      |> Crypto.generate_shared_secret(public_key)
      |> Crypto.derive_aes_key()

    participant = %Participant{id: id, name: name, aes_key: aes_key}
    updated_participants = Map.put(participants, id, participant)

    publish_message(
      participant,
      %Message{type: :system, kind: :join, sender_id: my_id},
      room_id
    )

    new_socket =
      socket
      |> assign(participants: updated_participants)
      |> push_event("generate_avatar", %{name: name, id: id})
      |> to_storage()

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(
        {Bus, {:leave, id}},
        %{assigns: %{id: my_id, room_id: room_id, participants: participants}} = socket
      ) do
    new_socket =
      if id == my_id do
        room_topic = room_topic(room_id)
        participant_topic = participant_topic(room_id, id)
        Bus.unsubscribe(room_topic)
        Bus.unsubscribe(participant_topic)

        socket
        |> push_event("clear_storage", %{})
        |> push_navigate(to: ~p"/")
      else
        socket
        |> assign(
          participants:
            Map.update!(participants, id, fn %Participant{} = participant ->
              %Participant{participant | left?: true}
            end)
        )
        |> to_storage
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_info({Bus, {:close_page, id}}, %{assigns: %{participants: participants}} = socket) do
    new_socket =
      socket
      |> assign(
        participants:
          Map.update!(participants, id, fn %Participant{} = participant ->
            %Participant{participant | online?: false}
          end)
      )
      |> to_storage

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(
        {Bus, {:typing, %Participant{id: id} = participant}},
        %{assigns: %{id: my_id, participants: participants, typing_refs: typing_refs}} = socket
      ) do
    new_socket =
      if id == my_id do
        socket
      else
        updated_participants =
          Map.update!(participants, id, fn %Participant{} = p ->
            %Participant{p | typing: true}
          end)

        current_participant_typing_ref = Map.get(typing_refs, id)

        if current_participant_typing_ref do
          Process.cancel_timer(current_participant_typing_ref)
        end

        new_typing_ref =
          Process.send_after(self(), {:stop_typing, participant}, :timer.seconds(1))

        assign(socket,
          participants: updated_participants,
          typing_refs: Map.put(typing_refs, id, new_typing_ref)
        )
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(
        {:stop_typing, %Participant{id: id}},
        %{assigns: %{id: my_id, participants: participants}} = socket
      ) do
    new_socket =
      if id != my_id do
        updated_participants =
          Map.update!(participants, id, fn %Participant{} = p ->
            %Participant{p | typing: false}
          end)

        assign(socket, participants: updated_participants)
      else
        socket
      end

    {:noreply, new_socket}
  end

  @impl true
  def handle_info(
        {:self_destroy, %Message{id: message_id}},
        %{assigns: %{chat_history: messages}} = socket
      ) do
    updated_message_history =
      Enum.drop_while(messages, fn %Message{id: id} -> id == message_id end)

    {:noreply, assign(socket, chat_history: updated_message_history)}
  end

  @impl true
  def handle_info(
        {:send_delayed_message, %Message{} = message},
        %{assigns: %{room_id: room_id, participants: participants}} = socket
      ) do
    publish_message_to_all(message, room_id, participants)
    {:noreply, socket}
  end

  @impl true
  def terminate(_reason, %{assigns: %{id: id, room_id: room_id}}) do
    if id do
      room_topic = room_topic(room_id)
      participant_topic = participant_topic(room_id, id)
      Bus.unsubscribe(room_topic)
      Bus.unsubscribe(participant_topic)

      # @NOTE: Do not send close_page message if there is another tab (with the chat) open.
      # User is not considered offline if he still has a page with the chat open.
      participant_topic
      |> Bus.get_subscribers()
      |> Kernel.==([])
      |> if do
        Bus.publish(room_topic, {:close_page, id})
      end
    end
  end

  defp publish_message_to_all(%Message{} = message, room_id, participants) do
    Enum.each(participants, fn {_id, %Participant{} = receiver} ->
      publish_message(receiver, message, room_id)
    end)
  end

  defp publish_message(
         %Participant{id: receiver_id, aes_key: aes_key},
         %Message{sender_id: sender_id} = message,
         room_id
       ) do
    encrypted_message =
      %Message{message | sent_at: DateTime.utc_now()}
      |> :erlang.term_to_binary()
      |> Crypto.encrypt_message(aes_key)

    topic = participant_topic(room_id, receiver_id)
    Bus.publish(topic, {:message, sender_id, encrypted_message})
  end

  defp render_message(%Message{type: :render, content: content}) do
    raw(content)
  end

  defp render_message(%Message{content: content}) do
    emoji_enlarger(content)
  end

  defp emoji_enlarger(text) do
    text
    |> html_escape()
    |> Phoenix.HTML.Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Emoji.replace_with(fn emoji_unicode ->
      "<span class=\"text-2xl\">#{emoji_unicode}</span>"
    end)
    |> raw()
  end

  defp format_message(%Message{type: :system, kind: kind}, sender_name) do
    case kind do
      :join -> "#{sender_name} joined the chat 🔥"
      :leave -> "#{sender_name} left the chat 😔"
    end
  end

  defp fetch_sender(participants, sender_id) do
    participants
    |> Enum.find(fn {_, %Participant{id: id}} -> id == sender_id end)
    |> elem(1)
  end

  defp get_random_emoji_unicode(%{0 => face_emojis}) do
    Enum.random(face_emojis).unicode
  end

  defp to_storage(
         %{
           assigns: %{
             id: id,
             name: %AsyncResult{result: name},
             message_input: message_input,
             chat_history: chat_history,
             participants: participants,
             public_key: public_key,
             private_key: private_key,
             room_id: room_id
           }
         } = socket
       ) do
    storage =
      :erlang.term_to_binary(%LocalStorage{
        id: id,
        name: name,
        message_input: message_input,
        chat_history: chat_history,
        participants: participants,
        public_key: public_key,
        private_key: private_key,
        room_id: room_id
      })
      |> Base.encode64()

    push_event(socket, "save_to_local_storage", %{value: storage})
  end

  defp room_topic(room_id) do
    "/room/#{room_id}"
  end

  defp participant_topic(room_id, participant_id) do
    "/room/#{room_id}/participant/#{participant_id}"
  end

  defp render_gif(url, width, height) do
    "<img src=\"#{url}\" width=\"#{width}\" height=\"#{height}\" class=\"rounded\"/>"
  end

  defp send_after_values do
    [{1, "10s", :timer.seconds(10)}, {2, "30s", :timer.seconds(30)}, {3, "1m", :timer.minutes(1)}]
  end

  defp build_room_join_url(room_id) do
    "http://localhost:4000/room/#{room_id}"
  end
end
