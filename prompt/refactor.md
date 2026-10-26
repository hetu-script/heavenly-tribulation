@plan/battle_system_overview.md 这个文档可以让你从总体上理解本项目中和战斗有关的部分。

@lib/scene/battle/battle.dart 这是一个类似杀戮尖塔的玩法游戏场景。但做了一些修改，比如卡牌是用类似暗黑破坏神的词缀系统随机生成的 (数据 @scripts/main/cardgame/card.ht 主词缀 @assets/data/cards.json5 额外词缀 @assets/data/card_affixes.json5 )。卡牌脚本 @scripts/main/cardgame/card_script.ht, 状态数据：@assets/data/status_effect.json5 状态脚本 @scripts/main/cardgame/status_script.ht。另外以上这些都使用了本地化字符串，(@assets/locale/zh/rpg/)。 同时关于这些系统我也写了文档，位置在 @docs/docs/how2play/rpg/

请你理解现有设计，系统和代码，不用修改任何文件。如果你在梳理的过程中发现了问题，也可以暂时记录下来之后报告给我。

我正在重构各个流派的关键天赋，卡牌和装备，以形成各个流派的特色风味和玩法。设计文件在 @plan/skill_tree 下。目前我正在进行悟道流派的开发。 @plan/skill_tree/spellcraft.md 

我们目前已经完成了悟道流派的境界节点，分叉节点，主词条，额外词条，绝世卡牌的整理工作。

悟道流派绝世装备额外词条的相关内容也已汇总在 @plan/skill_tree/spellcraft.md。

---

绝世卡牌是一种特殊的卡牌，词条id是固定的。但目前我们除了手动生成，并没有获得绝世卡牌的方法。我们一方面要修改card.ht的代码，在随机获取主词条时判断绝世卡牌的特殊逻辑。另外我们也要修改cardpack的逻辑，以及 @lib/scene/card_library/ 中的逻辑，允许卡包中以较低概率 (0.8%左右，此概率应该保存为常量)开出绝世卡牌。需要检查绝世卡牌的rank，卡包是开不出来比自己境界高，或者和卡包本身的流派和种类不符的绝世卡牌的。

2，