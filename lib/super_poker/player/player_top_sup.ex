defmodule SuperPoker.Player.PlayerTopSup do
  use Supervisor

  require Logger

  def start_link(args) do
    Logger.info("管理具体连接用户代理进程UserSupervisor即将启动...", ansi_color: :blue)
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init(_args) do
    children = [
      # 玩家进程
      {Registry, [keys: :unique, name: SuperPoker.Player.PlayerRegistry]},
      {DynamicSupervisor, [strategy: :one_for_one, name: SuperPoker.Player.PlayerSupervisor]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
