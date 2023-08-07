# [GOOD-OTP] 这里，是我针对DynamicSupervisor，但是我有一组清晰的概念说要启动谁的效果
# https://elixirforum.com/t/how-to-start-dynamic-supervisor-workers-on-application-startup/3582/2
defmodule SuperPoker.Multiplayer.TableStarter do
  # 注意transient类型restart, 负责加载完之后，此进程就完事了, 可以关闭, 无需重启
  use GenServer, restart: :transient
  require Logger
  alias SuperPoker.GameServer.TableLoader
  alias SuperPoker.GameServer.TableSupervisor

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil)
  end

  @impl GenServer
  def init(_) do
    {:ok, nil, {:continue, :start_table_processes}}
  end

  @impl GenServer
  def handle_continue(:start_table_processes, state) do
    Logger.info("#{inspect(self())} 即将针对每个游戏服务器启动新进程")
    {:ok, table_info} = TableLoader.all_table_info()
    Logger.info("TODO 实际启动table server进程 #{inspect(table_info)}")
    Enum.each(table_info, &TableSupervisor.start_table/1)
    # [GOOD-OTP] 实践动手，才想起来，这里需要:stop标示出来才对
    {:stop, {:shutdown, :job_done}, state}
  end
end
