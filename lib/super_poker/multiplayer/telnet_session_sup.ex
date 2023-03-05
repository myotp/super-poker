defmodule SuperPoker.Multiplayer.TelnetSessionSup do
  use DynamicSupervisor
  alias SuperPoker.Multiplayer.TelnetSessionServer

  # [GOOD-OTP] 这里，不像Erlang的simple_one_for_one，而是只在start_child的时候，才指定具体回调GenServer即可
  def start_telnet_session(socket) do
    DynamicSupervisor.start_child(__MODULE__, {TelnetSessionServer, socket})
  end

  def start_link(_args) do
    IO.puts("启动SessionSupervisor管理潜在的新session...")

    # [GOOD-OTP] 理解了前边的GenServer以及Supervisor也就是Elixir的OTP体系之后，这里非常好写了就
    DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)
  end

  @impl DynamicSupervisor
  def init(nil) do
    # [GOOD-OTP] 因为涉及带有外部TCP连接，死了的话，也没必要重启了就
    # [GOOD-OTP] 这里，跟普通Supervisor.init/2就是没有前边的children那个list而已，非常统一和谐
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
