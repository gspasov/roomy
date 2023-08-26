defmodule RoomyWeb.HomeLive do
  use RoomyWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    chat = [
      %{is_sender: true, content: "Hello there!", timestamp: 1_631_359_800, sender_id: 1},
      %{is_sender: false, content: "Hi!", timestamp: 1_631_359_860, sender_id: 3},
      %{is_sender: true, content: "How are you?", timestamp: 1_631_359_920, sender_id: 1},
      %{is_sender: false, content: "I'm good, thanks!", timestamp: 1_631_359_980, sender_id: 3},
      %{is_sender: true, content: "That's great to hear!", timestamp: 1_631_360_040, sender_id: 1}
    ]

    users = [
      %{id: 1, username: "gspasov", is_online: true, messages: chat},
      %{id: 2, username: "peshoo", is_online: false},
      %{id: 3, username: "hehe", is_online: true}
    ]

    new_socket =
      assign(socket,
        value: :rand.uniform(10),
        users: users,
        selected_user: Enum.at(users, 0),
        current_user: Enum.at(users, 2)
      )

    {:ok, new_socket}
  end

  @impl true
  def render(assigns) do
    assigns =
      assign(assigns,
        shadow:
          "shadow-[rgba(50,_50,_105,_0.15)_0px_2px_5px_0px,_rgba(0,_0,_0,_0.05)_0px_1px_1px_0px]"
      )

    ~H"""
    <div class="flex h-screen gap-2 p-2 bg-neutral-50">
      <!-- Sidebar -->
      <div class={"min-w-18 border rounded-xl border-gray-200 " <> @shadow}>
        <h1 class="p-4 text-2xl font-bold border-b border-gray-400">roomy.fun</h1>

        <div class="flex flex-col gap-2 p-2">
          <form class="flex p-1 mt-2 border border-gray-400 rounded-md focus:outline-none focus:ring focus:border-blue-300">
            <input
              type="text"
              class="h-8 w-full bg-neutral-50 border-none focus:outline-none focus:ring-0"
              placeholder="Find friend..."
            />
          </form>
          <ul>
            <p :if={length(@users) === 0}>No Connected Users :(</p>
            <li :for={user <- @users} key={user.id} class="cursor-pointer rounded-md mb-1 font-bold">
              <div class="flex py-2 px-2 gap-2 items-center rounded-md hover:bg-gray-200">
                <div class="flex items-end">
                  <div class="w-10 h-10 rounded-full bg-gray-500"/>
                  <div :if={user.is_online} class="w-2.5 h-2.5 rounded-full bg-green-700"/>
                  <div :if={not user.is_online} class="w-2.5 h-2.5 rounded-full bg-red-700"/>
                </div>
                <div>
                  <span><%= user.username %></span>
                  <div class="text-sm w-40 text-right font-normal truncate">
                    The last message goes here...
                  </div>
                </div>
              </div>
            </li>
          </ul>
        </div>
      </div>
      <!-- Chat Area -->
      <div class={"flex flex-col w-full border rounded-xl border-gray-200 " <> @shadow}>
        <%= if @selected_user == nil do %>
          <div class="flex items-center justify-center">
            <div class="text-gray-600 text-center">
              <h2 class="text-2xl font-bold mb-4">
                No Conversation selected
              </h2>
              <p class="text-lg">
                Click on a name to start a conversation with your friend!
              </p>
            </div>
          </div>
        <% else %>
          <h1 class="text-2xl p-4 font-bold border-b border-gray-400">
            <%= @selected_user.username %>
          </h1>
          <div class="overflow-y-scroll flex-grow px-2 pt-2">
            <div
              :for={message <- @selected_user.messages}
              class={"flex mb-2 " <> if message.is_sender, do: "justify-end", else: "justify-start"}
            >
              <div class={"rounded-xl px-4 py-2 " <>
                    if message.is_sender, do: "bg-blue-500 text-white", else: "bg-gray-300"
                  }>
                <p><%= message.content %></p>
                <div class={"text-xs " <>
                  if message.is_sender, do: "text-right text-gray-300", else: "text-gray-600"
                }>
                  <%= extract_time(message.timestamp) %>
                </div>
              </div>
            </div>
          </div>
          <form class="flex m-4 mt-2 p-1 gap-2 border border-gray-400 rounded-lg focus:outline-none focus:ring focus:border-blue-300">
            <input
              type="text"
              class="w-full bg-neutral-50 border-none focus:outline-none focus:ring-0"
              placeholder="Type your message..."
            />
            <button
              type="submit"
              class="px-7 text-white font-bold text-sm rounded-lg bg-blue-500 hover:bg-blue-600 focus:outline-none focus:ring focus:border-blue-300"
            >
              Send
            </button>
          </form>
        <% end %>
      </div>
    </div>
    """
  end

  defp extract_time(timestamp) do
    %{hour: hour, minute: minute} = DateTime.from_unix!(timestamp)
    "#{hour}:#{minute}"
  end
end
