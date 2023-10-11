defmodule SuperPoker.Bot.PlayerBotServer do
  use GenServer
  require Logger

  alias SuperPoker.Table

  @moduledoc """
  这里, 争取从API层面, 从实现层面乱入PlayerServer对应的
  那样的话, 就可以从派发消息的角度, 形成一个Player但是多个不同类型的GenServer派发了
  比如可以PlayerServer与这里的PlayerBotServer都是同一份API与回调
  但是, 完全可以做出不同的处理来
  """
  defmodule State do
    defstruct [
      :username
    ]
  end

  def start_bot(username, table_id) do
    # 都挂在同样的PlayerSupervisor旗下, 但是是不同的模块实现
    DynamicSupervisor.start_child(
      SuperPoker.Player.PlayerSupervisor,
      {__MODULE__, [username, table_id]}
    )
  end

  # ================ GenServer回调部分 =======================
  def start_link([username, table_id]) do
    IO.puts("启动bot #{username} 加入桌子#{table_id}")
    GenServer.start_link(__MODULE__, [username, table_id], name: via_tuple(username))
  end

  defp via_tuple(username) do
    {:via, Registry, {SuperPoker.Player.PlayerRegistry, username}}
  end

  @impl GenServer
  def init([username, table_id]) do
    log("对于bot#{username}启动独立player进程")

    {:ok, %State{username: username}, {:continue, {:join_table, table_id}}}
  end

  @impl GenServer
  def handle_continue({:join_table, table_id}, %State{username: username} = state) do
    Table.join_table(table_id, username)
    log("TODO bot#{username} 加入桌子 #{table_id}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(msg, %State{username: username} = state) do
    log("TODO bot#{username}收到消息 #{inspect(msg)}")
    {:noreply, state}
  end

  defp log(msg) do
    Logger.info("#{inspect(self())} " <> msg, ansi_color: :light_yellow)
  end
end
