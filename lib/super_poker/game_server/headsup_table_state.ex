defmodule SuperPoker.GameServer.HeadsupTableState do
  @moduledoc """
  关于数据的交互过程, 主要是 Rules <-> Table <-> Player
  居于中心的桌子的pos按照0..MAX-1编号, 比如8人桌就是0..7
  且每个玩家一旦坐上去, 就随机固定下来, 比如Anna, Bot, Cry三个人可能坐的位置是[0, 5, 7]
  在Rules当中, key永远是整理化之后的pos列表, 从零开始有几人就几个,
  并且, 每局pos随着button的改变而改变, 比如8人桌坐了5人只有3个人开始,则对应的pos永远是[0,1,2]
  但是, 每个Rules的pos对应的人, 每局都在发生变化
  在Player这一侧, 因为涉及到用用户名做进程PID映射, 所以, 传递给Player的数据永远用用户名做key
  现阶段故意简化, 桌子只能坐两个人, 且至少两人才能开始, 所以现在无论是从Table角度看
  还是Rules角度看, pos永远都是[0,1], 只不过随着button移动位置两边01对应的应该是不同玩家
  """
  alias SuperPoker.Core.{Deck, Hand, Ranking}
  alias SuperPoker.HandHistory.HandHistory

  @min_players 2
  # 这里的主要变化
  # * 去掉player_mod因为这里只负责更新state不再需要这里去知道player_mod了
  # * 去掉硬写的p0 p1改为通用的players %{}用map来保存
  # * 去掉rules相关内容, 那些上层server组合方式, 而非这里深度嵌套
  defmodule State do
    defstruct [
      # 静态牌桌本身信息
      :max_players,
      :sb_amount,
      :bb_amount,
      :buyin,
      # 动态牌信息
      :deck,
      :community_cards,
      :players_cards,
      table_status: :WAITING,
      # 动态玩家信息
      players: %{},
      chips: %{},
      button_pos: 0,
      # 牌局对战过程历史
      hand_history: nil
    ]
  end

  defmodule Player do
    defstruct [:pos, :username, :current_street_bet, :status]
  end

  # 最小化编写TDD
  def new(%{max_players: max_players, sb: sb, bb: bb, buyin: buyin}) do
    %State{buyin: buyin, sb_amount: sb, bb_amount: bb, max_players: max_players}
  end

  def join_table(%{} = state, username) do
    case username_to_pos(state, username) do
      nil ->
        case first_available_pos(state) do
          nil ->
            {:error, :table_full}

          pos ->
            player = %Player{pos: pos, username: username, status: :JOINED}

            state =
              state
              |> put_in([Access.key(:players), pos], player)
              |> put_in([Access.key(:chips), username], state.buyin)

            {:ok, state}
        end

      _ ->
        {:error, :already_in_table}
    end
  end

  def leave_table(%State{chips: chips} = state, username) do
    case get_player_by_username(state, username) do
      nil ->
        {:error, :not_in_table}

      %Player{} = player ->
        chips_left = chips[username]

        state =
          state
          |> put_in([Access.key(:players), Access.key(player.pos)], nil)
          |> put_in([Access.key(:chips), username], nil)

        {:ok, chips_left, state}
    end
  end

  # TODO: 后续替换为players_info_map实现
  def players_info(%State{players: players, chips: chips}) do
    players
    |> Map.values()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn %Player{} = player ->
      %{
        username: player.username,
        chips: chips[player.username],
        status: player.status
      }
    end)
  end

  def players_info_map(%State{players: players, chips: chips}) do
    players
    |> Map.values()
    |> Enum.reject(&is_nil/1)
    |> Enum.map(fn player ->
      %{
        player.username => %{
          username: player.username,
          chips: chips[player.username],
          status: player.status
        }
      }
    end)
    |> Map.new()
  end

  def chips_info!(%State{chips: chips}) do
    chips
  end

  def all_players(%State{players: players}) do
    Map.values(players)
    # 把:status放入Access.key就可以了
    |> get_in([Access.all(), Access.key(:username)])
    |> Enum.reject(&is_nil/1)
  end

  def player_start_game(%State{players: players} = state, username) do
    case get_player_by_username(state, username) do
      %Player{} = player ->
        updated_players = put_in(players, [player.pos, Access.key(:status)], :READY)
        {:ok, %State{state | players: updated_players}}
    end
  end

  def can_table_start_game?(%State{players: players} = _state) do
    num_ready_players =
      Map.values(players)
      # 把:status放入Access.key就可以了
      |> get_in([Access.all(), Access.key(:status)])
      |> Enum.filter(&(&1 == :READY))
      |> Enum.count()

    num_ready_players >= @min_players
  end

  def table_start_game!(%State{table_status: :WAITING} = state) do
    state
    |> change_table_status_to(:RUNNING)
    |> reset_cards()
    |> reset_players_bet()
    |> init_hand_history()
  end

  def table_finish_game!(%State{} = state, chips_left_from_rules_engine) do
    state
    |> change_table_status_to(:WAITING)
    |> change_players_status_to(:JOINED)
    |> update_players_chips(chips_left_from_rules_engine)
  end

  defp change_table_status_to(state, new_status) do
    %State{state | table_status: new_status}
  end

  defp change_players_status_to(
         %State{max_players: max_players, players: players} = state,
         new_status
       ) do
    players =
      Enum.reduce(0..(max_players - 1), players, fn pos, acc ->
        player = players[pos]
        Map.put(acc, pos, %{player | status: new_status})
      end)

    %State{state | players: players}
  end

  defp update_players_chips(%State{chips: chips} = state, chips_left_from_rules_engine) do
    updated_chips =
      Enum.reduce(chips_left_from_rules_engine, chips, fn {username, chips_left}, acc ->
        Map.put(acc, username, chips_left)
      end)

    %State{state | chips: updated_chips}
  end

  defp reset_cards(%State{} = state) do
    %State{
      state
      | deck: Deck.seq_deck52() |> Deck.shuffle(),
        players_cards: %{},
        community_cards: []
    }
  end

  defp reset_players_bet(%State{players: players} = state) do
    updated_playeres =
      players
      |> Enum.map(fn {pos, player} -> {pos, %Player{player | current_street_bet: 0}} end)
      |> Map.new()

    %State{state | players: updated_playeres}
  end

  defp init_hand_history(%State{} = state) do
    username0 = state.players[0].username
    username1 = state.players[1].username

    players = [
      %{pos: 0, username: username0, chips: state.chips[username0]},
      %{pos: 1, username: username1, chips: state.chips[username1]}
    ]

    blinds =
      case state.button_pos do
        0 ->
          [
            %{username: username0, amount: state.sb_amount},
            %{username: username1, amount: state.bb_amount}
          ]

        1 ->
          [
            %{username: username1, amount: state.sb_amount},
            %{username: username0, amount: state.bb_amount}
          ]
      end

    hh = %HandHistory{
      start_time: NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second),
      button_pos: state.button_pos,
      sb_amount: state.sb_amount,
      bb_amount: state.bb_amount,
      players: players,
      blinds: blinds,
      # 其它信息等下才能知道
      hole_cards: [],
      community_cards: "",
      actions: []
    }

    %State{state | hand_history: hh}
  end

  # 这里还必须是用username做key, 后续需要名字映射player_server进程
  def hole_cards_info!(%State{max_players: max_players} = state) do
    0..(max_players - 1)
    |> Enum.map(fn pos ->
      player = get_player_by_pos(state, pos)
      {player.username, state.players_cards[pos]}
    end)
  end

  def deal_hole_cards!(%State{max_players: max_players, deck: deck} = state) do
    {hole_cards, rest} =
      0..(max_players - 1)
      |> Enum.reduce({%{}, deck}, fn pos, {hole_cards, rest_deck} ->
        {cards, deck} = Deck.take_top_n_cards(rest_deck, 2)
        {Map.put(hole_cards, pos, cards), deck}
      end)

    %State{state | players_cards: hole_cards, deck: rest}
  end

  def deal_community_cards!(%State{deck: deck, community_cards: community_cards} = state, street) do
    {cards, rest} = Deck.take_top_n_cards(deck, street_to_num_cards(street))

    {cards, %State{state | deck: rest, community_cards: community_cards ++ cards}}
  end

  defp street_to_num_cards(:flop), do: 3
  defp street_to_num_cards(:turn), do: 1
  defp street_to_num_cards(:river), do: 1

  # 这里简单起见, 先固定两人玩家, pos可以不需要整理, 整理的意思是说
  # 比如8人玩家桌, 对应所有pos为0-7, 而两个玩家可能坐在了3和6号位子上面
  # 创建rules的时候, 需要整理成[0,1]交给rules以及对应关系
  # 只针对已经READY的玩家生成对战引擎数据
  # 后续这里还需要考虑button位置, 以及多人桌顺序轮替
  def generate_players_data_for_rules_engine(
        %State{max_players: max_players, chips: chips} = state
      ) do
    pos_chips =
      0..(max_players - 1)
      |> Enum.map(fn pos ->
        player = get_player_by_pos(state, pos)
        {pos, chips[player.username]}
      end)
      |> Map.new()

    pos_usernames =
      0..(max_players - 1)
      |> Enum.map(fn pos ->
        player = get_player_by_pos(state, pos)
        {pos, player.username}
      end)
      |> Map.new()

    {pos_chips, pos_usernames}
  end

  def decide_winner(state) do
    [{username1, cards1}, {username2, cards2}] = hole_cards_info!(state)
    rank1 = Ranking.run(cards1 ++ state.community_cards)
    rank2 = Ranking.run(cards2 ++ state.community_cards)

    case Hand.compare(cards1, cards2, state.community_cards) do
      :win ->
        {username1, rank1.type, rank1.best_hand, rank2.best_hand}

      :lose ->
        {username2, rank2.type, rank2.best_hand, rank1.best_hand}

      :tie ->
        {nil, rank1.type, rank1.best_hand, rank2.best_hand}
    end
  end

  # ==================== helper functions ===================
  defp first_available_pos(state) do
    first_available_pos(state, 0)
  end

  defp first_available_pos(%State{max_players: pos}, pos) do
    nil
  end

  defp first_available_pos(state, pos) do
    if state.players[pos] do
      first_available_pos(state, pos + 1)
    else
      pos
    end
  end

  defp get_player_by_pos(%State{players: players} = _state, pos) do
    players[pos]
  end

  defp get_player_by_username(state, username) do
    case username_to_pos(state, username) do
      nil ->
        nil

      pos ->
        get_player_by_pos(state, pos)
    end
  end

  defp username_to_pos(%State{players: players}, username) do
    with {pos, _} <-
           Enum.find(
             players,
             fn
               {_pos, nil} -> false
               {_pos, player} -> player.username == username
             end
           ) do
      pos
    end
  end
end
