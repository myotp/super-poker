# 这里，就是快速启动原型模拟，用的简单文本协议，后续是可以值得调整比如gRPC之类的交互方式的
# 当然，那样的时候，就得一个真正的CLI程序了，而不能是简单的Telnet了
# 所以，当下简单Telnet的话，也就还好了
# [GOOD-Elixir-OTP] 这里，其实相当于boundary了就，要通过调用内部API来完成诸如symbol验证等操作
defmodule SuperPoker.Multiplayer.TelnetProtocol do
  # 外面已经去掉Telnet的偶然回车
  # 这里就是所谓的协议的定义部分了实际上
  def parse(""), do: {:ok, :new_line}

  def parse("LOGIN " <> login_info) do
    case String.split(login_info, ":", parts: 2) do
      [username, password] ->
        {:ok, {:login, {username, password}}}

      _ ->
        {:error, :invalid_request}
    end
  end

  def parse("LIST" <> _) do
    {:ok, :list_games}
  end

  def parse("JOIN " <> game_id) do
    {:ok, {:join, String.to_integer(game_id)}}
  end

  def parse("START" <> _) do
    {:ok, :start_game}
  end
end
