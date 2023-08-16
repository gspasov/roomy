defmodule Roomy.Models.User do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Changeset

  alias Roomy.Repo
  alias Roomy.Models.Room
  alias Roomy.Models.Message
  alias Roomy.Models.Invitation
  alias Roomy.Models.UserRoom
  alias Roomy.Models.UserMessage
  alias Roomy.Models.UserFriend

  @type t :: %__MODULE__{
          id: pos_integer(),
          username: String.t(),
          display_name: String.t(),
          rooms: [Room.t()],
          messages: [Message.t()],
          friends: [__MODULE__.t()],
          sent_invitations: [Invitation.t()],
          received_invitations: [Invitation.t()]
        }

  @allowed_fields [:username, :display_name, :password]

  schema "users" do
    field(:username, :string)
    field(:display_name, :string)
    field(:password, :string, virtual: true, redact: true)
    field(:hashed_password, :string, redact: true)

    many_to_many(:rooms, Room, join_through: UserRoom)
    many_to_many(:messages, Message, join_through: UserMessage)

    many_to_many(:friends, __MODULE__,
      join_through: UserFriend,
      join_keys: [user1_id: :id, user2_id: :id]
    )

    has_many(:sent_invitations, Invitation, foreign_key: :sender_id)
    has_many(:received_invitations, Invitation, foreign_key: :receiver_id)

    timestamps()
  end

  typedstruct module: Register do
    field :username, String.t(), enforce: true
    field :password, String.t(), enforce: true
    field :display_name, String.t()
  end

  def registration_changeset(%__MODULE__{} = user, %__MODULE__.Register{} = attrs, opts \\ []) do
    user
    |> cast(Map.from_struct(attrs), @allowed_fields)
    |> validate_username(opts)
    |> validate_password(opts)
  end

  def password_changeset(%__MODULE__{} = user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_required([:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  @spec create(__MODULE__.Register.t()) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def create(%__MODULE__.Register{} = attrs) do
    %__MODULE__{}
    |> registration_changeset(attrs)
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

  def delete(%__MODULE__{} = user) do
    Repo.delete(user)
  end

  def valid_password?(
        %__MODULE__{hashed_password: hashed_password},
        password
      )
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end

  defp validate_username(changeset, opts) do
    if Keyword.get(opts, :validate_username, true) do
      changeset
      |> validate_required([:username])
      |> validate_format(:username, ~r/^[A-Za-z0-9._-]+$/,
        message: "The only valid special characters are dots, underscores and hyphens"
      )
      |> validate_length(:username, min: 2, max: 32)
      |> unique_constraint(:username)
    else
      changeset
    end
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 6, max: 72)
    # Examples of additional password validation:
    # |> validate_format(:password, ~r/[a-z]/, message: "at least one lower case character")
    # |> validate_format(:password, ~r/[A-Z]/, message: "at least one upper case character")
    # |> validate_format(:password, ~r/[!?@#$%^&*_0-9]/, message: "at least one digit or punctuation character")
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      # If using Bcrypt, then further validate it is at most 72 bytes long
      |> validate_length(:password, max: 72, count: :bytes)
      # Hashing could be done with `Ecto.Changeset.prepare_changes/2`, but that
      # would keep the database transaction open longer and hurt performance.
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
