defmodule SuperPoker.History.HhsmithyExporter do
  alias SuperPoker.History.GameHistory

  # TODO: 用上模版LEEx还是HEEx
  def to_string(%GameHistory{}) do
    """
    SuperPoker Hand #12345:  Hold'em No Limit ($2.50/$5.00 USD) - 1999-12-31 23:59:59
    Table 'Rigel' 6-max Seat #4 is the button
    Seat 1: Anna ($1091.61 in chips)
    Seat 2: Bob ($581.64 in chips)
    """
  end
end
