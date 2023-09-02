defmodule Roomy.Repo.Migrations.CreateUsersTable do
  use Ecto.Migration

  def change do
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""

    create table(:users) do
      add(:username, :citext, null: false)
      add(:display_name, :text, null: false)
      add(:hashed_password, :string, null: false)

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end

    create(unique_index(:users, [:username]))

    create table(:user_tokens) do
      add(:token, :binary, null: false)
      add(:context, :string, null: false)
      add(:user_id, references(:users, on_delete: :delete_all), null: false)

      timestamps(updated_at: false, type: :utc_datetime_usec, default: fragment("NOW()"))
    end

    create(index(:user_tokens, [:user_id]))
    create(unique_index(:user_tokens, [:context, :token]))
  end
end
