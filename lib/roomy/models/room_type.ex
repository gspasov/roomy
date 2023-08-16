defmodule Roomy.Models.RoomType do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  alias Roomy.Repo

  import Ecto.Changeset

  @fields [:name]

  @primary_key false
  schema "room_types" do
    field(:name, :string, primary_key: true)

    timestamps()
  end

  typedstruct module: New, enforce: true do
    field(:name, String.t())
  end

  def changeset(%__MODULE__{} = room_type, %__MODULE__.New{} = attrs) do
    room_type
    |> cast(Map.from_struct(attrs), @fields)
    |> validate_required(@fields)
  end

  def create(%__MODULE__.New{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
