defmodule Roomy.Repo.Migrations.CreateFriendRequestTable do
  use Ecto.Migration

  alias Roomy.Repo
  alias Roomy.Constants.FriendRequestStatus

  require FriendRequestStatus

  def change do
    create table(:friend_request_statuses, primary_key: false) do
      add(:name, :text, primary_key: true, null: false)

      add(:inserted_at, :utc_datetime_usec, default: fragment("NOW()"))
      add(:updated_at, :utc_datetime_usec, default: fragment("NOW()"))
    end

    flush()

    Repo.insert_all(FriendRequestStatus, [
      %FriendRequestStatus.Create{name: FriendRequestStatus.pending()},
      %FriendRequestStatus.Create{name: FriendRequestStatus.rejected()},
      %FriendRequestStatus.Create{name: FriendRequestStatus.accepted()}
    ])

    create table(:friend_requests) do
      add(:message, :text)

      add(:sender_id, references(:users), null: false)
      add(:receiver_id, references(:users), null: false)
      add(:status, references(:friend_request_statuses, type: :text, column: :name), null: false)

      add(:inserted_at, :utc_datetime_usec, default: fragment("NOW()"))
      add(:updated_at, :utc_datetime_usec, default: fragment("NOW()"))
    end

    create table(:users_friends) do
      add(:user1_id, references(:users), null: false)
      add(:user2_id, references(:users), null: false)

      add(:inserted_at, :utc_datetime_usec, default: fragment("NOW()"))
      add(:updated_at, :utc_datetime_usec, default: fragment("NOW()"))
    end

    create index(:users_friends, [:user1_id])
    create index(:users_friends, [:user2_id])

    create unique_index(:users_friends, [:user1_id, :user2_id],
             name: :users_friends_user1_id_user2_id_index
           )

    create unique_index(:users_friends, [:user2_id, :user1_id],
             name: :users_friends_user2_id_user1_id_index
           )
  end
end
