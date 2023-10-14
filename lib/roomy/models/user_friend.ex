defmodule Roomy.Models.UserFriend do
  @moduledoc false

  use Roomy.EctoModel
  use TypedStruct

  alias Roomy.Models.User

  @type t :: %__MODULE__{
          id: pos_integer(),
          user1: User.t(),
          user1_id: pos_integer(),
          user2: User.t(),
          user2_id: pos_integer(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @allowed_fields [:user1_id, :user2_id]

  schema "users_friends" do
    belongs_to(:user1, User)
    belongs_to(:user2, User)

    timestamps(type: :utc_datetime_usec)
  end

  typedstruct module: New, enforce: true do
    field(:user1_id, pos_integer())
    field(:user2_id, pos_integer())
  end

  def create_changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @allowed_fields)
    |> validate_required(@allowed_fields)
    |> Ecto.Changeset.unique_constraint(
      [:user1_id, :user2_id],
      name: :users_friends_user1_id_user2_id_index
    )
    |> Ecto.Changeset.unique_constraint(
      [:user2_id, :user1_id],
      name: :users_friends_user2_id_user1_id_index
    )
  end

  def update_changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @allowed_fields)
  end
end
