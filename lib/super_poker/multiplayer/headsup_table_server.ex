# TODO: 这里，先简单实现单挑桌，很多硬写的p0 p1后续都需要通用处理化
# TODO: 不过，好处是想到反正基于名字，完全不需要客户端，可以先独立完成服务器并测试
# TODO: 后续，结合Testing Elixir看看OTP部分如何测试，以及Design Elixir OTP也有提到OTP测试
defmodule SuperPoker.Multiplayer.HeadsupTableServer do
  use GenServer
  require Logger

  @moduledoc """
  具体每一个牌桌的GenServer进程
  """
  # ======================== 对外 API ================================
  def join_table(table_id, username) do
    GenServer.call(via_table_id(table_id), {:join_table, username})
  end

  def start_game(table_id, username) do
    GenServer.call(via_table_id(table_id), {:start_game, username})
  end

  # for testing
  def get_state(table_id) do
    GenServer.call(via_table_id(table_id), :get_state)
  end

  def debug_state(table_id) do
    GenServer.cast(via_table_id(table_id), :debug_state)
  end

  defp via_table_id(table_id) do
    {:via, Registry, {SuperPoker.Multiplayer.TableRegistry, table_id}}
  end

  # ===================== 定义主体 %State{} 结构 =======================
  defmodule State do
    defstruct [
      # 静态牌桌本身信息
      :max_players,
      :sb_amount,
      :bb_amount,
      :buyin,
      :rules_mod,
      # 动态牌桌信息
      table: nil,
      table_status: :WAITING,
      # 动态玩家信息
      p0: nil,
      p1: nil,
      button_pos: 0
    ]
  end

  defmodule Player do
    defstruct [:pos, :username, :chips, :status]
  end

  # ===================== OTP 回调部分 =================================
  def start_link(%{id: table_id} = args) do
    log("启动 单挑对局桌子 ID=#{table_id}")
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

    log("启动牌桌进程 #{inspect(state)}")
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:join_table, username}, _from, state) do
    case {state.p0, state.p1} do
      {%Player{}, %Player{}} ->
        {:reply, {:error, :table_full}, state}

      {nil, _} ->
        p0 = %Player{pos: 0, username: username, chips: state.buyin, status: :JOINED}
        {:reply, :ok, %State{state | p0: p0}}

      {_, nil} ->
        p1 = %Player{pos: 1, username: username, chips: state.buyin, status: :JOINED}
        {:reply, :ok, %State{state | p1: p1}}
    end
  end

  def handle_call({:start_game, username}, _from, state) do
    state =
      case {state.p0.username, state.p1.username} do
        {^username, _} ->
          put_in(state.p0.status, :READY)

        {_, ^username} ->
          put_in(state.p1.status, :READY)
      end

    {:reply, :ok, state, {:continue, :maybe_start_game}}
  end

  # 测试用
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl GenServer
  def handle_continue(:maybe_start_game, state) do
    if all_players_ready?(state) do
      {:noreply, start_new_game(state), {:continue, :handle_next_action}}
    else
      {:noreply, state}
    end
  end

  def handle_continue(:handle_next_action, state) do
    # TODO: 这里，开始要做大小盲下注，以及后续操作，尤其是通知的部分，如何设计，方便测试
    IO.inspect(state.table.next_action, label: "TODO开始处理rules那边下一步动作")
    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:debug_state, state) do
    log("牌桌状态 #{inspect(state)}")
    {:noreply, state}
  end

  # =================== 基于%State{} 的大操作函数 =====
  defp start_new_game(%State{rules_mod: rules_mod, sb_amount: sb, bb_amount: bb} = state) do
    players_data = generate_players_data_for_rules_engine(state)
    table = rules_mod.new(players_data, state.button_pos, {sb, bb})
    %State{state | table_status: :RUNNING, table: table}
  end

  defp all_players_ready?(state) do
    case {state.p0.status, state.p1.status} do
      {:READY, :READY} -> true
      _ -> false
    end
  end

  defp generate_players_data_for_rules_engine(state) do
    %{0 => state.p0.chips, 1 => state.p1.chips}
  end

  # =================== 其它 ======================
  defp log(msg) do
    Logger.info("#{inspect(self())}" <> msg, ansi_color: :cyan)
  end
end
