defmodule RoomyWeb.Components.AppBar do
  use Phoenix.Component

  use Phoenix.VerifiedRoutes,
    endpoint: RoomyWeb.Endpoint,
    router: RoomyWeb.Router

  alias RoomyWeb.Components.ContextMenu

  attr :user, :map, required: true

  def render(assigns) do
    ~H"""
    <div class="flex w-full items-center justify-between px-2 select-none bg-navigation">
      <ContextMenu.menu id={1} title="Menu">
        <:item title="Chat" href={~p"/"} />
        <:item title="Friends" href={~p"/users/friends"} />
        <:item title="Settings" href={~p"/users/settings"} />
        <:item border={true} />
        <:item title="Logout" href={~p"/users/log_out"} method="delete" />
      </ContextMenu.menu>
      <p class="text-sm text-white font-semibold"><%= @user.display_name %></p>
    </div>
    """
  end
end
