defmodule RoomyWeb.PageController do
  alias RoomyWeb.Forms.CreateRoom
  use RoomyWeb, :controller

  def index(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false, changeset: CreateRoom.changeset(%{}))
  end
end
