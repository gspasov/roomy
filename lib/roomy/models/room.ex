defmodule Roomy.Models.Room do
  @moduledoc false

  use Roomy.EctoModel
  use TypedStruct

  alias Roomy.Models.User
  alias Roomy.Models.Message
  alias Roomy.Models.UserRoom
  alias Roomy.Models.Invitation

  require Roomy.Constants.RoomType, as: RoomType

  # require RoomType

  @type t :: %__MODULE__{
          id: pos_integer(),
          name: String.t(),
          type: String.t(),
          invitations: [Invitation.t()],
          users: [User.t()],
          messages: [Message.t()]
        }

  @allowed_fields [:name, :type]

  schema "rooms" do
    field(:name, :string)
    field(:type, :string)

    many_to_many(:users, User, join_through: UserRoom)
    has_many(:messages, Message)
    has_many(:invitations, Invitation)

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

  def find_by_name(name, user_id) do
    like = "%#{name}%"

    user_rooms =
      from(room in __MODULE__,
        join: room_user in assoc(room, :users),
        where: room_user.id == ^user_id
      )

    from(room in subquery(user_rooms),
      join: invitation in assoc(room, :invitations),
      join: invited_user in assoc(invitation, :receiver),
      join: room_user in assoc(room, :users),
      distinct: room.id,
      where:
        (room.type == ^RoomType.dm() and
           (ilike(room_user.username, ^like) or ilike(room_user.display_name, ^like) or
              ilike(invited_user.username, ^like) or ilike(invited_user.display_name, ^like))) or
          (room.type == ^RoomType.group() and ilike(room.name, ^like))
    )
    |> Repo.all()
    |> Repo.preload([:users, invitations: [:receiver, :sender]])
  end
end
