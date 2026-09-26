@lib/scene/battle/battle.dart 这是一个类似杀戮尖塔的玩法游戏场景。但我做了一些修改，比如每张卡牌都是用类似暗黑破坏神的词缀系统随机生成的 (数据 @scripts/main/cardgame/card.ht 主词缀 @assets/data/cards.json5 额外词缀 @assets/data/card_affixes.json5 )。卡牌脚本 @scripts/main/cardgame/card_script.ht, 状态脚本 @scripts/main/cardgame/status_script.ht。另外以上这些都使用了本地化字符串，(@assets/locale/zh/rpg/)。 同时关于这些系统我也写了文档，位置在 @docs/docs/how2play/rpg/

这些文档可以让你从总体上理解本项目。目前只是规划阶段，只需要理解现有系统，不要修改任何文件。

---

目前我有几个需求：

1, 绝世卡牌是一种特殊的卡牌，词条id是固定的。但目前我们除了手动生成，并没有获得绝世卡牌的方法。我们一方面要修改card.ht的代码，在随机获取主词条时判断绝世卡牌的特殊逻辑。另外我们也要修改cardpack的逻辑，以及 @lib/scene/card_library/ 中的逻辑，允许卡包中以较低概率 (0.5%左右)开出绝世卡牌。需要检查绝世卡牌的rank，卡包是开不出来比自己境界高的绝世卡牌的。

2，

---

@plan/battle_card_equipment_overview2.md 这个文档可以让你从总体上理解本项目中和卡牌战斗有关的部分。目前你只需要理解现有系统，不要修改任何文件。稍后我会发给你更具体的指示。

请留意 battlecard-content 这个 skill 稍后可能会有相关的任务和它有关。

---

目前我正在重构各个流派的关键天赋，卡牌和装备，以形成各个流派的特色风味和玩法。设计文件在 @plan/skill_tree 下。目前我正在进行悟道。 @plan/skill_tree/spellcraft.md

目前我已经完成了境界节点，分叉节点的工作。

目前正在计划进行悟道流派主词条整理。 @plan/skill_tree/spellcraft_main_affix_rework.md

请阅读相关文档。如果你准备好执行 @plan/skill_tree/spellcraft_main_affix_rework.md 的话，告诉我。另外，执行中遇到任何不缺定的问题都可以先问我。
