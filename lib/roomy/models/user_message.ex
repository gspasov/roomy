defmodule Roomy.Models.UserMessage do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset
  import Ecto.Query

  alias Roomy.Repo
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
    field(:seen, boolean())
  end

  typedstruct module: New do
    field(:user_id, pos_integer(), enforce: true)
    field(:message_id, pos_integer(), enforce: true)
    field(:seen, boolean())
  end

  typedstruct module: Read do
    field(:user_id, pos_integer(), enforce: true)
    field(:message_id, pos_integer(), enforce: true)
  end

  def changeset(%__MODULE__{} = user_message, %__MODULE__.New{} = attrs) do
    user_message
    |> cast(Map.from_struct(attrs), @allowed_fields)
    |> validate_required(@required_fields)
  end

  def create(%__MODULE__.Multi{user_ids: ids, message_id: message_id, seen: seen}) do
    Repo.tx(fn ->
      Enum.each(ids, fn user_id ->
        %__MODULE__{}
        |> changeset(%__MODULE__.New{user_id: user_id, message_id: message_id, seen: seen})
        |> Repo.insert()
        |> case do
          {:ok, %__MODULE__{}} -> :ok
          {:error, reason} -> Repo.rollback(reason)
        end
      end)
    end)
  end

  def read(%__MODULE__.Read{message_id: message_id, user_id: user_id}) do
    with {:ok, %__MODULE__{} = user_message} <- get_by(message_id: message_id, user_id: user_id) do
      user_message
      |> changeset(%__MODULE__.New{message_id: message_id, user_id: user_id, seen: true})
      |> Repo.update()
    end
  end

  def get(id, preloads \\ []) when is_number(id) do
    get_by([id: id], preloads)
  end

  def get_by(opts, preloads \\ []) do
    __MODULE__
    |> Repo.get_by(opts)
    |> Repo.preload(preloads)
    |> case do
      nil -> {:error, :not_found}
      entry -> {:ok, entry}
    end
  end

  def all(message_id) do
    from(um in __MODULE__,
      join: m in Message,
      on: m.id == um.message_id,
      where: um.message_id == ^message_id,
      select: um
    )
    |> Repo.all()
  end
end
