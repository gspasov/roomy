defmodule RoomyWeb.HomeLive do
  use RoomyWeb, :live_view

  alias Roomy.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 h-full flex items-center justify-center">
      <div class="flex flex-col bg-white p-8 items-center gap-3 rounded-lg shadow-lg w-full max-w-md">
        <div>
          <h1 class="text-2xl font-semibold text-center text-gray-800 mb-6">Welcome to Roomy</h1>
          <p class="text-gray-600 text-center mb-6">What would you like to do today?</p>
        </div>
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
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(_params, _session, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("create_room", _, socket) do
    room_id = Utils.generate_code()
    {:noreply, push_navigate(socket, to: ~p"/room/#{room_id}")}
  end
end
