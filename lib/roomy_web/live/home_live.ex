defmodule RoomyWeb.HomeLive do
  use RoomyWeb, :live_view

  alias Roomy.Utils
  alias RoomyWeb.Icon
  alias RoomyWeb.RoomLive.LocalStorage
  alias Phoenix.LiveView.AsyncResult

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="local_storage"
      class="bg-my_purple_very_dark h-full flex flex-col gap-16 items-center justify-center"
      phx-hook="Parent"
    >
      <div class="flex flex-col items-start text-white font-bold">
        <span class="text-6xl">Welcome to</span>
        <span class="text-8xl"> Roomy </span>
        <span>Your local room client.</span>
      </div>
      <div
        :if={@room_id.loading}
        class="flex items-center justify-center bg-white rounded-lg min-w-96 px-16 h-64"
      >
        <Icon.loading class="h-10 w-10 animate-spin bg-white text-my_purple_very_dark" />
      </div>
      <.async_result :let={room_id} assign={@room_id}>
        <div class="flex flex-col bg-white p-8 items-center gap-3 rounded-lg shadow-lg w-full max-w-md">
          <h1 class="text-2xl font-semibold text-center text-gray-800 mb-6">
            <%= if room_id do %>
              Welcome back
            <% else %>
              So now what?
            <% end %>
          </h1>
          <p class="text-gray-600 text-center mb-6">
            <%= if room_id do %>
              You are already participant of the room <b>{room_id}</b>. Do you wish to Rejoin or Leave the Room?
              <br />
            <% else %>
              You can either create a brand new Room or join an already existing one
            <% end %>
          </p>
          <%= if room_id do %>
            <div class="flex gap-4 w-full justify-around">
              <button
                phx-click="leave_room"
                class="py-2 px-4 text-sm font-semibold leading-6 rounded-lg shadow-md text-white bg-my_red hover:bg-my_red_dark active:text-white/80 focus:outline-none"
              >
                Leave
              </button>
              <.link
                navigate={~p"/room/#{room_id}"}
                class="py-2 px-4 text-sm font-semibold leading-6 rounded-lg shadow-md text-white bg-my_green hover:bg-my_green_dark active:text-white/80 focus:outline-none"
              >
                Rejoin
              </.link>
            </div>
            <span class="text-sm italic">
              Leaving a Room will delete your saved chat history.
            </span>
          <% else %>
            <div class="flex gap-4 w-full items-center justify-center">
              <.link
                navigate={~p"/room/join"}
                class="m-auto py-2 px-4 text-sm font-semibold leading-6 rounded-lg shadow-md text-white bg-my_blue hover:bg-my_blue_dark active:text-white/80 focus:outline-none"
              >
                Join Room
              </.link>
              <span>or</span>
              <.link
                navigate={~p"/room/#{Roomy.Utils.generate_code()}"}
                class="m-auto py-2 px-4 text-sm font-semibold leading-6 rounded-lg shadow-md text-white bg-my_green hover:bg-my_green_dark active:text-white/80 focus:outline-none"
              >
                Create Room
              </.link>
            </div>
          <% end %>
        </div>
      </.async_result>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, room_id: AsyncResult.loading())}
  end

  @impl true
  def handle_params(_params, _session, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("restore_from_local_storage", %{"value" => value}, socket) do
    room_id =
      if value do
        %LocalStorage{room_id: room_id} =
          value |> Base.decode64!() |> :erlang.binary_to_term()

        room_id
      end

    {:noreply, assign(socket, room_id: AsyncResult.ok(room_id))}
  end

  @impl true
  def handle_event("create_room", _, socket) do
    room_id = Utils.generate_code()
    {:noreply, push_navigate(socket, to: ~p"/room/#{room_id}")}
  end

  @impl true
  def handle_event("leave_room", _params, socket) do
    new_socket =
      socket
      |> push_event("clear_storage", %{})
      |> push_navigate(to: ~p"/")

    {:noreply, new_socket}
  end
end
