@lib/scene/battle/battle.dart 这是一个类似杀戮尖塔的玩法游戏场景。但我做了一些修改，比如每张卡牌都是用类似暗黑破坏神的词缀系统随机生成的 (数据 @scripts/main/cardgame/card.ht 主词缀 @assets/data/cards.json5 额外词缀 @assets/data/card_affixes.json5 )。卡牌脚本 @scripts/main/cardgame/card_script.ht, 状态脚本 @scripts/main/cardgame/status_script.ht。另外以上这些都使用了本地化字符串，(@assets/locale/zh/rpg/)。 同时关于这些系统我也写了文档，位置在 @docs/docs/how2play/rpg/battle/

这些文档可以让你从总体上理解目前我设计的这个游戏框架。目前只是规划阶段，只需要理解现有系统，不要修改任何文件。（文档可能和实际代码不符，以实际代码为准，但文档也可能包含了未实现的功能）

目前我有几个需求：

1, 绝世卡牌是一种特殊的卡牌，词条id是固定的。但目前我们除了手动生成，并没有获得绝世卡牌的方法。我们一方面要修改card.ht的代码，在随机获取主词条时判断绝世卡牌的特殊逻辑。另外我们也要修改cardpack的逻辑，以及 @lib/scene/card_library/ 中的逻辑，允许卡包中以较低概率 (0.5%左右)开出绝世卡牌。需要检查绝世卡牌的rank，卡包是开不出来比自己境界高的绝世卡牌的。

2，
