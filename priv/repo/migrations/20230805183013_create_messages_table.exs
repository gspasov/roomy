defmodule Roomy.Repo.Migrations.CreateMessagesTable do
  use Ecto.Migration

  alias Roomy.Models.MessageType
  alias Roomy.Constants.MessageType, as: Type

  require Type

  def change do
    create table(:message_types, primary_key: false) do
      add(:name, :text, primary_key: true, null: false)

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end

    flush()

    [Type.normal(), Type.system_group_join(), Type.system_group_leave()]
    |> Enum.each(fn type ->
      MessageType.create(%MessageType.New{name: type})
    end)

    create table(:messages) do
      add(:type, :text, null: false)
      add(:content, :text, null: false)
      add(:sent_at, :utc_datetime_usec, null: false)
      add(:edited_at, :utc_datetime_usec)
      add(:edited, :boolean, null: false)
      add(:deleted, :boolean, null: false)

      add(:sender_id, references(:users))
      add(:room_id, references(:rooms), null: false)

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end
  end
end
