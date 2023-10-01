defmodule Roomy.Models.Invitation do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset
  import Ecto.Query

  alias Roomy.Repo
  alias Roomy.Models.User
  alias Roomy.Models.Room
  alias Roomy.Constants.InvitationStatus

  require InvitationStatus

  @type t :: %__MODULE__{
          id: pos_integer(),
          message: String.t(),
          status: String.t(),
          room_id: pos_integer(),
          sender_id: pos_integer(),
          receiver_id: pos_integer(),
          seen: boolean(),
          room: Room.t(),
          sender: User.t(),
          receiver: User.t()
        }

  @required_fields [:sender_id, :receiver_id, :room_id, :status]
  @allowed_fields [:message, :seen | @required_fields]
  @default_preloads [:sender, :room]

  schema "invitations" do
    field(:message, :string)
    field(:status, :string)
    field(:seen, :boolean)

    belongs_to(:sender, User)
    belongs_to(:receiver, User)
    belongs_to(:room, Room)

    timestamps(type: :utc_datetime_usec)
  end

  typedstruct module: New do
    field(:sender_id, pos_integer(), enforce: true)
    field(:receiver_id, pos_integer(), enforce: true)
    field(:room_id, pos_integer(), enforce: true)
    field(:message, String.t())
    field(:status, String.t(), default: InvitationStatus.pending())
  end

  typedstruct module: Update do
    field(:id, pos_integer(), enforce: true)
    field(:status, String.t(), default: InvitationStatus.pending())
  end

  def changeset(%__MODULE__{} = invitation, %__MODULE__.New{} = attrs) do
    invitation
    |> cast(Map.from_struct(attrs), @allowed_fields)
    |> validate_required(@required_fields)
    |> unique_constraint([:sender_id, :receiver_id, :status])
  end

  def update_changeset(%__MODULE__{} = invitation, %__MODULE__.Update{} = attrs) do
    invitation
    |> cast(Map.from_struct(attrs), [:status])
    |> validate_required([:status])
    |> put_change(:seen, true)
    |> validate_inclusion(:status, [InvitationStatus.accepted(), InvitationStatus.rejected()])
  end

  def create(%__MODULE__.New{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
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

  def all_by(opts, preloads \\ @default_preloads) do
    filters = Keyword.get(opts, :filter, [])
    order_by = Keyword.get(opts, :order_by, [])

    query = from(rows in __MODULE__)
    {new_query, dynamic_where} = dynamic_where_clause(query, filters)

    new_query
    |> where(^dynamic_where)
    |> order_by(^order_by)
    |> preload(^preloads)
    |> Repo.all()
  end

  def update(%__MODULE__.Update{id: id} = attrs, preloads \\ @default_preloads) do
    Repo.tx(fn ->
      with {:ok, %__MODULE__{} = invitation} <- get(id),
           {:ok, %__MODULE__{} = updated_invitation} <-
             invitation
             |> update_changeset(attrs)
             |> Repo.update(),
           %__MODULE__{} = result <- Repo.preload(updated_invitation, preloads) do
        {:ok, result}
      else
        error -> Repo.rollback(error)
      end
    end)
  end

  defp dynamic_where_clause(query, search_terms) do
    Enum.reduce(search_terms, {query, true}, &dynamic_where_clause(&1, &2, nil))
  end

  defp dynamic_where_clause({column, values}, {query, where_clauses}, nil) when is_list(values) do
    if association_field?(column) do
      new_query = join(query, :inner, [table], assoc in assoc(table, ^column), as: ^column)
      Enum.reduce(values, {new_query, where_clauses}, &dynamic_where_clause(&1, &2, column))
    else
      {query, dynamic([table], field(table, ^column) in ^values and ^where_clauses)}
    end
  end

  defp dynamic_where_clause({column, value}, {query, where_clauses}, nil) do
    {query, dynamic([table], field(table, ^column) == ^value and ^where_clauses)}
  end

  defp dynamic_where_clause({column, values}, {query, where_clauses}, association)
       when is_list(values) do
    {query, dynamic([{^association, table}], field(table, ^column) in ^values and ^where_clauses)}
  end

  defp dynamic_where_clause({column, value}, {query, where_clauses}, association) do
    {query, dynamic([{^association, table}], field(table, ^column) == ^value and ^where_clauses)}
  end

  defp association_field?(field) do
    %__MODULE__{}
    |> Map.from_struct()
    |> Map.get(field)
    |> case do
      %Ecto.Association.NotLoaded{__field__: ^field} -> true
      _ -> false
    end
  end
end
