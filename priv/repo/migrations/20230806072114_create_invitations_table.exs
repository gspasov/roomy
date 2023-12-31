defmodule Roomy.Repo.Migrations.CreateInvitationsTable do
  use Ecto.Migration

  alias Roomy.Models.InvitationStatus
  alias Roomy.Constants.InvitationStatus, as: Status

  require Status

  def change do
    create table(:invitation_statuses, primary_key: false) do
      add(:name, :text, primary_key: true, null: false)

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end

    flush()

    [Status.pending(), Status.rejected(), Status.accepted()]
    |> Enum.each(fn status ->
      InvitationStatus.create(%InvitationStatus.New{name: status})
    end)

    create table(:invitations) do
      add(:message, :text)
      add(:seen, :boolean, null: false, default: false)

      add(:sender_id, references(:users), null: false)
      add(:receiver_id, references(:users), null: false)
      add(:room_id, references(:rooms), null: false)
      add(:status, references(:invitation_statuses, type: :text, column: :name), null: false)

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end

    create(
      unique_index(:invitations, [:sender_id, :receiver_id, :status],
        where: "status = '#{Status.pending()}'"
      )
    )

    create table(:users_friends) do
      add(:user1_id, references(:users), null: false)
      add(:user2_id, references(:users), null: false)

      timestamps(type: :utc_datetime_usec, default: fragment("NOW()"))
    end

    create(index(:users_friends, [:user1_id]))
    create(index(:users_friends, [:user2_id]))

    create(
      unique_index(:users_friends, [:user1_id, :user2_id],
        name: :users_friends_user1_id_user2_id_index
      )
    )

    create(
      unique_index(:users_friends, [:user2_id, :user1_id],
        name: :users_friends_user2_id_user1_id_index
      )
    )
  end
end
