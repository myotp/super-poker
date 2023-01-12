# Poker规则

## 先后顺序规则

- 多人局第一轮flop发牌之前，button位之后，分别为sb, bb，然后bb下家先说话
- flop发牌及之后，button总是最后行动位，button+1位第一行动，如果button盖牌，依然是button+1先行动

# TODO

## 核心游戏

- [ ] 对于hand这种，实际上想表述的是[card()]的概念，应该如何抽取定义模块，测试

# 二人对战下注规则模型

- 前边无人下注，自己领打的情况下，可以选择 fold/check/bet 其中bet的一个特例是allin所有筹码
- 前边有人下注，自己跟随的情况下，可以选择 fold/call/raise 不够call的话或者raise到所有都是allin的一种
- 关于allin基本不用特别特殊处理，基本上在三种情况下allin:
  - 自己bet的时候，所有下注allin，属于bet的一个特例
  - 自己raise的时候，所有下注allin，属于raise的一个特例
  - 自己call的时候，筹码不足的情况下allin，属于call的一个特殊形式
- 上面这些，raise的话，会改变起始位置，从而需要再次终结在raise的位置
- 从编程模型角度上来看，fold就放弃了，游戏结束，check相当于{call, 0}了，bet跟raise实际上是一样的
- 根据zynga扑克看起来raise的金额
  - 目标金额是当前call的两倍起跳，加量为至少一个bb，比如当前只有大盲50的量，raise就是100，150，200以此类推
  - 玩家显示raise的部分，是达到目标所需的值，比如自己已有25入池了，目标100的话，raise菜单中列出来就是75起
  - 而bet的话，就可以以bb作为起始，每bb为加价
- 由于fold总是可选项之一，故模型next_action部分，不包括fold了就，可以简化一些编程麻烦
- 即使二人对战就已经相当复杂了，幸亏先从二人对战实现开始
