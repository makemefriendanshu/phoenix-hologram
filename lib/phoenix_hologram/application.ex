defmodule PhoenixHologram.Application do
  # See https://elixir.hexdocs.pm/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      PhoenixHologramWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:phoenix_hologram, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: PhoenixHologram.PubSub},
      # Start a worker by calling: PhoenixHologram.Worker.start_link(arg)
      # {PhoenixHologram.Worker, arg},
      # Start to serve requests, typically the last entry
      PhoenixHologramWeb.Endpoint
    ]

    # See https://elixir.hexdocs.pm/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: PhoenixHologram.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    PhoenixHologramWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
