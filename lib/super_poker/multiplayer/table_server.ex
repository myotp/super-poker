defmodule SuperPoker.Multiplayer.TableServer do
  use GenServer
  require Logger

  @moduledoc """
  具体每一个牌桌的GenServer进程
  """

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  def init(init_arg) do
    Logger.info("#{inspect(self())} 启动牌桌进程 #{inspect(init_arg)}")
    {:ok, init_arg}
  end
end
