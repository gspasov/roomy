defmodule Roomy.Models.FriendRequestStatus do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  alias Roomy.Repo

  import Ecto.Changeset

  @fields [:name]

  @primary_key false
  schema "friend_request_statuses" do
    field(:name, :string, primary_key: true)

    timestamps()
  end

  typedstruct module: Create, enforce: true do
    field(:name, String.t())
  end

  def changeset(%__MODULE__{} = friend_request_status, %__MODULE__.Create{} = attrs) do
    friend_request_status
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end

  defmacro pending do
    quote do
      "pending"
    end
  end

  defmacro rejected do
    quote do
      "rejected"
    end
  end

  defmacro accepted do
    quote do
      "accepted"
    end
  end

  def create(%__MODULE__.Create{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
