defmodule SuperPoker.Multiplayer.TelnetListenManager do
  use GenServer
  require Logger
  alias SuperPoker.Multiplayer.TelnetListenServer

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  # 因为，这里只是个关联跳板，所以，要手工主动自己去链接过去
  @impl GenServer
  def init(nil) do
    Logger.info("#{__MODULE__} 即将通过跳板启动TCP监听进程之跳板进程...")
    Process.flag(:trap_exit, true)
    tcp_pid = TelnetListenServer.start_listen_server()
    # [GOOD-Elixir] 这里，充分运用基础Erlang的进程那一套关系引入进来
    Process.link(tcp_pid)
    {:ok, tcp_pid}
  end

  # [GOOD-OTP] 这里，跳板进程要随着挂掉，还能额外展示如何正确挂掉自己
  # [GOOD-OTP] 这种方式方法从某种意义上来说，也像G家的gen_server套那个fsm做法
  @impl GenServer
  def handle_info({:EXIT, tcp_pid, reason}, tcp_pid) do
    Logger.error("HELP!!! TCP进程#{inspect(tcp_pid)}挂了，原因: #{reason}")
    Logger.error("跳板进程#{inspect(self())} 也要跟随挂掉，从而重启")
    {:stop, :listen_server_die, nil}
  end
end
