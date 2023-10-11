# 这里刻意设置seed为0, 从而可以顺序运行HeadsupTableServerTest中的测试
# 或者默认skip掉需要seed为0的测试
ExUnit.configure(seed: 0)
ExUnit.start()
Ecto.Adapters.SQL.Sandbox.mode(SuperPoker.Repo, :manual)
