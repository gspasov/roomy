defmodule Roomy.Repo.Migrations.CreateRoomsTable do
  use Ecto.Migration

  def change do
    create table(:rooms) do
      add(:name, :text, null: false)

      add(:inserted_at, :utc_datetime_usec, default: fragment("NOW()"))
      add(:updated_at, :utc_datetime_usec, default: fragment("NOW()"))
    end
  end
end
