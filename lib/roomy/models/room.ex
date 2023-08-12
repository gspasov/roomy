defmodule Roomy.Models.Room do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset

  alias Roomy.Repo
  alias Roomy.Models.User
  alias Roomy.Models.UserRoom

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          users: [User.t()]
        }

  @fields [:name]

  schema "rooms" do
    field(:name, :string)

    many_to_many(:users, User, join_through: UserRoom)

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

  @spec create(__MODULE__.Create.t()) :: {:ok, Room.t()} | {:error, Ecto.Changeset.t()}
  def create(%__MODULE__.Create{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def get(id, preloads \\ []) when is_number(id) do
    get_by([id: id], preloads)
  end

  def get_by(opts, preloads \\ []) do
    __MODULE__
    |> Repo.get_by(opts)
    |> Repo.preload(preloads)
    |> case do
      nil -> {:error, :not_found}
      entry -> {:ok, entry}
    end
  end
end
