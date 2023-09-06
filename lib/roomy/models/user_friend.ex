defmodule Roomy.Models.UserFriend do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset

  alias Roomy.Repo
  alias Roomy.Models.User

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

  def changeset(%__MODULE__.New{} = attrs) do
    %__MODULE__{}
    |> cast(Map.from_struct(attrs), @allowed_fields)
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

  def create(%__MODULE__.New{} = attrs) do
    attrs
    |> changeset()
    |> Repo.insert()
  end
end
