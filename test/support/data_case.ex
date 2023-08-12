defmodule Roomy.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use Roomy.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Roomy.Repo
  alias Roomy.Models.User
  alias Roomy.TestUtils
  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias Roomy.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Roomy.DataCase
    end
  end

  # setup_all tags do
  #   :ok = Ecto.Adapters.SQL.Sandbox.checkout(Roomy.Repo)
  #   Ecto.Adapters.SQL.Sandbox.mode(Roomy.Repo, :auto)

  #   user1 = %User{} = TestUtils.create_user("foo_data_case", "Foo Bar", "123456")
  #   user2 = %User{} = TestUtils.create_user("bar_data_case", "Bar Baz", "123456")

  #   %{user1: user1, user2: user2}
  # end

  setup tags do
    Roomy.DataCase.setup_sandbox(tags)
    :ok

    user1 =
      %User{} =
      TestUtils.create_user("foo_data_case_#{:rand.uniform(1_000)}", "Foo Bar", "123456")

    user2 =
      %User{} =
      TestUtils.create_user("bar_data_case_#{:rand.uniform(1_000)}", "Bar Baz", "123456")

    %{user1: user1, user2: user2}
  end

  @doc """
  Sets up the sandbox based on the test tags.
  """
  def setup_sandbox(tags) do
    pid = Sandbox.start_owner!(Repo, shared: not tags[:async])
    on_exit(fn -> Sandbox.stop_owner(pid) end)
  end

  @doc """
  A helper that transforms changeset errors into a map of messages.

      assert {:error, changeset} = Accounts.create_user(%{password: "short"})
      assert "password is too short" in errors_on(changeset).password
      assert %{password: ["password is too short"]} = errors_on(changeset)

  """
  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
