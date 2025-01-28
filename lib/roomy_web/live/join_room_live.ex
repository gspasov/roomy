defmodule RoomyWeb.JoinRoomLive do
  use RoomyWeb, :live_view

  alias RoomyWeb.Forms.CreateRoom

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-my_purple_very_dark h-full flex flex-col items-center justify-center">
      <h1 class="mb-6 text-4xl font-semibold text-center text-white">Joining a Room</h1>
      <div class="flex flex-col bg-white p-8 items-center gap-3 rounded-lg shadow-lg w-full max-w-md">
        <.form :let={f} for={@form} phx-submit="join" class="flex flex-col gap-3">
          <.input
            field={f[:room_id]}
            type="text"
            label="Room ID"
            placeholder="Room ID"
            autofocus
            required
          />
          <.button class="py-2 px-4 rounded-lg shadow-md text-white bg-my_blue hover:bg-my_blue_dark focus:outline-none">
            Next
          </.button>
        </.form>
        <.link navigate={~p"/"} class="underline text-xs text-my_purple hover:text-my_purple_dark">
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
          assign(socket, form: to_form(changeset, as: "room"))
      end

    {:noreply, new_socket}
  end
end
