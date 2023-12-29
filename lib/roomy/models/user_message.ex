defmodule Roomy.Models.UserMessage do
  @moduledoc false

  use Roomy.EctoModel
  use TypedStruct

  alias Roomy.Models.User
  alias Roomy.Models.Message

  @type t :: %__MODULE__{
          id: pos_integer(),
          seen: boolean(),
          user_id: pos_integer(),
          message_id: pos_integer(),
          user: User.t(),
          message: Message.t()
        }

  @required_fields [:user_id, :message_id]
  @allowed_fields [:seen | @required_fields]

  schema "users_messages" do
    field(:seen, :boolean)
    belongs_to(:user, User)
    belongs_to(:message, Message)

    timestamps(type: :utc_datetime_usec)
  end

  typedstruct module: Multi do
    field(:user_ids, [pos_integer()], enforce: true)
    field(:message_id, pos_integer(), enforce: true)
    field(:seen, boolean(), default: false)
  end

  typedstruct module: New do
    field(:user_id, pos_integer(), enforce: true)
    field(:message_id, pos_integer(), enforce: true)
    field(:seen, boolean(), default: false)
  end

  typedstruct module: Read do
    field(:user_id, pos_integer(), enforce: true)
    field(:message_id, pos_integer(), enforce: true)
  end

  def create_changeset(%__MODULE__{} = struct, attrs \\ %{}) do
    struct
    |> cast(attrs, @allowed_fields)
    |> validate_required(@required_fields)
  end

  def update_changeset(%__MODULE__{} = struct, attrs \\ %{}) do
    struct
    |> cast(attrs, @allowed_fields)
    |> put_change(:seen, true)
  end

  def multiple(%__MODULE__.Multi{user_ids: ids, message_id: message_id, seen: seen}) do
    __MODULE__
    |> Repo.insert_all(
      Enum.map(ids, fn id -> %{user_id: id, message_id: message_id, seen: seen} end)
    )
    |> case do
      {inserts, nil} when inserts == length(ids) -> :ok
      _ -> {:error, :failed_to_insert_users_messages}
    end
  end

  def read(%__MODULE__.Read{message_id: message_id, user_id: user_id}) do
    with {:ok, %__MODULE__{} = user_message} <- get_by(message_id: message_id, user_id: user_id) do
      user_message
      |> update_changeset()
      |> update()
    end
  end

  def get_all_unread(user_id, room_id) do
    from(um in __MODULE__,
      join: m in assoc(um, :message),
      where:
        um.user_id == ^user_id and
          m.room_id == ^room_id and
          um.seen == false
    )
  end
end
