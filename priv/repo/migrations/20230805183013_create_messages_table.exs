defmodule Roomy.Repo.Migrations.CreateMessagesTable do
  use Ecto.Migration

  def change do
    create table(:messages) do
      add(:content, :text, null: false)
      add(:sent_at, :utc_datetime_usec, null: false)
      add(:edited, :boolean)
      add(:deleted, :boolean)

      add(:sender_id, references(:users), null: false)
      add(:room_id, references(:rooms), null: false)

      add(:inserted_at, :utc_datetime_usec, default: fragment("NOW()"))
      add(:updated_at, :utc_datetime_usec, default: fragment("NOW()"))
    end
  end
end
