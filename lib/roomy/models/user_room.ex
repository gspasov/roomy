defmodule Roomy.Models.UserRoom do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset

  alias Roomy.Repo
  alias Roomy.Models.User
  alias Roomy.Models.Room

  @allowed_fields [:user_id, :room_id]

  schema "users_rooms" do
    belongs_to(:user, User)
    belongs_to(:room, Room)

    timestamps()
  end

  typedstruct module: New, enforce: true do
    field(:user_id, pos_integer())
    field(:room_id, pos_integer())
  end

  def changeset(%__MODULE__{} = user_room, %__MODULE__.New{} = attrs) do
    user_room
    |> cast(Map.from_struct(attrs), @allowed_fields)
    |> validate_required(@allowed_fields)
  end

  def add_user_to_room(%__MODULE__.New{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def get(user_id, room_id) do
    __MODULE__
    |> Repo.get_by(user_id: user_id, room_id: room_id)
    |> case do
      %__MODULE__{} = entry -> {:ok, entry}
      nil -> {:error, :not_found}
    end
  end

  def delete(%__MODULE__.New{user_id: user_id, room_id: room_id}) do
    with {:ok, %__MODULE__{} = user_room} <- get(user_id, room_id) do
      Repo.delete(user_room)
    end
  end
end
