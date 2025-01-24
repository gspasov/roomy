defmodule RoomyWeb.Components do
  use Phoenix.Component

  alias RoomyWeb.Icon
  alias RoomyWeb.CoreComponents

  attr :id, :string
  attr :title, :string, required: true
  attr :loading, :boolean, default: true
  slot :inner_block, required: true

  def dialog(assigns) do
    ~H"""
    <div
      id={@id}
      class="absolute m-2 flex z-20 rounded-xl bottom-full right-0 bg-purple hidden"
      phx-click-away={CoreComponents.hide("##{@id}")}
    >
      <%= if @loading do %>
        <span class="w-96 h-96 flex items-center justify-center">
          <Icon.loading class="h-10 w-10 animate-spin bg-purple text-slate-200" />
        </span>
      <% else %>
        <h2 class="font-semibold text-3xl text-white px-4 py-2">{@title}</h2>
        <div class="w-96 h-96 mb-0 flex flex-col gap-10 overflow-y-auto">
          {render_slot(@inner_block)}
        </div>
      <% end %>
    </div>
    """
  end

  attr :type, :string, required: true
  attr :click, :string, required: true
  attr :time, :integer, default: nil
  attr :variant, :integer, default: nil
  attr :selected, :boolean, default: false
  slot :inner_block, required: true

  def message_type_button(assigns) do
    ~H"""
    <button
      class={[
        "rounded-full h-10 w-10 text-white text-xs",
        if(@selected, do: "bg-indigo-500", else: "bg-gray-500 hover:bg-indigo-400")
      ]}
      type="button"
      phx-click={@click}
      phx-value-type={@type}
      phx-value-variant={@variant}
      phx-value-milliseconds={@time}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :title, :string, required: true
  attr :message_type, :atom, required: true
  slot :inner_block, required: true

  def message_type_section(assigns) do
    ~H"""
    <div class="flex flex-col gap-1">
      <div class="flex items-center gap-2 text-white">
        <Icon.chat :if={@message_type == :normal} />
        <Icon.clock_history :if={@message_type == :send_after} />
        <Icon.stopwatch :if={@message_type == :destroy_after} />
        <span>{@title}</span>
      </div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :message, :map, required: true
  attr :timezone, :string, required: true
  attr :user_id, :string, required: true
  attr :reply?, :boolean, default: false
  attr :reply_to, :string, default: ""
  attr :replying?, :boolean, default: false
  slot :inner_block, required: true

  def message_bubble(assigns) do
    ~H"""
    <div
      :if={@reply?}
      class={["flex items-center text-xs text-dark", if(@replying?, do: "justify-end")]}
    >
      <Icon.reply_fill />
      <span>
        replied to
        <span class="font-medium">
          {@reply_to}
        </span>
      </span>
    </div>
    <div class={[if(@message.sender_id == @user_id, do: "self-end"), if(@reply?, do: "-mb-4")]}>
      <div class={[
        "max-w-prose min-w-24 w-fit break-words py-4 px-6 rounded-3xl",
        if(@message.sender_id == @user_id,
          do: "rounded-tr-md bg-bubble_2 hover:bg-bubble_2_dark",
          else: "rounded-tl-md bg-bubble_1 hover:bg-bubble_1_dark"
        ),
        if(@reply?, do: "pointer-events-none")
      ]}>
        {render_slot(@inner_block)}
        <div class="flex text-center items-center justify-end text-xs gap-1 text-slate-600 text-right">
          <Icon.stopwatch :if={@message.kind == :destroy_after} />
          <span class="leading-[11px]">
            {@message.sent_at
            |> DateTime.shift_zone!(@timezone)
            |> Calendar.strftime("%H:%M")}
          </span>
        </div>
      </div>
      <div
        :if={not @reply? && length(@message.reactions) > 0}
        class="w-fit rounded-xl px-2 py-1 text-xs text-white font-bold bg-slate-400 -mt-4 ml-4"
      >
        👍️ {length(@message.reactions)}
      </div>
    </div>
    """
  end
end
