defmodule RoomyWeb.Component.ContextMenu do
  use RoomyWeb, :html

  alias RoomyWeb.Component.Core

  def render(assigns) do
    ~H"""
    <div class="flex w-full px-2 select-none bg-stone-500">
      <.menu id={2} title="Menu">
        <:item title="Settings" href={~p"/"} />
        <:item title="Logout" href={~p"/"} />
      </.menu>
    </div>
    """
  end

  attr(:id, :integer, required: true)
  attr(:title, :string, required: true)

  slot :item, required: true do
    attr(:title, :string, required: true)
    attr(:href, :string, required: true)
  end

  def menu(assigns) do
    ~H"""
    <nav
      class="px-1 relative cursor-pointer hover:bg-stone-400"
      phx-click={Core.toggle("#context-menu-" <> to_string(@id))}
      phx-click-away={Core.hide_fast("#context-menu-" <> to_string(@id))}
    >
      <%= @title %>
      <ul id={"context-menu-" <> to_string(@id)} class="absolute left-0 w-32 flex hidden bg-gray-300">
        <li :for={item <- @item}>
          <.link navigate={item.href} class="w-full block hover:bg-gray-400 px-2">
            <%= item.title %>
          </.link>
        </li>
      </ul>
    </nav>
    """
  end
end
