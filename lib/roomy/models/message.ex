defmodule Roomy.Models.Message do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset

  alias Roomy.Repo
  alias Roomy.Models.User
  alias Roomy.Models.UsersMessages

  @required_fields [:content, :sent_at, :sender_id, :room_id]
  @fields [:edited, :deleted | @required_fields]

  schema "messages" do
    field(:content, :string)
    field(:sent_at, :utc_datetime_usec)
    field(:sender_id, :integer)
    field(:room_id, :integer)
    field(:edited, :boolean, default: false)
    field(:deleted, :boolean, default: false)

    many_to_many(:users, User, join_through: UsersMessages)

    timestamps()
  end

  typedstruct module: Create do
    field(:content, String.t(), enforce: true)
    field(:sent_at, DateTime.t(), enforce: true)
    field(:sender_id, pos_integer(), enforce: true)
    field(:room_id, pos_integer(), enforce: true)
    field(:edited, boolean())
    field(:deleted, boolean())
  end

  def changeset(%__MODULE__{} = message, %__MODULE__.Create{} = attrs) do
    message
    |> cast(Map.from_struct(attrs), @fields)
    |> validate_required(@fields)
  end

  def create(%__MODULE__.Create{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
