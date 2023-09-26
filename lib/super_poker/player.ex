# 作为用户代理进程player_server部分的API封装模块
# 请求一般来自于两个方向，一个是从客户端的具体操作
# 另一个是来自牌桌的调用
defmodule SuperPoker.Player do
  alias SuperPoker.Player.PlayerServer

  #### ============== 来自玩家客户端的请求 ==================####
  def start_player(username) do
    PlayerServer.start_player(username)
  end

  def join_table(username, table_id, buyin) do
    PlayerServer.join_table(username, table_id, buyin)
  end

  def start_game(username) do
    PlayerServer.start_game(username)
  end

  def player_action(username, action) do
    PlayerServer.player_action(username, action)
  end

  #### ============== 来自牌桌服务器的调用 ==================####
  def notify_players_info(username, players_info) do
    PlayerServer.notify_players_info(username, players_info)
  end

  def notify_bets_info(username, blinds) do
    PlayerServer.notify_bets_info(username, blinds)
  end

  def deal_hole_cards(username, hole_cards) do
    PlayerServer.deal_hole_cards(username, hole_cards)
  end

  def deal_community_cards(username, street, cards) do
    PlayerServer.deal_community_cards(username, street, cards)
  end

  def notify_player_todo_actions(player, current_action_username, actions) do
    PlayerServer.notify_player_todo_actions(player, current_action_username, actions)
  end

  # 通知show hands手牌, 如果有玩家fold的话, hole_cards为%{}不予显示
  def notify_winner_result(player, winner, player_chips, hole_cards_and_win5) do
    PlayerServer.notify_winner_result(player, winner, player_chips, hole_cards_and_win5)
  end
end
