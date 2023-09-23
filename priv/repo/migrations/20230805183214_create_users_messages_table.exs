defmodule Roomy.Repo.Migrations.CreateUserMessageTable do
  use Ecto.Migration

  def change do
    create table(:users_messages) do
      add(:user_id, references(:users), null: false)
      add(:message_id, references(:messages), null: false)
      add(:seen, :boolean, default: false, null: false)

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end
  end
end
