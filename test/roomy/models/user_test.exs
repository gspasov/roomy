defmodule Roomy.UserTest do
  use Roomy.DataCase, async: true

  alias Roomy.Account
  alias Roomy.Request
  alias Roomy.Models.User

  test "user can register" do
    {:ok, user} =
      Account.register_user(%Request.RegisterUser{
        username: "example",
        display_name: "Spider man",
        password: "123456"
      })

    assert strip_unnecessary_fields(user) == %{
             username: "example",
             display_name: "Spider man"
           }
  end

  test "user can login" do
    {:ok, %User{} = user} =
      Account.register_user(%Request.RegisterUser{
        username: "example",
        display_name: "Spider man",
        password: "123456"
      })

    {:ok, %User{} = ^user} =
      Account.login_user(%Request.LoginUser{username: "example", password: "123456"})

    assert strip_unnecessary_fields(user) == %{
             username: "example",
             display_name: "Spider man"
           }
  end

  test "user cannot login with false credentials" do
    {:error, reason} =
      Account.login_user(%Request.LoginUser{username: "not_exist", password: "123456"})

    assert reason == :not_found
  end

  test "user password must be at least 6 characters" do
    {:error, %Ecto.Changeset{errors: errors}} =
      Account.register_user(%Request.RegisterUser{
        username: "example",
        display_name: "Spider man",
        password: "12345"
      })

    assert errors == [
             password:
               {"should be at least %{count} character(s)",
                [count: 6, validation: :length, kind: :min, type: :string]}
           ]
  end

  test "cannot register user with forbidden special symbol" do
    {:error, %Ecto.Changeset{errors: errors}} =
      Account.register_user(%Request.RegisterUser{
        username: "example%",
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
    {:error, %Ecto.Changeset{errors: errors_1}} =
      Account.register_user(%Request.RegisterUser{
        username: "e",
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
    {:ok, user} =
      Account.register_user(%Request.RegisterUser{
        username: "example",
        display_name: "Spider man",
        password: "123456"
      })

    assert strip_unnecessary_fields(user) == %{
             username: "example",
             display_name: "Spider man"
           }

    {:error, %Ecto.Changeset{errors: errors}} =
      Account.register_user(%Request.RegisterUser{
        username: "example",
        display_name: "Bat man",
        password: "123456"
      })

    assert errors == [
             username:
               {"has already been taken",
                [constraint: :unique, constraint_name: "users_username_index"]}
           ]
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
