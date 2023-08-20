defmodule Roomy.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    create table(:users) do
      add(:username, :text, null: false)
      add(:display_name, :text, null: false)
      add(:hashed_password, :text, null: false)

      add(:inserted_at, :utc_datetime_usec, default: fragment("NOW()"))
      add(:updated_at, :utc_datetime_usec, default: fragment("NOW()"))
    end

    create unique_index(:users, [:username])
  end
end
