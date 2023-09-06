defmodule Roomy.RoomCase do
  @moduledoc false

  use ExUnit.CaseTemplate

  alias Roomy.Repo
  alias Roomy.Account
  alias Roomy.TestUtils
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Models.Invitation
  alias Roomy.Constants.RoomType
  alias Ecto.Adapters.SQL.Sandbox

  require RoomType

  using do
    quote do
      alias Roomy.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import Roomy.DataCase
    end
  end

  setup tags do
    Roomy.DataCase.setup_sandbox(tags)

    user1 = %User{} = TestUtils.create_user("foo_room_case", "Foo Bar", "123456")
    user2 = %User{} = TestUtils.create_user("bar_room_case", "Bar Baz", "123456")

    %Invitation{id: invitation_id} =
      TestUtils.send_friend_request(
        user1.id,
        user2.username,
        "It's a me, Mario!"
      )

    {:ok, %Invitation{}} = Account.answer_invitation(invitation_id, true)

    {:ok, %Room{} = room} = Room.get_by(name: Account.build_room_name(user1.id, user2.id))

    %{user1: user1, user2: user2, room: room}
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
