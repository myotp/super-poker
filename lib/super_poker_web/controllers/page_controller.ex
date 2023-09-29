defmodule SuperPokerWeb.PageController do
  use SuperPokerWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    redirect(conn, to: ~p"/lobby")
  end
end
