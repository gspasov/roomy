defmodule RoomyWeb.Components.ContextMenu do
  use RoomyWeb, :html

  alias RoomyWeb.Components.Core

  slot :item do
    attr(:title, :string)
    attr(:href, :string)
    attr(:method, :string)
    attr(:border, :boolean)
    attr(:type, :string)
    attr(:click, :string)
  end

  def menu(assigns) do
    assigns =
      Phoenix.Component.assign(assigns, id: "context-menu-" <> to_string(System.unique_integer()))

    ~H"""
    <nav
      class="relative"
      phx-click={Core.toggle("#" <> @id)}
      phx-click-away={Core.hide_fast("#" <> @id)}
    >
      <%= render_slot(@inner_block) %>
      <div id={@id} class="absolute left-0 hidden z-10 shadow-xl drop-shadow-xl bg-white rounded py-2">
        <ul>
          <li :for={item <- @item}>
            <.link
              :if={!item[:border] and item[:type] == "link"}
              href={item.href}
              method={item[:method] || "get"}
              class="flex items-center px-5 h-12 w-full gap-4 text-slate-500 cursor-pointer hover:bg-gray-100"
            >
              <%= item.inner_block && render_slot(item) %>
              <span class="text-sm"><%= item.title %></span>
            </.link>
            <button
              :if={!item[:border] and item[:type] == "button"}
              phx-click={item[:click]}
              value={@id}
              class="flex items-center px-5 h-12 w-full gap-4 text-slate-500 cursor-pointer hover:bg-gray-100"
            >
              <%= item.inner_block && render_slot(item) %>
              <span class="text-sm whitespace-nowrap"><%= item.title %></span>
            </button>

            <div :if={item[:border]} class="py-2">
              <span class="block border-t" />
            </div>
          </li>
        </ul>
      </div>
    </nav>
    """
  end
end
