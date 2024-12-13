defmodule RoomyWeb.JoinRoomLive do
  use RoomyWeb, :live_view

  alias RoomyWeb.Forms.CreateRoom

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-gray-100 h-full flex items-center justify-center">
      <div class="flex flex-col bg-white p-8 items-center gap-3 rounded-lg shadow-lg w-full max-w-md">
        <div>
          <h1 class="text-2xl font-semibold text-center text-gray-800 mb-6">Joining a Room</h1>
        </div>
        <.form :let={f} for={@form} phx-submit="join" class="flex flex-col gap-3">
          <.input
            field={f[:room_id]}
            type="text"
            label="Room ID"
            placeholder="Room ID"
            autofocus
            required
          />
          <.button class="bg-green-600 text-white py-2 px-4 rounded-lg shadow-md hover:bg-green-700 focus:outline-none">
            Next
          </.button>
        </.form>
        <.link navigate={~p"/"} class="underline text-indigo-500 hover:text-indigo-600 text-xs">
          Back
        </.link>
      </div>
    </div>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, form: to_form(CreateRoom.changeset(%{}), as: "room"))}
  end

  @impl true
  def handle_params(_params, _session, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("join", %{"room" => room_params}, socket) do
    new_socket =
      case CreateRoom.changeset(room_params) |> CreateRoom.validate() do
        {:ok, %CreateRoom{room_id: room_id}} ->
          push_navigate(socket, to: ~p"/room/#{room_id}")

        {:error, %Ecto.Changeset{valid?: false} = changeset} ->
          assign(socket, form: to_form(changeset, as: "room") |> IO.inspect())
      end

    {:noreply, new_socket}
  end
end
