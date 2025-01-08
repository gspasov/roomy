defmodule RoomyWeb.HomeLive do
  use RoomyWeb, :live_view

  alias Roomy.Utils
  alias RoomyWeb.RoomLive.LocalStorage
  alias Phoenix.LiveView.AsyncResult

  @impl true
  def render(assigns) do
    ~H"""
    <div
      id="local_storage"
      class="bg-gray-100 h-full flex items-center justify-center"
      phx-hook="Parent"
    >
      <.async_result :let={room_id} assign={@room_id}>
        <div class="flex flex-col bg-white p-8 items-center gap-3 rounded-lg shadow-lg w-full max-w-md">
          <h1 class="text-2xl font-semibold text-center text-gray-800 mb-6">
            <%= if room_id do %>
              Welcome back
            <% else %>
              Welcome to Roomy
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
                class="text-sm font-semibold leading-6 text-white active:text-white/80 bg-red-600 text-white py-2 px-4 rounded-lg shadow-md hover:bg-red-700 focus:outline-none"
              >
                Leave
              </button>
              <.link
                navigate={~p"/room/#{room_id}"}
                class="text-sm font-semibold leading-6 text-white active:text-white/80 bg-green-600 text-white py-2 px-4 rounded-lg shadow-md hover:bg-green-700 focus:outline-none"
              >
                Rejoin
              </.link>
            </div>
            <span class="text-sm italic">
              Leaving a Room will delete your saved chat history.
            </span>
          <% else %>
            <.link
              navigate={~p"/room/#{Roomy.Utils.generate_code()}"}
              class="m-auto text-sm font-semibold leading-6 text-white active:text-white/80 bg-green-600 text-white py-2 px-4 rounded-lg shadow-md hover:bg-green-700 focus:outline-none"
            >
              Create a New Room
            </.link>
            <p>or</p>
            <.link
              navigate={~p"/room/join"}
              class="m-auto text-sm font-semibold leading-6 text-white active:text-white/80 bg-blue-600 text-white py-2 px-4 rounded-lg shadow-md hover:bg-blue-700 focus:outline-none"
            >
              Join Room
            </.link>
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
