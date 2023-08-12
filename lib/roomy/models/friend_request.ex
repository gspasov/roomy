defmodule Roomy.Models.FriendRequest do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset
  import Ecto.Query

  alias Roomy.Repo
  alias Roomy.Models.User
  alias Roomy.Constants.FriendRequestStatus

  require FriendRequestStatus

  @type t :: %__MODULE__{
          id: pos_integer(),
          message: String.t(),
          status: String.t(),
          sender: User.t(),
          receiver: User.t()
        }

  @required_fields [:sender_id, :receiver_id, :status]
  @fields [:message | @required_fields]

  schema "friend_requests" do
    field(:message, :string)
    field(:status, :string)

    belongs_to(:sender, User)
    belongs_to(:receiver, User)

    timestamps()
  end

  typedstruct module: Create do
    field(:sender_id, pos_integer(), enforce: true)
    field(:receiver_id, pos_integer(), enforce: true)
    field(:message, String.t())
    field(:status, String.t(), default: FriendRequestStatus.pending())
  end

  typedstruct module: Update, enforce: true do
    field(:status, String.t())
  end

  def changeset(%__MODULE__{} = friend_request, %__MODULE__.Create{} = attrs) do
    friend_request
    |> cast(Map.from_struct(attrs), @fields)
    |> validate_required(@required_fields)
  end

  def update_changeset(%__MODULE__{} = friend_request, %__MODULE__.Update{} = attrs) do
    friend_request
    |> cast(Map.from_struct(attrs), [:status])
    |> validate_required([:status])
    |> validate_change(:status, &validate_status_is_accept_or_reject/2)
  end

  def create(%__MODULE__.Create{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end

  def get(id) do
    case Repo.get(__MODULE__, id) do
      nil -> {:error, :not_found}
      entry -> {:ok, entry}
    end
  end

  def update(id, %__MODULE__.Update{} = attrs) do
    Repo.transaction(fn ->
      with {:ok, %__MODULE__{} = friend_request} <- get(id),
           {:ok, %__MODULE__{} = result} <-
             friend_request
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
      FriendRequestStatus.pending() ->
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
