defmodule Roomy.UserTest do
  use Roomy.DataCase, async: true

  alias Roomy.Account
  alias Roomy.Request
  alias Roomy.Models.User

  test "user can register" do
    username = create_username()

    {:ok, user} =
      Account.register_user(%Request.RegisterUser{
        username: username,
        display_name: "Spider man",
        password: "123456"
      })

    assert strip_unnecessary_fields(user) == %{
             username: username,
             display_name: "Spider man"
           }
  end

  test "user can login" do
    username = create_username()

    {:ok, %User{} = user} =
      Account.register_user(%Request.RegisterUser{
        username: username,
        display_name: "Spider man",
        password: "123456"
      })

    {:ok, %User{} = ^user} =
      Account.login_user(%Request.LoginUser{username: username, password: "123456"})

    assert strip_unnecessary_fields(user) == %{
             username: username,
             display_name: "Spider man"
           }
  end

  test "user cannot login with false credentials" do
    non_existing_username = "not_exist"

    {:error, reason} =
      Account.login_user(%Request.LoginUser{
        username: non_existing_username,
        password: "123456"
      })

    assert reason == :not_found
  end

  test "user password must be at least 6 characters" do
    too_short_password = "12345"

    {:error, %Ecto.Changeset{errors: errors}} =
      Account.register_user(%Request.RegisterUser{
        username: "example3",
        display_name: "Spider man",
        password: too_short_password
      })

    assert errors == [
             password:
               {"should be at least %{count} character(s)",
                [count: 6, validation: :length, kind: :min, type: :string]}
           ]
  end

  test "cannot register user with forbidden special symbol in username" do
    username_with_invalid_character = "example%"

    {:error, %Ecto.Changeset{errors: errors}} =
      Account.register_user(%Request.RegisterUser{
        username: username_with_invalid_character,
        display_name: "Spider man",
        password: "123456"
      })

    assert errors == [
             username: {
               "The only valid special characters are dots, underscores and hyphens",
               [validation: :format]
             }
           ]
  end

  test "cannot register user with bad username length" do
    too_short_username = "e"

    {:error, %Ecto.Changeset{errors: errors_1}} =
      Account.register_user(%Request.RegisterUser{
        username: too_short_username,
        display_name: "Spider man",
        password: "123456"
      })

    assert errors_1 == [
             username: {
               "should be at least %{count} character(s)",
               [
                 {:count, 2},
                 {:validation, :length},
                 {:kind, :min},
                 {:type, :string}
               ]
             }
           ]

    {:error, %Ecto.Changeset{errors: errors_2}} =
      Account.register_user(%Request.RegisterUser{
        username: Enum.reduce(1..33, "", fn _, acc -> acc <> "a" end),
        display_name: "Spider man",
        password: "123456"
      })

    assert errors_2 == [
             username: {
               "should be at most %{count} character(s)",
               [
                 {:count, 32},
                 {:validation, :length},
                 {:kind, :max},
                 {:type, :string}
               ]
             }
           ]
  end

  test "cannot have two users with the same username" do
    username = create_username()

    {:ok, user} =
      Account.register_user(%Request.RegisterUser{
        username: username,
        display_name: "Spider man",
        password: "123456"
      })

    assert strip_unnecessary_fields(user) == %{
             username: username,
             display_name: "Spider man"
           }

    {:error, %Ecto.Changeset{errors: errors}} =
      Account.register_user(%Request.RegisterUser{
        username: username,
        display_name: "Bat man",
        password: "123456"
      })

    assert errors == [
             username:
               {"has already been taken",
                [constraint: :unique, constraint_name: "users_username_index"]}
           ]
  end

  defp create_username() do
    "example#{:random.uniform(1_000_000_000)}"
  end

  defp strip_unnecessary_fields(user) do
    user
    |> Map.from_struct()
    |> Map.delete(:__meta__)
    |> Map.delete(:id)
    |> Map.delete(:hashed_password)
    |> Map.delete(:rooms)
    |> Map.delete(:password)
    |> Map.delete(:messages)
    |> Map.delete(:sent_invitations)
    |> Map.delete(:received_invitations)
    |> Map.delete(:friends)
    |> Map.delete(:inserted_at)
    |> Map.delete(:updated_at)
  end
end
