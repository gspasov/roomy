defmodule Roomy.Models.Room do
  @moduledoc false

  use Roomy.EctoModel
  use TypedStruct

  alias Roomy.Models.User
  alias Roomy.Models.Message
  alias Roomy.Models.UserRoom
  alias Roomy.Models.Invitation

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          type: String.t(),
          invitation: Invitation.t() | nil,
          users: [User.t()],
          messages: [Message.t()]
        }

  @allowed_fields [:name, :type]

  schema "rooms" do
    field(:name, :string)
    field(:type, :string)

    many_to_many(:users, User, join_through: UserRoom)
    has_many(:messages, Message)
    has_one(:invitation, Invitation)

    timestamps(type: :utc_datetime_usec)
  end

  typedstruct module: New, enforce: true do
    field(:name, String.t())
    field(:type, String.t())
  end

  def create_changeset(%__MODULE__{} = room, attrs) do
    room
    |> cast(attrs, @allowed_fields)
    |> validate_required(@allowed_fields)
  end

  def update_changeset(%__MODULE__{} = room, attrs) do
    room
    |> cast(attrs, @allowed_fields)
  end
end
