defmodule RoomyWeb.UserLoginLive do
  use RoomyWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="flex h-screen w-screen">
      <div class="flex flex-1 items-center justify-end p-10 bg-white">
        <div>
          <h2 class="font-extrabold tracking-tight leading-tight text-gray-800 text-4xl">Sign in</h2>
          <p class="text-sm">
            Don't have an account?
            <.link
              class="cursor-pointer text-indigo-700 hover:underline"
              navigate={~p"/users/register"}
            >
              Sign up
            </.link>
          </p>
          <.simple_form
            for={@form}
            id="login_form"
            action={~p"/users/log_in"}
            phx-update="ignore"
            class="flex flex-col gap-2"
          >
            <div class="flex flex-col gap-3 my-6 w-72">
              <.input field={@form[:username]} type="text" label="Username *" required autofocus />
              <div>
                <.input field={@form[:password]} type="password" label="Password *" required />
                <.link
                  class="text-sm text-indigo-700 cursor-pointer hover:underline"
                  navigate={~p"/users/log_in"}
                >
                  Forgot password?
                </.link>
              </div>
            </div>
            <:actions>
              <button class="text-sm rounded-3xl h-12 text-white font-semibold text-center px-1 bg-indigo-600 hover:bg-indigo-600/[.95] focus:bg-indigo-700">
                Sign in
              </button>
            </:actions>
          </.simple_form>
        </div>
      </div>
      <div class="flex flex-1 flex-col relative">
        <div class="flex h-full w-full items-center bg-indigo-800 p-10 z-10 bg-[url('/images/sign_up.jpg')] bg-blend-overlay bg-no-repeat bg-cover">
          <div class="z-1">
            <h1 class="text-white font-bold text-6xl">Welcome to <br /> Roomy</h1>
            <br />
            <p class="text-slate-300">
              Text your friends and family in one place Join us now to embrace the new world.
            </p>
          </div>
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
