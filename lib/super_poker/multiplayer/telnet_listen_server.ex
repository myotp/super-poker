# 这里是主要搬家原来写的echo服务器，顺带凑出来层级Supervisor组合出来
# 并且，这里融入普通进程写法，然后参考Elixir视频教程写法，通过一个专门GenServer进程挂入即可
# [GOOD-Elixir] 这里，普通进程写法，明显比愣去套用GenServer看起来更优雅，非常好的技巧
# 这样，本文件，就能非常类似原来Erlang写的单独小文件的感觉，十分简洁清晰，又都集中于一起
defmodule SuperPoker.Multiplayer.TelnetListenServer do
  require Logger
  alias SuperPoker.Multiplayer.TelnetSessionSup
  @port 4040

  def start_listen_server do
    spawn(__MODULE__, :do_start, [])
  end

  def do_start() do
    port = Application.get_env(:tic_tac_toe, :tcp_listen_port, @port)
    Logger.info("#{inspect(self())} #{__MODULE__} 即将监听端口 #{port}")

    # [GOOD-Elixir] 这里，用Elixir的地道list中表达写法，去调用Erlang函数，:binary居前，然后套在一个大[]当中就行了
    # 这里，看视频教程是一遍，自己动手做一遍才真正理解
    {:ok, lsock} = :gen_tcp.listen(@port, [:binary, packet: 0, active: true, reuseaddr: true])
    # 手工注册个名字，在observer当中看起来更清晰
    Process.register(self(), __MODULE__)
    loop(lsock)
  end

  defp loop(lsock) do
    Logger.info("#{inspect(self())} #{__MODULE__} 等待客户端连接...")
    {:ok, sock} = :gen_tcp.accept(lsock)
    Logger.info("#{inspect(self())} #{__MODULE__} 成功收到客户端连接请求")
    # 这里改为是通过DynamicSupervisor回调模块来调用启动start_child操作
    {:ok, pid} = TelnetSessionSup.start_telnet_session(sock)
    Logger.info("#{inspect(self())} #{__MODULE__} 启动一个新的session响应进程#{inspect(pid)}")

    # 这里，后续加了一个sleep，发现，即使在controlling_process切过去之前有消息
    # 设置完controlling_process之后，消息也一并过去了就
    # 这里，开始的时候，随便设置了15秒的延迟，观察效果，那边可以send，但是得等controlling设置过去之后才能收到消息
    :gen_tcp.controlling_process(sock, pid)
    loop(lsock)
  end
end
