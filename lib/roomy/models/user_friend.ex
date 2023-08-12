defmodule Roomy.Models.UserFriend do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset

  alias Roomy.Repo
  alias Roomy.Models.User

  @fields [:user1_id, :user2_id]

  schema "users_friends" do
    belongs_to(:user1, User)
    belongs_to(:user2, User)

    timestamps()
  end

  typedstruct module: Create, enforce: true do
    field(:user1_id, pos_integer())
    field(:user2_id, pos_integer())
  end

  def changeset(%__MODULE__.Create{} = attrs) do
    %__MODULE__{}
    |> cast(Map.from_struct(attrs), @fields)
    |> validate_required(@fields)
    |> Ecto.Changeset.unique_constraint(
      [:user1_id, :user2_id],
      name: :users_friends_user1_id_user2_id_index
    )
    |> Ecto.Changeset.unique_constraint(
      [:user2_id, :user1_id],
      name: :users_friends_user2_id_user1_id_index
    )
  end

  def create(%__MODULE__.Create{} = attrs) do
    attrs
    |> changeset()
    |> Repo.insert()
  end
end
