defmodule Roomy.Models.InvitationStatus do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  alias Roomy.Repo

  import Ecto.Changeset

  @allowed_fields [:name]

  @primary_key false
  schema "invitation_statuses" do
    field(:name, :string, primary_key: true)

    timestamps(type: :utc_datetime_usec)
  end

  typedstruct module: New, enforce: true do
    field(:name, String.t())
  end

  def changeset(%__MODULE__{} = invitation_status, %__MODULE__.New{} = attrs) do
    invitation_status
    |> cast(Map.from_struct(attrs), @allowed_fields)
    |> validate_required(@allowed_fields)
  end

  def create(%__MODULE__.New{} = attrs) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Repo.insert()
  end
end
