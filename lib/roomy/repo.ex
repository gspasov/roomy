defmodule Roomy.Repo do
  use Ecto.Repo,
    otp_app: :roomy,
    adapter: Ecto.Adapters.Postgres

  use Scrivener, page_size: 10
end
