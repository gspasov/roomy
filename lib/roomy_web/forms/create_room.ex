defmodule RoomyWeb.Forms.CreateRoom do
  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field :room_id, :string
  end

  def changeset(attrs) do
    %__MODULE__{}
    |> cast(attrs, [:room_id])
    |> validate_required([:room_id])
    |> validate_length(:room_id, is: 11)
  end

  def validate(%Ecto.Changeset{} = changeset) do
    changeset
    |> apply_action(:create)
  end
end
