defmodule SuperPoker.PlayerNotify.PlayerRequestSender do
  alias SuperPoker.Player

  def notify_players_info(all_players, players_info) do
    Enum.each(all_players, fn username ->
      Player.notify_players_info(username, players_info)
    end)
  end

  def notify_bets_info(all_players, blinds) do
    Enum.each(all_players, fn username ->
      Player.notify_bets_info(username, blinds)
    end)
  end

  def deal_hole_cards(username, hole_cards) do
    Player.deal_hole_cards(username, hole_cards)
  end

  def notify_player_action(all_players, current_action_username, actions) do
    Enum.each(all_players, fn player ->
      Player.notify_player_todo_actions(player, current_action_username, actions)
    end)
  end

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
      Player.notify_winner_result(player, winner, player_chips, nil)
    end)
  end

  # 双方摊牌打平
  def notify_winner_result(all_players, nil, players_chips, {type, win5, lose5}) do
    Enum.each(all_players, fn player ->
      IO.puts("""
       通知玩家 #{player} 最终两人打平 手牌类型 #{type}
       玩家1 #{inspect(win5)} 玩家2 #{inspect(lose5)}
      大伙筹码更新 #{inspect(players_chips)}
      """)
    end)
  end

  # 正常一方获胜，另一方失败
  def notify_winner_result(all_players, winner, players_chips, {type, win5, lose5}) do
    Enum.each(all_players, fn player ->
      IO.puts("""
       通知玩家 #{player} 最终胜利玩家 #{winner} 手牌类型 #{type}
       赢家 #{inspect(win5)} 输家 #{inspect(lose5)}
      大伙筹码更新 #{inspect(players_chips)}
      """)
    end)
  end
end
