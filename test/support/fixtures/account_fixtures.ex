defmodule Roomy.AccountFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `Roomy.Account` context.
  """

  def unique_user_username do
    unique_id = System.unique_integer() |> to_string() |> String.slice(-10..-1)
    "user_" <> unique_id
  end

  def valid_user_password, do: "hello world!"

  def valid_user_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      username: unique_user_username(),
      password: valid_user_password(),
      display_name: "User User"
    })
  end

  def user_fixture(attrs \\ %{}) do
    {:ok, user} =
      attrs
      |> valid_user_attributes()
      |> Roomy.Account.register_user()

    user
  end

  def extract_user_token(fun) do
    {:ok, captured_username} = fun.(&"[TOKEN]#{&1}[TOKEN]")
    [_, token | _] = String.split(captured_username.text_body, "[TOKEN]")
    token
  end
end
