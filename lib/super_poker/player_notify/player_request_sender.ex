defmodule SuperPoker.PlayerNotify.PlayerRequestSender do
  alias SuperPoker.Player

  alias SuperPoker.PlayerNotify.PlayerNotifierBehaviour
  @behaviour PlayerNotifierBehaviour

  @impl PlayerNotifierBehaviour
  def notify_players_info(all_players, players_info) do
    Enum.each(all_players, fn username ->
      Player.notify_players_info(username, players_info)
    end)
  end

  @impl PlayerNotifierBehaviour
  def notify_bets_info(all_players, bets_info) do
    IO.inspect(bets_info, label: "通知所有玩家目前下注最新信息")

    Enum.each(all_players, fn username ->
      Player.notify_bets_info(username, bets_info)
    end)
  end

  @impl PlayerNotifierBehaviour
  def deal_hole_cards(username, hole_cards) do
    Player.deal_hole_cards(username, hole_cards)
  end

  @impl PlayerNotifierBehaviour
  def notify_player_todo_actions(all_players, current_action_username, actions) do
    IO.puts("==等待 #{current_action_username} 操作 #{inspect(actions)}")

    Enum.each(all_players, fn player ->
      Player.notify_player_todo_actions(player, current_action_username, actions)
    end)
  end

  @impl PlayerNotifierBehaviour
  def deal_community_cards(all_players, street, cards) do
    # TODO: 发牌信息完成
    Enum.each(all_players, fn player ->
      IO.puts("通知玩家 #{player} 当前发牌轮 #{street} 发牌 #{inspect(cards)}")
      Player.deal_community_cards(player, street, cards)
    end)
  end

  # 一方fold，另一方自动获胜，不用比牌
  def notify_winner_result(all_players, winner, player_chips, nil) do
    Enum.each(all_players, fn player ->
      Player.notify_winner_result(player, winner, player_chips, {%{}, []})
    end)
  end

  # 双方摊牌打平
  def notify_winner_result(all_players, nil, players_chips, {_type, hole_cards, win5, _lose5}) do
    Enum.each(all_players, fn player ->
      Player.notify_winner_result(player, nil, players_chips, {hole_cards, win5})
    end)
  end

  # 正常一方获胜，另一方失败
  def notify_winner_result(all_players, winner, players_chips, {_type, hole_cards, win5, _lose5}) do
    IO.puts("通知最终结果333, 获胜方为: #{winner}, 最终筹码更新为: #{inspect(players_chips)}")

    Enum.each(all_players, fn player ->
      Player.notify_winner_result(player, winner, players_chips, {hole_cards, win5})
    end)
  end
end
