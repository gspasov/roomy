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
          room: Room.t(),
          sender: User.t(),
          receiver: User.t()
        }

  @required_fields [:sender_id, :receiver_id, :room_id, :status]
  @fields [:message | @required_fields]

  schema "invitations" do
    field(:message, :string)
    field(:status, :string)

    belongs_to(:sender, User)
    belongs_to(:receiver, User)
    belongs_to(:room, Room)

    timestamps()
  end

  typedstruct module: Create do
    field(:sender_id, pos_integer(), enforce: true)
    field(:receiver_id, pos_integer(), enforce: true)
    field(:room_id, pos_integer(), enforce: true)
    field(:message, String.t())
    field(:status, String.t(), default: InvitationStatus.pending())
  end

  typedstruct module: Update, enforce: true do
    field(:id, pos_integer())
    field(:status, String.t())
  end

  def changeset(%__MODULE__{} = invitation, %__MODULE__.Create{} = attrs) do
    invitation
    |> cast(Map.from_struct(attrs), @fields)
    |> validate_required(@required_fields)
  end

  def update_changeset(%__MODULE__{} = invitation, %__MODULE__.Update{} = attrs) do
    invitation
    |> cast(Map.from_struct(attrs), [:status])
    |> validate_required([:status])
    |> validate_change(:status, &validate_status_is_accept_or_reject/2)
  end

  def create(%__MODULE__.Create{} = attrs) do
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

  def update(%__MODULE__.Update{id: id} = attrs) do
    Repo.transaction(fn ->
      with {:ok, %__MODULE__{} = invitation} <- get(id),
           {:ok, %__MODULE__{} = result} <-
             invitation
             |> update_changeset(attrs)
             |> Repo.update() do
        result
      else
        {:error, reason} -> Repo.rollback(reason)
      end
    end)
  end

  def all(id) do
    from(m in __MODULE__, where: m.receiver_id == ^id)
    |> Repo.all()
  end

  defp validate_status_is_accept_or_reject(:status, status) do
    case status do
      InvitationStatus.pending() ->
        [
          status:
            {"cannot_be_pending",
             error: "Status can only be changed to 'accepted' or 'rejected'."}
        ]

      _ ->
        []
    end
  end
end
