defmodule RoomyWeb.UserSettingsLive do
  use RoomyWeb, :live_view

  alias Roomy.Account
  alias Roomy.Models.User

  def render(assigns) do
    ~H"""
    <.header class="text-center">
      Account Settings
      <:subtitle>Manage your account username and password settings</:subtitle>
    </.header>

    <div class="space-y-12 divide-y">
      <div>
        <.simple_form
          for={@username_form}
          id="username_form"
          phx-submit="update_username"
          phx-change="validate_username"
        >
          <.input field={@username_form[:username]} type="text" label="Username" required />
          <.input
            field={@username_form[:current_password]}
            name="current_password"
            id="current_password_for_username"
            type="password"
            label="Current password"
            value={@username_form_current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Username</.button>
          </:actions>
        </.simple_form>
      </div>
      <div>
        <.simple_form
          for={@password_form}
          id="password_form"
          action={~p"/users/log_in?_action=password_updated"}
          method="post"
          phx-change="validate_password"
          phx-submit="update_password"
          phx-trigger-action={@trigger_submit}
        >
          <.input
            field={@password_form[:username]}
            type="hidden"
            id="hidden_user_username"
            value={@current_username}
          />
          <.input field={@password_form[:password]} type="password" label="New password" required />
          <.input
            field={@password_form[:password_confirmation]}
            type="password"
            label="Confirm new password"
          />
          <.input
            field={@password_form[:current_password]}
            name="current_password"
            type="password"
            label="Current password"
            id="current_password_for_password"
            value={@current_password}
            required
          />
          <:actions>
            <.button phx-disable-with="Changing...">Change Password</.button>
          </:actions>
        </.simple_form>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    user = socket.assigns.current_user
    username_changeset = Account.change_user_username(user)
    password_changeset = Account.change_user_password(user)

    socket =
      socket
      |> assign(:current_password, nil)
      |> assign(:username_form_current_password, nil)
      |> assign(:current_username, user.username)
      |> assign(:username_form, to_form(username_changeset))
      |> assign(:password_form, to_form(password_changeset))
      |> assign(:trigger_submit, false)

    {:ok, socket}
  end

  def handle_event(
        "validate_username",
        %{"current_password" => password, "user" => user_params},
        %{assigns: %{current_user: %User{} = user}} = socket
      ) do
    username_form =
      user
      |> Account.change_user_username(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    new_socket =
      assign(socket,
        username_form: username_form,
        username_form_current_password: password
      )

    {:noreply, new_socket}
  end

  def handle_event(
        "update_username",
        %{"current_password" => password, "user" => user_params},
        %{assigns: %{current_user: %User{} = user}} = socket
      ) do
    case Account.update_user_username(user, password, user_params) do
      {:ok, %User{}} ->
        {:noreply, assign(socket, username_form_current_password: nil)}

      {:error, changeset} ->
        {:noreply, assign(socket, username_form: to_form(changeset))}
    end
  end

  def handle_event(
        "validate_password",
        %{"current_password" => password, "user" => user_params},
        %{assigns: %{current_user: %User{} = user}} = socket
      ) do
    password_form =
      user
      |> Account.change_user_password(user_params)
      |> Map.put(:action, :validate)
      |> to_form()

    {:noreply, assign(socket, password_form: password_form, current_password: password)}
  end

  def handle_event(
        "update_password",
        %{"current_password" => password, "user" => user_params},
        %{assigns: %{current_user: %User{} = user}} = socket
      ) do
    case Account.update_user_password(user, password, user_params) do
      {:ok, user} ->
        password_form =
          user
          |> Account.change_user_password(user_params)
          |> to_form()

        {:noreply, assign(socket, trigger_submit: true, password_form: password_form)}

      {:error, changeset} ->
        {:noreply, assign(socket, password_form: to_form(changeset))}
    end
  end
end
