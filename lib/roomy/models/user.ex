defmodule Roomy.Models.User do
  @moduledoc false

  use Ecto.Schema
  use TypedStruct

  import Ecto.Query
  import Ecto.Changeset

  alias Roomy.Repo
  alias Roomy.Models.Room
  alias Roomy.Models.Invitation
  alias Roomy.Models.UserRoom
  alias Roomy.Models.UserFriend
  alias Roomy.Models.UserToken

  @type t :: %__MODULE__{
          id: pos_integer(),
          username: String.t(),
          display_name: String.t(),
          rooms: [Room.t()],
          friends: [__MODULE__.t()],
          invitations: [Invitation.t()],
          tokens: [UserToken.t()],
          inserted_at: DateTime.t(),
          updated_at: DateTime.t()
        }

  @session_validity_in_days 60

  @allowed_fields [:username, :display_name, :password]
  @default_preloads []

  def default_preloads, do: @default_preloads

  schema "users" do
    field(:username, :string)
    field(:display_name, :string)
    field(:password, :string, virtual: true, redact: true)
    field(:hashed_password, :string, redact: true)

    many_to_many(:rooms, Room, join_through: UserRoom)

    many_to_many(:friends, __MODULE__,
      join_through: UserFriend,
      join_keys: [user1_id: :id, user2_id: :id]
    )

    has_many(:invitations, Invitation, foreign_key: :receiver_id)
    has_many(:tokens, UserToken)

    timestamps(type: :utc_datetime_usec)
  end

  typedstruct module: Register do
    field(:username, String.t(), enforce: true)
    field(:password, String.t(), enforce: true)
    field(:display_name, String.t())
  end

  def registration_changeset(%__MODULE__{} = user, attrs, opts \\ []) do
    user
    |> cast(attrs, @allowed_fields)
    |> validate_username(opts)
    |> validate_password(opts)
  end

  def password_changeset(%__MODULE__{} = user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:password])
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_password(opts)
  end

  def username_changeset(%__MODULE__{} = user, attrs, opts \\ []) do
    user
    |> cast(attrs, [:username])
    |> validate_username(opts)
  end

  @spec create(map()) :: {:ok, __MODULE__.t()} | {:error, Ecto.Changeset.t()}
  def create(attrs) do
    %__MODULE__{}
    |> registration_changeset(attrs)
    |> Repo.insert()
  end

  @spec get(pos_integer(), any()) :: {:ok, __MODULE__.t()} | {:error, :not_found}
  def get(id, preloads \\ []) when is_number(id) do
    get_by([id: id], preloads)
  end

  @spec get_by([{atom(), any()}], any()) ::
          {:ok, __MODULE__.t()} | {:error, :not_found}
  def get_by(opts, preloads \\ []) do
    __MODULE__
    |> Repo.get_by(opts)
    |> Repo.preload(preloads)
    |> case do
      nil -> {:error, :not_found}
      entry -> {:ok, entry}
    end
  end

  def get_by_session_token(token) do
    from(user in __MODULE__,
      join: token in ^UserToken.token_and_context_query(token, "session"),
      on: user.id == token.user_id,
      where: token.inserted_at > ago(@session_validity_in_days, "day"),
      preload: ^@default_preloads
    )
    |> Repo.one()
  end

  def find_users_by_name(name) do
    like = "%#{name}%"

    from(user in __MODULE__,
      where:
        ilike(user.username, ^like) or
          ilike(user.display_name, ^like)
    )
    |> Repo.all()
  end

  def delete(%__MODULE__{} = user) do
    Repo.delete(user)
  end

  @spec valid_password?(__MODULE__.t(), String.t()) :: boolean()
  def valid_password?(user, password)

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

  @spec hash_password(String.t()) :: String.t()
  def hash_password(password), do: Bcrypt.hash_pwd_salt(password)

  defp validate_username(changeset, opts) do
    if Keyword.get(opts, :validate_username, true) do
      changeset
      |> validate_required([:username])
      |> validate_format(:username, ~r/^[A-Za-z0-9._-]+$/,
        message: "The only valid special characters are dots, underscores and hyphens"
      )
      |> validate_length(:username, min: 2, max: 32)
      |> unsafe_validate_unique(:username, Repo)
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
      |> put_change(:hashed_password, hash_password(password))
      |> delete_change(:password)
    else
      changeset
    end
  end
end
