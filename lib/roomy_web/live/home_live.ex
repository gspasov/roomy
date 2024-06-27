defmodule RoomyWeb.HomeLive do
  use RoomyWeb, :live_view

  alias Roomy.Utils

  @impl true
  def render(assigns) do
    ~H"""
    <button class="bg-indigo-300 rounded p-3" phx-click="create_room">Create room</button>
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
