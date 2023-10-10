# 这个模块用来最终安静执行测试用的
defmodule SuperPoker.PlayerNotify.PlayerRequestNull do
  def notify_players_info(_all_players, _players_info), do: :ok
  def notify_bets_info(_all_players, _bets_info), do: :ok
  def deal_hole_cards(_username, _cards), do: :ok
  def notify_player_todo_actions(_all_players, _current_action_username, _actions), do: :ok
  def deal_community_cards(_all_players, _street, _cards), do: :ok
  def notify_winner_result(_all_players, _winner, _player_chips, _res), do: :ok
end
