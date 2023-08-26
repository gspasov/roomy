defmodule Roomy.Models.Room do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset

  alias Roomy.Repo
  alias Roomy.Models.User
  alias Roomy.Models.Message
  alias Roomy.Models.UserRoom

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          type: String.t(),
          users: [User.t()],
          messages: [Message.t()]
        }

  @allowed_fields [:name, :type]

  schema "rooms" do
    field(:name, :string)
    field(:type, :string)

    many_to_many(:users, User, join_through: UserRoom)
    has_many(:messages, Message)

    timestamps()
  end

  typedstruct module: New, enforce: true do
    field(:name, String.t())
    field(:type, String.t())
  end

  def changeset(%__MODULE__{} = room, %__MODULE__.New{} = attrs) do
    room
    |> cast(Map.from_struct(attrs), @allowed_fields)
    |> validate_required(@allowed_fields)
  end

  @spec create(__MODULE__.New.t()) ::
          {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t(__MODULE__.t())}
  def create(%__MODULE__.New{} = attrs) do
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
