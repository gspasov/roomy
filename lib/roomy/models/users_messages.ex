defmodule Roomy.Models.UsersMessages do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset

  alias Roomy.Repo
  alias Roomy.Models.User
  alias Roomy.Models.Message

  @fields [:user_id, :message_id]

  schema "users_messages" do
    field(:seen, :boolean)
    belongs_to(:user, User)
    belongs_to(:message, Message)

    timestamps()
  end

  typedstruct module: Create do
    field(:user_id, pos_integer(), enforce: true)
    field(:message_id, pos_integer(), enforce: true)
    field(:seen, boolean())
  end

  def changeset(%__MODULE__{} = user_message, %__MODULE__.Create{} = attrs) do
    user_message
    |> cast(Map.from_struct(attrs), @fields)
    |> validate_required(@fields)
  end

  def create(%__MODULE__.Create{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
