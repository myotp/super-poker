alias SuperPoker.Core.{Card, Deck, Hand}

# GTO相关
alias SuperPoker.Gto.PreflopEquity
alias SuperPoker.Gto.{EquityCalculator, Range}

# GTO报告
alias SuperPoker.GtoReport.EquitySummary
alias SuperPoker.GtoReport.RankingProbabilityReport
alias SuperPoker.GtoReport.AceKingReport

# 多人游戏相关
alias SuperPoker.GameServer.TableSupervisor
alias SuperPoker.GameServer.HeadsupTableServer
alias SuperPoker.Player.PlayerServer
alias SuperPoker.Player

# Bot相关
alias SuperPoker.Bot.PlayerBotServer

#
dev_table_config = %{
  id: 1055,
  max_players: 2,
  sb: 5,
  bb: 10,
  buyin: 500,
  table: SuperPoker.GameServer.HeadsupTableServer,
  rules: SuperPoker.RulesEngine.SimpleRules1v1,
  player: SuperPoker.PlayerNotify.PlayerRequestPrinter
}

# IRC dataset
alias SuperPoker.IrcDataset.DumpIrcDataset
alias SuperPoker.IrcDataset.IrcGame
