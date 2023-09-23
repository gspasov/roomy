ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(Roomy.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:ex_machina)
