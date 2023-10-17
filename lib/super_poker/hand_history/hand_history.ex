defmodule SuperPoker.HandHistory.HandHistory do
  defstruct [
    :game_id,
    :sb_amount,
    :bb_amount,
    :start_time
  ]

  def history_example() do
    [
      {:deal, :flop, "8d 5d Ac"}
    ]
  end
end
