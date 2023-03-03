defmodule SuperPoker.Multiplayer.TableSup do
  use DynamicSupervisor
  require Logger
  alias SuperPoker.Multiplayer.TableServer

  # =================== Public API =====================
  def start_table(args) do
    DynamicSupervisor.start_child(__MODULE__, {TableServer, args})
  end

  # ============= DynamicSupervisor 回调部分 =============
  def start_link(args) do
    Logger.info("管理每个具体游戏桌子的DyanmicSupervisor即将启动...")
    DynamicSupervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(_args) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
