defmodule Roomy.Models.InvitationStatus do
  @moduledoc false

  use Roomy.EctoModel
  use TypedStruct

  @type t :: %__MODULE__{
          name: String.t(),
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @allowed_fields [:name]

  @primary_key false
  schema "invitation_statuses" do
    field(:name, :string, primary_key: true)

    timestamps(type: :utc_datetime_usec)
  end

  typedstruct module: New, enforce: true do
    field(:name, String.t())
  end

  def create_changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @allowed_fields)
    |> validate_required(@allowed_fields)
  end

  def update_changeset(%__MODULE__{} = struct, attrs) do
    struct
    |> cast(attrs, @allowed_fields)
  end
end
