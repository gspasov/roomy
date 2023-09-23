defmodule Roomy.Models.Message do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset
  import Ecto.Query

  alias Roomy.Repo
  alias Roomy.Models.Room
  alias Roomy.Models.User
  alias Roomy.Models.UserMessage
  alias Roomy.Constants.MessageType

  require MessageType

  @type t :: %__MODULE__{
          id: pos_integer(),
          content: String.t(),
          sender_id: pos_integer(),
          room_id: pos_integer(),
          edited: boolean(),
          deleted: boolean(),
          sent_at: DateTime.t(),
          room: Room.t(),
          sender: User.t(),
          users_messages: [UserMessage.t()]
        }

  @required_fields [:type, :content, :sent_at, :room_id]
  @allowed_fields [:edited, :deleted, :edited_at, :sender_id | @required_fields]

  @required_edit_fields [:content, :edited_at, :edited]
  @allowed_edit_fields [:deleted | @required_edit_fields]

  @required_delete_fields [:content, :deleted]

  schema "messages" do
    field(:type, :string)
    field(:content, :string)
    field(:seen, :boolean, virtual: true)
    field(:sent_at, :utc_datetime_usec)
    field(:edited, :boolean)
    field(:edited_at, :utc_datetime_usec)
    field(:deleted, :boolean)

    has_many(:users_messages, UserMessage)

    belongs_to(:room, Room)
    belongs_to(:sender, User)

    timestamps(type: :utc_datetime_usec)
  end

  typedstruct module: New do
    field(:sender_id, pos_integer())
    field(:content, String.t(), enforce: true)
    field(:sent_at, DateTime.t(), enforce: true)
    field(:room_id, pos_integer(), enforce: true)
    field(:edited, boolean(), default: false)
    field(:deleted, boolean(), default: false)
    field(:type, String.t(), default: MessageType.normal())
  end

  typedstruct module: Edit, enforce: true do
    field(:id, pos_integer())
    field(:content, String.t())
    field(:edited_at, DateTime.t())
  end

  typedstruct module: Paginate, enforce: true do
    field(:page, pos_integer(), default: 1)
    field(:page_size, pos_integer(), default: 20)
    field(:room_id, pos_integer())
  end

  typedstruct module: Where do
    field(:reader_id, pos_integer())
    field(:room_id, pos_integer())
    field(:seen, boolean(), default: false)
    field(:deleted, boolean(), default: false)
  end

  def changeset(%__MODULE__{} = message, %__MODULE__.New{} = attrs) do
    message
    |> cast(Map.from_struct(attrs), @allowed_fields)
    |> validate_required(@required_fields)
  end

  def edit_changeset(%__MODULE__{} = message, %__MODULE__.Edit{} = attrs) do
    message
    |> cast(Map.from_struct(attrs), @allowed_edit_fields)
    |> put_change(:edited, true)
    |> validate_required(@required_edit_fields)
  end

  def delete_changeset(%__MODULE__{} = message) do
    message
    |> cast(%{}, @required_delete_fields)
    |> put_change(:deleted, true)
    |> put_change(:content, "Deleted message")
    |> validate_required(@required_delete_fields)
  end

  @spec create(__MODULE__.New.t()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(%__MODULE__.New{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @spec edit(__MODULE__.Edit.t()) ::
          {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def edit(%__MODULE__.Edit{id: id} = attrs) do
    Repo.tx(fn ->
      with {:ok, %__MODULE__{} = message} <- get(id),
           {:ok, %__MODULE__{}} = result <-
             message
             |> edit_changeset(attrs)
             |> Repo.update() do
        result
      else
        error -> Repo.rollback(error)
      end
    end)
  end

  @spec get(pos_integer(), Keyword.t()) ::
          {:ok, __MODULE__.t()} | {:error, :not_found}
  def get(id, preloads \\ []) when is_number(id) do
    get_by([id: id], preloads)
  end

  @spec get_by(Keyword.t(), Keyword.t()) ::
          {:ok, __MODULE__.t()} | {:error, :not_found}
  def get_by(opts, preloads \\ []) do
    __MODULE__
    |> Repo.get_by(opts)
    |> Repo.preload(preloads)
    |> case do
      nil -> {:error, :not_found}
      entry -> {:ok, entry}
    end
  end

  @spec delete(pos_integer()) ::
          {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t(__MODULE__.t())}
  def delete(id) do
    Repo.tx(fn ->
      with {:ok, %__MODULE__{} = message} <- get(id),
           {:ok, %__MODULE__{}} = result <-
             Repo.update(delete_changeset(message)) do
        result
      else
        error -> Repo.rollback(error)
      end
    end)
  end

  @spec all_unread(__MODULE__.Where.t()) :: [__MODULE__.t()]
  def all_unread(%__MODULE__.Where{} = filters) do
    from(message in __MODULE__,
      as: :message,
      join: user_message in assoc(message, :users_messages),
      as: :user_message,
      where: ^dynamic_where(filters),
      select: message
    )
    |> Repo.all()
  end

  defp dynamic_where(%__MODULE__.Where{} = where_filter) do
    where_filter
    |> Map.from_struct()
    |> Enum.reduce(dynamic(true), fn
      {:room_id, room_id}, dynamic ->
        dynamic([message: message], ^dynamic and message.room_id == ^room_id)

      {:deleted, deleted}, dynamic ->
        dynamic([message: message], ^dynamic and message.deleted == ^deleted)

      {:reader_id, reader_id}, dynamic ->
        dynamic(
          [user_message: user_message],
          ^dynamic and user_message.user_id == ^reader_id
        )

      {:seen, seen}, dynamic ->
        dynamic(
          [user_message: user_message],
          ^dynamic and user_message.seen == ^seen
        )

      _, dynamic ->
        dynamic
    end)
  end

  @spec paginate(__MODULE__.Paginate.t()) :: Scrivener.Page.t()
  def paginate(%__MODULE__.Paginate{
        page: page,
        page_size: page_size,
        room_id: room_id
      }) do
    from(m in __MODULE__,
      where: m.room_id == ^room_id,
      order_by: [desc: m.sent_at],
      select: m,
      preload: [:sender]
    )
    |> Repo.paginate(page: page, page_size: page_size)
  end
end
