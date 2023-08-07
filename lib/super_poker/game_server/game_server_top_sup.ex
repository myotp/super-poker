defmodule SuperPoker.GameServer.GameServerTopSup do
  use Supervisor

  require Logger

  def start_link(args) do
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
      SuperPoker.Multiplayer.TableStarter
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
