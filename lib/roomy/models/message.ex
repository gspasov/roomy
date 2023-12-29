defmodule Roomy.Models.Message do
  @moduledoc false

  use Roomy.EctoModel
  use TypedStruct

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
  end

  def create_changeset(%__MODULE__{} = message, attrs) do
    message
    |> cast(attrs, @allowed_fields)
    |> validate_required(@required_fields)
  end

  def update_changeset(%__MODULE__{} = message, attrs) do
    message
    |> cast(attrs, @allowed_edit_fields)
    |> put_change(:edited, true)
    |> validate_required(@required_edit_fields)
  end

  def delete_changeset(%__MODULE__{} = message) do
    message
    |> cast(%{}, @required_delete_fields)
    |> put_change(:deleted, true)
    |> put_change(:content, "[system] Deleted message")
    |> validate_required(@required_delete_fields)
  end

  @spec mark_deleted(pos_integer()) ::
          {:ok, Roomy.Models.Message.t()} | {:error, :not_found | Ecto.Changeset.t()}
  def mark_deleted(id) when is_integer(id) do
    with {:ok, %__MODULE__{} = message} <- get(id),
         {:ok, %__MODULE__{}} = result <- update(delete_changeset(message)) do
      result
    end
  end

  @spec all_unread(__MODULE__.Where.t()) :: [__MODULE__.t()]
  def all_unread(
        %__MODULE__.Where{room_id: room_id, reader_id: reader_id, seen: seen},
        preloads \\ @default_preloads
      ) do
    all_by(
      filter: [room_id: room_id, users_messages: [seen: seen, user_id: reader_id]],
      preloads: preloads
    )
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
      preload: [:sender]
    )
    |> Repo.paginate(page: page, page_size: page_size)
  end
end
