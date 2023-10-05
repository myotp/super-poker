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
  alias SuperPoker.Core.Deck

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
      button_pos: 0
    ]
  end

  defmodule Player do
    defstruct [:pos, :username, :chips, :current_street_bet, :status]
  end

  # 最小化编写TDD
  def new(%{max_players: max_players, sb: sb, bb: bb, buyin: buyin}) do
    %State{buyin: buyin, sb_amount: sb, bb_amount: bb, max_players: max_players}
  end

  def join_table(%{players: players} = state, username) do
    case username_to_pos(state, username) do
      nil ->
        case first_available_pos(state) do
          nil ->
            {:error, :table_full}

          pos ->
            player = %Player{pos: pos, username: username, chips: state.buyin, status: :JOINED}
            state = %State{state | players: Map.put(players, pos, player)}
            {:ok, state}
        end

      _ ->
        {:error, :already_in_table}
    end
  end

  def leave_table(%State{players: players} = state, username) do
    case get_player_by_username(state, username) do
      nil ->
        {:error, :not_in_table}

      %Player{} = player ->
        state = %State{state | players: Map.put(players, player.pos, nil)}
        {:ok, player.chips, state}
    end
  end

  # TODO: 后续替换为players_info_map实现
  def players_info(%State{max_players: max_players} = state) do
    0..(max_players - 1)
    |> Enum.map(fn pos ->
      case get_player_by_pos(state, pos) do
        nil ->
          nil

        %Player{} = player ->
          %{
            player.username => %{
              username: player.username,
              chips: player.chips,
              status: player.status
            }
          }
      end
    end)
    |> Enum.reject(&is_nil/1)
  end

  def players_info_map(%State{max_players: max_players} = state) do
    0..(max_players - 1)
    |> Enum.map(fn pos ->
      case get_player_by_pos(state, pos) do
        nil ->
          nil

        %Player{} = player ->
          {player.username,
           %{
             username: player.username,
             chips: player.chips,
             status: player.status
           }}
      end
    end)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end

  def all_players(state) do
    players_info_map(state)
    |> Enum.map(fn {username, _player} -> username end)
  end

  def player_start_game(%State{players: players} = state, username) do
    case get_player_by_username(state, username) do
      %Player{} = player ->
        updated_players = %{players | player.pos => %{player | status: :READY}}
        {:ok, %State{state | players: updated_players}}
    end
  end

  def can_table_start_game?(%State{max_players: max_players} = state) do
    num_ready_players =
      0..(max_players - 1)
      |> Enum.map(fn pos -> get_player_by_pos(state, pos) end)
      |> Enum.reject(&is_nil/1)
      |> Enum.filter(fn player -> player.status == :READY end)
      |> Enum.count()

    num_ready_players >= @min_players
  end

  def table_start_game!(%State{table_status: :WAITING} = state) do
    state =
      state
      |> change_table_status_to(:RUNNING)
      |> reset_cards()
      |> reset_players_bet()

    %State{state | table_status: :RUNNING}
  end

  defp change_table_status_to(state, new_status) do
    %State{state | table_status: new_status}
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
  def generate_players_data_for_rules_engine(%State{max_players: max_players} = state) do
    pos_chips =
      0..(max_players - 1)
      |> Enum.map(fn pos ->
        player = get_player_by_pos(state, pos)
        {pos, player.chips}
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
