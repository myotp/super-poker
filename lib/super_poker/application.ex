defmodule SuperPoker.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Telemetry supervisor
      SuperPokerWeb.Telemetry,
      # Start the Ecto repository
      SuperPoker.Repo,
      # Start the PubSub system
      {Phoenix.PubSub, name: SuperPoker.PubSub},
      # Start the Endpoint (http/https)
      SuperPokerWeb.Endpoint,
      # Start a worker by calling: SuperPoker.Worker.start_link(arg)
      # {SuperPoker.Worker, arg}

      # 牌桌控制部分
      SuperPoker.GameServer.GameServerTopSup,
      # 玩家控制部分
      SuperPoker.Player.PlayerTopSup
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: SuperPoker.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    SuperPokerWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
