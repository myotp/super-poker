defmodule SuperPoker.GameServer.TableSupervisor do
  use DynamicSupervisor
  require Logger

  # =================== Public API =====================
  def start_table(%{table: table_server_mod} = args) do
    DynamicSupervisor.start_child(__MODULE__, {table_server_mod, args})
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
