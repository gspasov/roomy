defmodule Roomy.Repo do
  use Ecto.Repo,
    otp_app: :roomy,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10

  @doc """
  Designed as a replacement for the `Repo.transaction/2` function.
  So that we don't have to worry about it wrapping the `success case` with an `:ok` tuple
  or the `error case` with an `:error` tuple
  """
  @spec tx((... -> response)) :: response when response: {:ok, any()} | {:error, any()}
  def tx(f) when is_function(f) do
    case __MODULE__.transaction(f) do
      {:ok, data} -> data
      {:error, error} -> error
    end
  end
end
