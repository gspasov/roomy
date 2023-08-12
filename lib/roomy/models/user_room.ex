defmodule Roomy.Models.UserRoom do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset

  alias Roomy.Repo
  alias Roomy.Models.User
  alias Roomy.Models.Room

  @fields [:user_id, :room_id]

  schema "users_rooms" do
    belongs_to(:user, User)
    belongs_to(:room, Room)

    timestamps()
  end

  typedstruct module: AddUserToRoom, enforce: true do
    field(:user_id, pos_integer())
    field(:room_id, pos_integer())
  end

  def changeset(%__MODULE__{} = user_room, %__MODULE__.AddUserToRoom{} = attrs) do
    user_room
    |> cast(Map.from_struct(attrs), @fields)
    |> validate_required(@fields)
  end

  def add_user_to_room(%__MODULE__.AddUserToRoom{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
