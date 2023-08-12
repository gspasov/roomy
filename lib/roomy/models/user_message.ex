defmodule Roomy.Models.UserMessage do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset
  import Ecto.Query

  alias Roomy.Repo
  alias Roomy.Models.User
  alias Roomy.Models.Message

  @required_fields [:user_id, :message_id]
  @fields [:seen | @required_fields]

  schema "users_messages" do
    field(:seen, :boolean)
    belongs_to(:user, User)
    belongs_to(:message, Message)

    timestamps()
  end

  typedstruct module: Multi do
    field(:user_ids, [pos_integer()], enforce: true)
    field(:message_id, pos_integer(), enforce: true)
    field(:seen, boolean())
  end

  typedstruct module: Create do
    field(:user_id, pos_integer(), enforce: true)
    field(:message_id, pos_integer(), enforce: true)
    field(:seen, boolean())
  end

  typedstruct module: Read do
    field(:user_id, pos_integer(), enforce: true)
    field(:message_id, pos_integer(), enforce: true)
  end

  def changeset(%__MODULE__{} = user_message, %__MODULE__.Create{} = attrs) do
    user_message
    |> cast(Map.from_struct(attrs), @fields)
    |> validate_required(@required_fields)
  end

  def create(%__MODULE__.Multi{user_ids: ids, message_id: message_id, seen: seen}) do
    Repo.transaction(fn ->
      Enum.each(ids, fn user_id ->
        %__MODULE__{}
        |> changeset(%__MODULE__.Create{user_id: user_id, message_id: message_id, seen: seen})
        |> Repo.insert()
      end)
    end)
  end

  def read(%__MODULE__.Read{message_id: message_id, user_id: user_id}) do
    with {:ok, %__MODULE__{} = user_message} <- get_by(message_id: message_id, user_id: user_id) do
      user_message
      |> changeset(%__MODULE__.Create{message_id: message_id, user_id: user_id, seen: true})
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

  def all_unread(reader_id, room_id) do
    from(um in __MODULE__,
      join: m in Message,
      on: m.id == um.message_id,
      where: um.user_id == ^reader_id and um.seen == false and m.room_id == ^room_id,
      select: m
    )
    |> Repo.all()
  end
end
