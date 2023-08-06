defmodule Roomy.Models.Room do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset

  alias Roomy.Repo
  alias Roomy.Models.User
  alias Roomy.Models.UsersRooms

  @fields [:name]

  schema "rooms" do
    field(:name, :string)

    many_to_many(:users, User, join_through: UsersRooms)

    timestamps()
  end

  typedstruct module: Create, enforce: true do
    field(:name, String.t())
  end

  def changeset(%__MODULE__{} = room, %__MODULE__.Create{} = attrs) do
    room
    |> cast(Map.from_struct(attrs), @fields)
    |> validate_required(@fields)
  end

  def create(%__MODULE__.Create{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
