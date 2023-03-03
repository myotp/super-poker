defmodule SuperPoker.Multiplayer.MultiplayerSup do
  use Supervisor

  require Logger

  def start_link(args) do
    Logger.info("多人游戏服务器核心部分总supervisor启动...")
    Logger.info("args: #{inspect(args)}")

    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init(_args) do
    children = []
    Supervisor.init(children, strategy: :one_for_one)
  end
end
