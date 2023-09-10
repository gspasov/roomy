defmodule RoomyWeb.UserRegistrationLive do
  use RoomyWeb, :live_view

  alias Roomy.Bus
  alias Roomy.Account
  alias Roomy.Models.User

  require Bus.Topic

  def render(assigns) do
    ~H"""
    <div class="flex flex-col gap-2 mt-20 relative items-center">
      <h1 class="text-white font-bold text-8xl">Welcome to <br> Roomy</h1>
      <fieldset class="px-12 py-6 mt-20 border rounded border-gray-200 min-w-[25%]">
        <legend class="px-2 text-sm text-center text-nav_text_light font-bold">Sign up</legend>
        <.simple_form
          for={@form}
          id="registration_form"
          phx-submit="register"
          phx-change="validate"
          phx-trigger-action={@trigger_submit}
          action={~p"/users/log_in?_action=registered"}
          method="post"
          class="flex flex-col gap-2">
          <.error :if={@check_errors}>
            Oops, something went wrong! Please check the errors below.
          </.error>

          <.input field={@form[:username]} type="text" label="Username" required />
          <.input field={@form[:display_name]} type="text" label="Display Name" />
          <.input field={@form[:password]} type="password" label="Password" required />

          <:actions>
            <div class="flex justify-center pt-6">
              <div class="text-white">
                <span class="text-xl">[</span>
                <button class="text-center px-1 hover:bg-slate-300/25" type="submit" phx-disable-with="Creating account...">
                  &lt; Create an account &gt;
                </button>
                <span class="text-xl">]</span>
              </div>
            </div>
          </:actions>
        </.simple_form>
      </fieldset>
      <div class="flex gap-5 items-center text-white">
        <span class="italic">Already have an account?</span>
        <div>
          <span>[</span>
          <.link class="text-center px-1 hover:bg-slate-300/25" navigate={~p"/users/log_in"}>
            &lt; Log in &gt;
          </.link>
          <span>]</span>
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
