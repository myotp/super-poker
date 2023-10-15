defmodule SuperPoker.IrcDataset.PlayerActions do
  alias SuperPoker.IrcDataset.PlayerActions

  defstruct [
    :username,
    :game_id,
    :num_players,
    :pos,
    :preflop,
    :flop,
    :turn,
    :river,
    :bankroll,
    :total_bet,
    :winnings,
    :hole_cards
  ]

  # player             #play prflop    turn         bankroll    winnings
  #           timestamp    pos   flop       river           action      cards
  # Jak       820830094  2  1 Bc  kc    kc    k          850   40   80 7c Ac
  # num       820830094  2  2 Bk  b     b     k         1420   40    0 9h Kh
  # ZhaoYun   975790230  6  2 B   -     -     -         2671   20   30
  def parse(str) do
    [
      username,
      game_id,
      num_players,
      pos,
      preflop,
      flop,
      turn,
      river,
      bankroll,
      total_bet,
      winnings | cards
    ] = String.split(str, " ", trim: true)

    hole_cards =
      case cards do
        [_, _] ->
          cards
          |> Enum.join(" ")
          |> String.upcase()

        [] ->
          nil
      end

    %PlayerActions{
      username: username,
      game_id: game_id |> String.to_integer(),
      num_players: num_players |> String.to_integer(),
      pos: pos |> String.to_integer(),
      preflop: preflop,
      flop: flop |> round_action_maybe_empty(),
      turn: turn |> round_action_maybe_empty(),
      river: river |> round_action_maybe_empty(),
      bankroll: bankroll |> String.to_integer(),
      total_bet: total_bet |> String.to_integer(),
      winnings: winnings |> String.to_integer(),
      hole_cards: hole_cards
    }
  end

  defp round_action_maybe_empty("-"), do: nil
  defp round_action_maybe_empty(str), do: str
end
