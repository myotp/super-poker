defmodule SuperPoker.Player.PlayerServer do
  use GenServer
  require Logger

  alias SuperPoker.Table
  alias SuperPoker.GameServer.HeadsupTableServer, as: TableServerAPI

  defmodule State do
    defstruct [
      :username,
      :total_chips,
      table_id: nil,
      hole_cards: [],
      community_cards: nil,
      bet_actions: [],
      chips_on_table: 0,
      state: :LOBBY,
      clients: []
    ]
  end

  # ================ 针对来自客户端的API ======================
  def start_player(username) do
    client = self()

    DynamicSupervisor.start_child(
      SuperPoker.Player.PlayerSupervisor,
      {__MODULE__, [username, client]}
    )
  end

  def join_table(username, table_id, buyin) do
    GenServer.call(via_tuple(username), {:join_table, table_id, buyin})
  end

  def start_game(username) do
    GenServer.call(via_tuple(username), :start_game)
  end

  def player_action(username, action) do
    GenServer.call(via_tuple(username), {:player_action, action})
  end

  # ================ 针对来自服务器端的API ====================
  # 通知客户端用异步形式，因为玩家join_table或者start_game都在同步调用中
  def notify_players_info(username, players_info) do
    GenServer.cast(via_tuple(username), {:notify_players_info, players_info})
  end

  def notify_bets_info(username, blinds) do
    GenServer.call(via_tuple(username), {:bets_info, blinds})
  end

  def deal_hole_cards(username, hole_cards) do
    GenServer.call(via_tuple(username), {:deal_hole_cards, hole_cards})
  end

  def deal_community_cards(username, street, cards) do
    GenServer.call(via_tuple(username), {:deal_community_cards, street, cards})
  end

  def notify_player_todo_actions(username, action_player, actions) do
    GenServer.call(via_tuple(username), {:todo_actions, action_player, actions})
  end

  def notify_winner_result(username, winner, player_chips, cards) do
    GenServer.call(via_tuple(username), {:winner_result, winner, player_chips, cards})
  end

  # ================ 测试辅助 ================================
  def debug_state(username) do
    GenServer.cast(via_tuple(username), :debug_state)
  end

  def get_state(username) do
    GenServer.call(via_tuple(username), :get_state)
  end

  # ================ GenServer回调部分 =======================
  def start_link([username, client]) do
    Logger.info("对于client=#{inspect(client)} 启动玩家 #{username} 进程")
    GenServer.start_link(__MODULE__, [username, client], name: via_tuple(username))
  end

  defp via_tuple(username) do
    {:via, Registry, {SuperPoker.Player.PlayerRegistry, username}}
  end

  @impl GenServer
  def init([username, client_pid]) do
    Process.flag(:trap_exit, true)
    log("对于玩家#{username}启动独立player进程")

    {:ok, %State{username: username, clients: [client_pid], state: :LOBBY},
     {:continue, :load_user_info}}
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

  def handle_cast({:notify_players_info, players_info}, %State{clients: clients} = state) do
    notify_player_clients(clients, {:players_info, players_info})
    {:noreply, state}
  end

  @impl GenServer
  # ========= 来自客户端方面的请求回调 ==============
  def handle_call(
        {:join_table, table_id, buyin},
        _from,
        %State{username: username, total_chips: total_chips} = state
      ) do
    case Table.join_table(table_id, username) do
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
    {:reply, :ok, %State{state | community_cards: []}}
  end

  def handle_call(
        {:player_action, action},
        _from,
        %State{table_id: table_id, username: username, bet_actions: bet_actions} = state
      ) do
    IO.puts("==player_server== user[#{username}] action: #{inspect(action)}")

    case valid_player_action?(action, bet_actions) do
      true ->
        TableServerAPI.player_action_done(table_id, username, action)
        {:reply, :ok, %State{state | bet_actions: []}}

      _ ->
        {:reply, {:error, :invalid_action}, state}
    end
  end

  # ===================== 来自服务器的请求回调 ====================
  def handle_call(
        {:bets_info, bets_info},
        _from,
        %State{username: username, chips_on_table: _chips_on_table, clients: clients} = state
      ) do
    # TODO: 这里似乎可以直接把整个bets信息丢给后续了就,每个人的每条街累计下注与总的筹码数量都应该正确显示出来后续
    total = bets_info[username].chips_left
    IO.inspect(total, label: "玩家剩余筹码数量为")
    notify_player_clients(clients, {:update_bets, bets_info})
    {:reply, :ok, %State{state | chips_on_table: total}}
  end

  def handle_call({:deal_hole_cards, hole_cards}, _from, %State{clients: clients} = state) do
    notify_player_clients(clients, {:hole_cards, hole_cards})
    {:reply, :ok, %State{state | hole_cards: hole_cards}}
  end

  def handle_call({:deal_community_cards, street, cards}, _from, %State{clients: clients} = state) do
    notify_player_clients(clients, {:community_cards, street, cards})
    {:reply, :ok, %State{state | community_cards: state.community_cards ++ cards}}
  end

  def handle_call(
        {:todo_actions, action_player, actions},
        _from,
        %State{username: username, clients: clients} = state
      ) do
    if username == action_player do
      notify_player_clients(clients, {:bet_actions, actions})
      {:reply, :ok, %State{state | bet_actions: actions}}
    else
      notify_player_clients(clients, {:wating, action_player})
      {:reply, :ok, %State{state | bet_actions: []}}
    end
  end

  def handle_call(
        {:winner_result, winner, player_chips, cards},
        _from,
        %State{clients: clients} = state
      ) do
    IO.puts("===>>> 收到服务器赢家#{winner} 大家筹码 #{inspect(player_chips)} 手牌: #{inspect(cards)}")
    notify_player_clients(clients, {:winner, winner, player_chips})
    {:reply, :ok, state}
  end

  # ==================== 测试辅助回调 ===============================
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  # ==================== 其它辅助函数 =============================
  # TODO: 实际的检查实现还需要处理更多细节可能操作
  defp valid_player_action?(_action, []), do: false

  defp valid_player_action?(_action, _actions) do
    true
  end

  # TODO: 这里，等服务器修正，返回username做key之后，才有办法实现
  # 1. 更新玩家自己的剩余筹码量
  # 2. 更新桌上其它玩家的筹码量
  defp update_chips(state, _player_chips) do
    state
  end

  defp log(msg) do
    Logger.info("#{inspect(self())} " <> msg, ansi_color: :light_magenta)
  end

  defp load_user_info(username) do
    %{username: username, chips: 9999}
  end

  # ============================ 这里多一层函数为把所有事件集中列出来，便于后续实现客户端 ================
  # {:players_info, players_info}

  # {:blind_bet, my_chips_on_table_left, blind_bet_info}
  # 变更为, 这样, 可以响应后续牌局每次的下注变化通知情况
  # {:update_bets, bets_info}

  # {:hole_cards, my_hole_cards}
  # {:waiting_player, username}
  # {:bet_actions, actions}
  # {:winner, winner}
  defp notify_player_clients(clients, event) do
    Enum.each(clients, fn client_pid ->
      send(client_pid, event)
    end)
  end
end
