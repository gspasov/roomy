defmodule Roomy.Repo.Migrations.CreateRoomsTable do
  use Ecto.Migration

  alias Roomy.Models.RoomType
  alias Roomy.Constants.RoomType, as: Type

  require Type

  def change do
    create table(:room_types, primary_key: false) do
      add(:name, :text, primary_key: true, null: false)

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end

    flush()

    [Type.dm(), Type.group()]
    |> Enum.each(fn type ->
      RoomType.create(%RoomType.New{name: type})
    end)

    create table(:rooms) do
      add(:name, :text, null: false)
      add(:type, :text, null: false)

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end
  end
end
