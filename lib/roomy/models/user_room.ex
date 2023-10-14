defmodule Roomy.Models.UserRoom do
  @moduledoc false

  use Roomy.EctoModel
  use TypedStruct

  alias Roomy.Models.User
  alias Roomy.Models.Room

  @type t :: %__MODULE__{
          id: pos_integer(),
          user_id: pos_integer(),
          room_id: pos_integer(),
          user: User.t(),
          room: Room.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @allowed_fields [:user_id, :room_id]

  schema "users_rooms" do
    belongs_to(:user, User)
    belongs_to(:room, Room)

    timestamps(type: :utc_datetime_usec)
  end

  typedstruct module: New, enforce: true do
    field(:user_id, pos_integer())
    field(:room_id, pos_integer())
  end

  def create_changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @allowed_fields)
    |> validate_required(@allowed_fields)
  end

  def update_changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @allowed_fields)
  end

  def add_user_to_room(%__MODULE__.New{} = attrs) do
    create(attrs)
  end
end
