defmodule Roomy.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      pg_spec(),
      RoomyWeb.Telemetry,
      Roomy.Repo,
      {DNSCluster, query: Application.get_env(:roomy, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Roomy.PubSub},
      # Start the Finch HTTP client for sending emails
      {Finch, name: Roomy.Finch},
      # Start a worker by calling: Roomy.Worker.start_link(arg)
      # {Roomy.Worker, arg},
      # Start to serve requests, typically the last entry
      RoomyWeb.Endpoint
    ]

    # Load emojis ets table
    Roomy.Emoji.load_table()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Roomy.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    RoomyWeb.Endpoint.config_change(changed, removed)
    :ok
  end

  defp pg_spec do
    %{
      id: :pg,
      start: {:pg, :start_link, []}
    }
  end
end
