defmodule SuperPokerWeb.PageController do
  use SuperPokerWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
