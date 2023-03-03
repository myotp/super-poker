defmodule SuperPoker.Multiplayer.TableServer do
  use GenServer
  require Logger

  @moduledoc """
  具体每一个牌桌的GenServer进程
  """
  # ======================== 对外 API ================================
  def debug_state(table_id) do
    GenServer.cast(via_table_id(table_id), :debug_state)
  end

  defp via_table_id(table_id) do
    {:via, Registry, {SuperPoker.Multiplayer.TableRegistry, table_id}}
  end

  # ===================== 定义主体 %State{} 结构 =======================
  defmodule State do
    defstruct [:max_players, :sb_amount, :bb_amount, :buyin, :rules_mod]
  end

  # ===================== OTP 回调部分 =================================
  def start_link(%{id: table_id} = args) do
    GenServer.start_link(__MODULE__, args, name: via_table_id(table_id))
  end

  @impl GenServer
  def init(%{
        max_players: max_players,
        sb: sb,
        bb: bb,
        buyin: buyin,
        rules: mod
      }) do
    state = %State{
      max_players: max_players,
      sb_amount: sb,
      bb_amount: bb,
      buyin: buyin,
      rules_mod: mod
    }

    Logger.info("#{inspect(self())} 启动牌桌进程 #{inspect(state)}")
    {:ok, state}
  end

  @impl GenServer
  def handle_cast(:debug_state, state) do
    Logger.info("[DEBUG] 牌桌 #{inspect(self())} 状态 #{inspect(state)}")
    {:noreply, state}
  end
end
