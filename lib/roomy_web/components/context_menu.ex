defmodule RoomyWeb.Components.ContextMenu do
  use RoomyWeb, :html

  alias RoomyWeb.Components.Core

  slot :item do
    attr(:title, :string)
    attr(:href, :string)
    attr(:method, :string)
    attr(:border, :boolean)
  end

  def menu(assigns) do
    assigns = Phoenix.Component.assign(assigns, id: System.unique_integer())

    ~H"""
    <nav
      class="relative"
      phx-click={Core.toggle("#context-menu-" <> to_string(@id))}
      phx-click-away={Core.hide_fast("#context-menu-" <> to_string(@id))}
    >
      <%= render_slot(@inner_block) %>
      <div
        id={"context-menu-" <> to_string(@id)}
        class="absolute left-0 block hidden z-10 shadow-xl drop-shadow-xl bg-white rounded py-2"
      >
        <ul>
          <li :for={item <- @item}>
            <div
              :if={!item[:border]}
              class="flex items-center px-5 h-12 w-full gap-4 text-slate-500 cursor-pointer hover:bg-gray-100"
            >
              <%= item.inner_block && render_slot(item) %>
              <.link
                href={item.href}
                method={item[:method] || "get"}
                class="text-sm whitespace-nowrap"
              >
                <%= item.title %>
              </.link>
            </div>

            <div :if={item[:border]} class="py-2">
              <span class="block border-t-2" />
            </div>
          </li>
        </ul>
      </div>
    </nav>
    """
  end
end
