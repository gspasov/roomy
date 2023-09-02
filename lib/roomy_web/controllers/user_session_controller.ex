defmodule RoomyWeb.UserSessionController do
  use RoomyWeb, :controller

  alias Roomy.Account
  alias Roomy.Models.User
  alias RoomyWeb.UserAuth

  def create(conn, %{"_action" => "registered"} = params) do
    create(conn, params, "Account created successfully!")
  end

  def create(conn, %{"_action" => "password_updated"} = params) do
    conn
    |> put_session(:user_return_to, ~p"/users/settings")
    |> create(params, "Password updated successfully!")
  end

  def create(conn, params) do
    create(conn, params, "Welcome back!")
  end

  defp create(
         conn,
         %{"user" => %{"username" => username, "password" => password} = user_params},
         info
       ) do
    case Account.get_user_by_username_and_password(username, password) do
      {:ok, %User{} = user} ->
        conn
        |> put_flash(:info, info)
        |> UserAuth.log_in_user(user, user_params)

      {:error, :not_found} ->
        conn
        |> put_flash(:error, "Invalid username or password")
        |> put_flash(:username, username)
        |> redirect(to: ~p"/users/log_in")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> UserAuth.log_out_user()
  end
end
