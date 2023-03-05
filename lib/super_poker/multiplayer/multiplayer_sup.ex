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
    children = [
      # 读取所有牌桌静态信息，包括大小盲数量，最大玩家数
      SuperPoker.Multiplayer.TableLoader,

      # 具体牌桌进程的DynamicSupervisor
      SuperPoker.Multiplayer.TableSup,

      # 牌桌ID注册registry
      {Registry, [keys: :unique, name: SuperPoker.Multiplayer.TableRegistry]},

      # 实际触发DynamicSupervisor启动具体牌桌的进程
      SuperPoker.Multiplayer.TableStarter,

      # 玩家进程
      {Registry, [keys: :unique, name: SuperPoker.Multiplayer.PlayerRegistry]},
      SuperPoker.Multiplayer.PlayerSup
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
