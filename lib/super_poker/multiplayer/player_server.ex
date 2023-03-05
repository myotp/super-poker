defmodule SuperPoker.Multiplayer.PlayerServer do
  use GenServer
  require Logger

  alias SuperPoker.Multiplayer.HeadsupTableServer, as: TableServerAPI

  defmodule State do
    defstruct [
      :username,
      :total_chips,
      table_id: nil,
      hole_cards: [],
      chips_on_table: 0,
      state: :LOBBY,
      clients: []
    ]
  end

  # ================ 针对来自客户端的API ======================
  def start_player(username) do
    DynamicSupervisor.start_child(SuperPoker.Multiplayer.PlayerSup, {__MODULE__, username})
  end

  def join_table(username, table_id, buyin) do
    GenServer.call(via_tuple(username), {:join_table, table_id, buyin})
  end

  def start_game(username) do
    GenServer.call(via_tuple(username), :start_game)
  end

  # ================ 针对来自服务器端的API ====================
  def notify_blind_bet(username, blinds) do
    GenServer.call(via_tuple(username), {:blind_bet, blinds})
  end

  def deal_hole_cards(username, hole_cards) do
    GenServer.call(via_tuple(username), {:deal_hole_cards, hole_cards})
  end

  # ================ 测试辅助 ================================
  def debug_state(username) do
    GenServer.cast(via_tuple(username), :debug_state)
  end

  # ================ GenServer回调部分 =======================
  def start_link(username) do
    Logger.info("启动玩家 #{username} 进程")
    GenServer.start_link(__MODULE__, username, name: via_tuple(username))
  end

  defp via_tuple(username) do
    {:via, Registry, {SuperPoker.Multiplayer.PlayerRegistry, username}}
  end

  @impl GenServer
  def init(username) do
    Process.flag(:trap_exit, true)
    log("对于玩家#{username}启动独立player进程")
    {:ok, %State{username: username, state: :LOBBY}, {:continue, :load_user_info}}
  end

  @impl GenServer
  def handle_continue(:load_user_info, %State{username: username} = state) do
    user = load_user_info(username)
    {:noreply, %State{state | total_chips: user.chips}}
  end

  @impl GenServer
  def handle_cast(:debug_state, %State{username: username} = state) do
    log("玩家#{username} state=#{inspect(state)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(
        {:join_table, table_id, buyin},
        _from,
        %State{username: username, total_chips: total_chips} = state
      ) do
    case TableServerAPI.join_table(table_id, username) do
      :ok ->
        state = %State{
          state
          | chips_on_table: buyin,
            table_id: table_id,
            total_chips: total_chips - buyin
        }

        {:reply, :ok, state}

      error ->
        {:reply, error, state}
    end
  end

  def handle_call(:start_game, _from, %State{table_id: table_id, username: username} = state) do
    TableServerAPI.start_game(table_id, username)
    {:reply, :ok, state}
  end

  def handle_call(
        {:blind_bet, blind_bet_info},
        _from,
        %State{username: username, chips_on_table: chips_on_table, clients: clients} = state
      ) do
    my_blind_bet = Map.get(blind_bet_info, username, 0)
    chips_left = chips_on_table - my_blind_bet
    notify_player_clients(clients, {:blind_bet, chips_left, blind_bet_info})
    {:reply, :ok, %State{state | chips_on_table: chips_left}}
  end

  def handle_call({:deal_hole_cards, hole_cards}, _from, %State{clients: clients} = state) do
    notify_player_clients(clients, {:hold_cards, hole_cards})
    {:reply, :ok, %State{state | hole_cards: hole_cards}}
  end

  defp log(msg) do
    Logger.info("#{inspect(self())} " <> msg, ansi_color: :light_magenta)
  end

  defp load_user_info(username) do
    %{username: username, chips: 9999}
  end

  # ============================ 这里多一层函数为把所有事件集中列出来，便于后续实现客户端 ================
  # {:blind_bet, my_chips_on_table_left, blind_bet_info}
  # {:hole_cards, my_hole_cards}
  defp notify_player_clients(clients, event) do
    Enum.each(clients, fn client_pid ->
      send(client_pid, event)
    end)
  end
end
