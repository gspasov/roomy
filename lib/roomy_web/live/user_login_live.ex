defmodule RoomyWeb.UserLoginLive do
  use RoomyWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 mt-20 relative items-center">
      <h1 class="text-white font-bold text-8xl">Let's chat on <br> Roomy</h1>
      <fieldset class="px-12 py-6 mt-20 border rounded border-gray-200 min-w-[25%]">
        <legend class="px-2 text-sm text-center text-nav_text_light font-bold">Log in</legend>
        <.simple_form for={@form} id="login_form" action={~p"/users/log_in"} phx-update="ignore" class="flex flex-col gap-2">
          <.input field={@form[:username]} type="text" label="Username" required autofocus />
          <.input field={@form[:password]} type="password" label="Password" required />
          <:actions>
            <div class="flex justify-around pt-6 text-white">
              <div>
                <span class="text-xl">[</span>
                <button class="text-center px-1 hover:bg-slate-300/25" type="submit">
                  &lt; Sign in &gt;
                </button>
                <span class="text-xl">]</span>
              </div>
            </div>
          </:actions>
        </.simple_form>
      </fieldset>
      <div class="flex gap-5 items-center text-white">
        <span class="italic">Don't have an account yet?</span>
        <div>
          <span>[</span>
          <.link class="text-center px-1 hover:bg-slate-300/25" navigate={~p"/users/register"}>
            &lt; Register &gt;
          </.link>
          <span>]</span>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    username = live_flash(socket.assigns.flash, :username)
    form = to_form(%{"username" => username}, as: "user")
    {:ok, assign(socket, form: form), temporary_assigns: [form: form]}
  end
end
