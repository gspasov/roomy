defmodule Roomy.Models.Invitation do
  @moduledoc false

  use Roomy.EctoModel, preloads: [:sender, room: [invitations: [:sender, :receiver]]]
  use TypedStruct

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

  def create_changeset(%__MODULE__{} = invitation, attrs) do
    invitation
    |> cast(attrs, @allowed_fields)
    |> put_change(:status, InvitationStatus.pending())
    |> validate_required(@required_fields)
    |> unique_constraint([:sender_id, :receiver_id, :status])
  end

  def update_changeset(%__MODULE__{} = invitation, attrs) do
    invitation
    |> cast(attrs, [:status])
    |> put_change(:seen, true)
    |> validate_required([:status])
    |> validate_inclusion(:status, [InvitationStatus.accepted(), InvitationStatus.rejected()])
  end
end
