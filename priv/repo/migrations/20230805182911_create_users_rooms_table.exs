defmodule Roomy.Repo.Migrations.CreateUserRoomTable do
  use Ecto.Migration

  def change do
    create table(:users_rooms) do
      add(:user_id, references(:users), null: false)
      add(:room_id, references(:rooms), null: false)

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end
  end
end
