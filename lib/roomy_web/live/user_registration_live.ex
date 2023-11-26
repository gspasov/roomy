defmodule RoomyWeb.UserRegistrationLive do
  use RoomyWeb, :live_view

  alias Roomy.Bus
  alias Roomy.Account
  alias Roomy.Models.User

  require Bus.Topic

  def render(assigns) do
    ~H"""
    <div class="flex h-screen w-screen">
      <div class="flex flex-1 items-center justify-end p-10 bg-white">
        <div>
          <h2 class="font-extrabold tracking-tight leading-tight text-gray-800 text-4xl">Sign up</h2>
          <p class="text-sm">
            Already have an account?
            <.link class="cursor-pointer text-indigo-700 hover:underline" navigate={~p"/users/log_in"}>
              Sign in
            </.link>
          </p>
          <.simple_form
            for={@form}
            id="registration_form"
            phx-submit="register"
            phx-change="validate"
            phx-trigger-action={@trigger_submit}
            action={~p"/users/log_in?_action=registered"}
            method="post"
            class="flex flex-col gap-2"
          >
            <div class="flex flex-col gap-3 my-6 w-72">
              <.input
                field={@form[:username]}
                type="text"
                label="Username *"
                debounce={500}
                required
                autofocus
              />
              <.input field={@form[:display_name]} type="text" label="Display Name *" />
              <.input
                field={@form[:password]}
                type="password"
                label="Password *"
                debounce={500}
                required
              />
              <.input
                field={@form[:confirm_password]}
                type="password"
                label="Confirm Password *"
                debounce={500}
                required
              />
            </div>
            <:actions>
              <button class="text-sm rounded-3xl h-12 text-white font-semibold text-center px-1 bg-indigo-600 hover:bg-indigo-600/[.95] focus:bg-indigo-700">
                Create your free account
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
    changeset = Account.change_user_registration(%User{})

    socket =
      socket
      |> assign(trigger_submit: false, check_errors: false)
      |> assign_form(changeset)

    {:ok, socket, temporary_assigns: [form: nil]}
  end

  def handle_event("register", %{"user" => user_params}, socket) do
    case Account.register_user(user_params) do
      {:ok, %User{display_name: name} = user} ->
        changeset = Account.change_user_registration(user)

        Bus.Event.new_user_join(%Bus.Event.UserJoin{display_name: name})

        new_socket = socket |> assign(trigger_submit: true) |> assign_form(changeset)

        {:noreply, new_socket}

      {:error, %Ecto.Changeset{} = changeset} ->
        new_socket = socket |> assign(check_errors: true) |> assign_form(changeset)

        {:noreply, new_socket}
    end
  end

  def handle_event("validate", %{"user" => user_params}, socket) do
    changeset = Account.change_user_registration(%User{}, user_params)
    {:noreply, assign_form(socket, Map.put(changeset, :action, :validate))}
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    form = to_form(changeset, as: "user")

    if changeset.valid? do
      assign(socket, form: form, check_errors: false)
    else
      assign(socket, form: form)
    end
  end
end
