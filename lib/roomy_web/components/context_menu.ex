defmodule RoomyWeb.Components.ContextMenu do
  use RoomyWeb, :html

  alias RoomyWeb.Components.Core

  def render(assigns) do
    ~H"""
    <div class="flex w-full px-2 select-none bg-stone-200">
      <.menu id={2} title="Menu">
        <:item title="Settings" href={~p"/users/settings"} method="get" />
        <:item title="Logout" href={~p"/users/log_out"} method="delete" />
      </.menu>
    </div>
    """
  end

  attr(:id, :integer, required: true)
  attr(:title, :string, required: true)

  slot :item, required: true do
    attr(:title, :string, required: true)
    attr(:href, :string, required: true)
    attr(:method, :string)
  end

  def menu(assigns) do
    ~H"""
    <nav
      class="px-1 relative cursor-pointer text-sm font-semibold text-zinc-900 hover:text-zinc-700 hover:bg-stone-400"
      phx-click={Core.toggle("#context-menu-" <> to_string(@id))}
      phx-click-away={Core.hide_fast("#context-menu-" <> to_string(@id))}
    >
      <%= @title %>
      <ul id={"context-menu-" <> to_string(@id)} class="absolute left-0 w-32 flex hidden bg-gray-300">
        <li :for={item <- @item}>
          <.link href={item.href} method={item.method} class="w-full block hover:bg-gray-400 px-2">
            <%= item.title %>
          </.link>
        </li>
      </ul>
    </nav>
    """
  end
end
