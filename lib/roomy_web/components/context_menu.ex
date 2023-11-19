defmodule RoomyWeb.Components.ContextMenu do
  use RoomyWeb, :html

  alias RoomyWeb.Components.Core

  attr(:id, :integer, required: true)
  attr(:title, :string, required: true)

  slot :item do
    attr(:title, :string)
    attr(:href, :string)
    attr(:method, :string)
    attr(:border, :boolean)
  end

  def menu(assigns) do
    ~H"""
    <nav
      class="px-3 relative cursor-pointer text-sm font-bold tracking-wider text-nav_text_light hover:bg-nav_text_dark"
      phx-click={Core.toggle("#context-menu-" <> to_string(@id))}
      phx-click-away={Core.hide_fast("#context-menu-" <> to_string(@id))}
    >
      <span class="text-highlight"><%= String.first(@title) %></span><%= String.slice(@title, 1, 99) %>
      <div
        id={"context-menu-" <> to_string(@id)}
        class="absolute left-0 p-1 w-48 flex hidden bg-navigation z-10"
      >
        <ul class="border-2 py-2 border-nav_text_light">
          <li :for={item <- @item}>
            <.link
              :if={!item[:border]}
              href={item.href}
              method={item[:method] || "get"}
              class="mx-1 block hover:bg-nav_text_dark px-2"
            >
              <%= item.title %>
            </.link>

            <div :if={item[:border]} class="py-2">
              <span class="block border-t-2 border-nav_text-light" />
            </div>
          </li>
        </ul>
      </div>
    </nav>
    """
  end
end
