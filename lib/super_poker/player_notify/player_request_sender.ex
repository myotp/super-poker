defmodule SuperPoker.PlayerNotify.PlayerRequestSender do
  alias SuperPoker.Player.PlayerServer
  alias SuperPoker.Player

  def notify_blind_bet(all_players, blinds) do
    Enum.each(all_players, fn username ->
      Player.notify_blind_bet(username, blinds)
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

  # 一方fold，另一方自动获胜，不用比牌
  def notify_winner_result(all_players, winner, player_chips, nil) do
    Enum.each(all_players, fn player ->
      Player.notify_winner_result(player, winner, player_chips)
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

  def notify_deal_cards(all_players, street, cards) do
    Enum.each(all_players, fn player ->
      IO.puts("通知玩家 #{player} 当前发牌轮 #{street} 发牌 #{inspect(cards)}")
    end)
  end
end
