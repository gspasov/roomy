defmodule Roomy.Models.UserToken do
  use Ecto.Schema

  import Ecto.Query

  alias Roomy.Repo
  alias Roomy.Models.User

  require Logger

  @type t :: %__MODULE__{
          id: pos_integer(),
          token: binary(),
          context: String.t(),
          user: User.t(),
          inserted_at: DateTime.t()
        }

  @rand_size 32

  # It is very important to keep the reset password token expiry short,
  # since someone with access to the username may take over the account.
  @session_validity_in_days 60

  schema "user_tokens" do
    field(:token, :binary)
    field(:context, :string)
    belongs_to(:user, User)

    timestamps(updated_at: false)
  end

  @doc """
  Generates a token that will be stored in a signed place,
  such as session or cookie. As they are signed, those
  tokens do not need to be hashed.

  The reason why we store session tokens in the database, even
  though Phoenix already provides a session cookie, is because
  Phoenix' default session cookies are not persisted, they are
  simply signed and potentially encrypted. This means they are
  valid indefinitely, unless you change the signing/encryption
  salt.

  Therefore, storing them allows individual user
  sessions to be expired. The token system can also be extended
  to store additional data, such as the device used for logging in.
  You could then use this information to display all valid sessions
  and devices in the UI and allow users to explicitly expire any
  session they deem invalid.
  """
  def create_session_token(%User{id: user_id}) do
    token = :crypto.strong_rand_bytes(@rand_size)
    Repo.insert!(%__MODULE__{token: token, context: "session", user_id: user_id})
    token
  end

  @doc """
  Checks if the token is valid and returns its underlying lookup query.

  The query returns the user found by the token, if any.

  The token is valid if it matches the value in the database and it has
  not expired (after @session_validity_in_days).
  """
  def get_user_by_session_token(token) do
    from(token in token_and_context_query(token, "session"),
      join: user in assoc(token, :user),
      where: token.inserted_at > ago(@session_validity_in_days, "day"),
      select: user,
      preload: [user: {user, :rooms}]
    )
    # |> Repo.preload(User.default_preloads())
    |> Repo.one()
  end

  @doc """
  Returns the token struct for the given token value and context.
  """
  def token_and_context_query(token, context) do
    from(__MODULE__, where: [token: ^token, context: ^context])
  end

  @doc """
  Gets all tokens for the given user for the given contexts.
  """
  @spec user_and_contexts_query(User.t(), :all | [String.t(), ...]) :: Ecto.Query.t()
  def user_and_contexts_query(%User{id: user_id}, :all) do
    from(t in __MODULE__, where: t.user_id == ^user_id)
  end

  def user_and_contexts_query(%User{id: user_id}, [_ | _] = contexts) do
    from(t in __MODULE__, where: t.user_id == ^user_id and t.context in ^contexts)
  end
end
