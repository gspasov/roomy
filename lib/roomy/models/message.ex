defmodule Roomy.Models.Message do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset
  import Ecto.Query

  alias Roomy.Repo
  alias Roomy.Models.UserMessage

  @type t :: %__MODULE__{
          id: pos_integer(),
          content: String.t(),
          sender_id: pos_integer(),
          room_id: pos_integer(),
          edited: boolean(),
          deleted: boolean(),
          sent_at: DateTime.t(),
          users_messages: [UserMessage.t()]
        }

  @required_fields [:content, :sent_at, :sender_id, :room_id]
  @required_edit_fields [:content, :edited_at, :edited]
  @allowed_fields [:edited, :deleted, :edited_at | @required_fields]

  schema "messages" do
    field(:content, :string)
    field(:sent_at, :utc_datetime_usec)
    field(:sender_id, :integer)
    field(:room_id, :integer)
    field(:edited, :boolean, default: false)
    field(:edited_at, :utc_datetime_usec, default: nil)
    field(:deleted, :boolean, default: false)

    has_many(:users_messages, UserMessage)

    timestamps()
  end

  typedstruct module: New do
    field(:content, String.t(), enforce: true)
    field(:sent_at, DateTime.t(), enforce: true)
    field(:sender_id, pos_integer(), enforce: true)
    field(:room_id, pos_integer(), enforce: true)
    field(:edited, boolean(), default: false)
    field(:deleted, boolean(), default: false)
  end

  typedstruct module: Edit, enforce: true do
    field(:id, pos_integer())
    field(:content, String.t())
    field(:edited_at, DateTime.t())
  end

  typedstruct module: Paginate, enforce: true do
    field(:page, pos_integer())
    field(:page_size, pos_integer())
    field(:room_id, pos_integer())
  end

  def changeset(%__MODULE__{} = message, %__MODULE__.New{} = attrs) do
    message
    |> cast(Map.from_struct(attrs), @allowed_fields)
    |> validate_required(@required_fields)
  end

  def edit_changeset(%__MODULE__{} = message, %__MODULE__.Edit{} = attrs) do
    message
    |> cast(Map.from_struct(attrs), @allowed_fields)
    |> put_change(:edited, true)
    |> validate_required(@required_edit_fields)
  end

  @spec create(__MODULE__.New.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def create(%__MODULE__.New{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  @spec edit(__MODULE__.Edit.t()) :: {:ok, Ecto.Schema.t()} | {:error, Ecto.Changeset.t()}
  def edit(%__MODULE__.Edit{id: id} = attrs) do
    Repo.transaction(fn ->
      with {:ok, %__MODULE__{} = message} <- get(id),
           {:ok, %__MODULE__{} = result} <-
             message
             |> edit_changeset(attrs)
             |> Repo.update() do
        result
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  @spec get(pos_integer(), Keyword.t()) :: {:ok, __MODULE__.t()} | {:error, :not_found}
  def get(id, preloads \\ []) when is_number(id) do
    get_by([id: id], preloads)
  end

  @spec get_by(Keyword.t(), Keyword.t()) :: {:ok, __MODULE__.t()} | {:error, :not_found}
  def get_by(opts, preloads \\ []) do
    __MODULE__
    |> Repo.get_by(opts)
    |> Repo.preload(preloads)
    |> case do
      nil -> {:error, :not_found}
      entry -> {:ok, entry}
    end
  end

  @spec all_unread(pos_integer(), pos_integer()) :: [__MODULE__.t()]
  def all_unread(reader_id, room_id) do
    from(m in __MODULE__,
      join: um in UserMessage,
      on: m.id == um.message_id,
      where: um.user_id == ^reader_id and um.seen == false and m.room_id == ^room_id,
      select: m
    )
    |> Repo.all()
  end

  @spec paginate(__MODULE__.Paginate.t()) :: Scrivener.Page.t()
  def paginate(%__MODULE__.Paginate{page: page, page_size: page_size, room_id: room_id}) do
    from(m in __MODULE__,
      where: m.room_id == ^room_id,
      select: m
    )
    |> Repo.paginate(page: page, page_size: page_size)
  end
end
