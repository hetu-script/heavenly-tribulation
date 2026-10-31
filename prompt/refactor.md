@.agents/context/battle_system.md 这个文档可以让你从总体上理解本项目中和战斗有关的部分。

@lib/scene/battle/battle.dart 这是一个类似杀戮尖塔的玩法游戏场景。但做了一些修改，比如卡牌是用类似暗黑破坏神的词缀系统随机生成的 (数据 @scripts/main/cardgame/card.ht 主词缀 @assets/data/cards.json5 额外词缀 @assets/data/card_affixes.json5 )。卡牌脚本 @scripts/main/cardgame/card_script.ht, 状态数据：@assets/data/status_effect.json5 状态脚本 @scripts/main/cardgame/status_script.ht。另外以上这些都使用了本地化字符串，(@assets/locale/zh/rpg/)。 同时关于这些系统我也写了文档，位置在 @docs/docs/how2play/rpg/

我正在重构各个流派的关键天赋，卡牌和装备，以形成各个流派的特色风味和玩法。设计文件在 @plan/skill_tree 下。

我们目前已经完成了悟道流派（spellcraft）的境界节点词条和关键分叉节点词条，流派卡牌的主词条和额外词条，绝世卡牌和绝世装备的整理工作。但目前尚未给技能树节点分配词条。接下来我们原本要设计御剑流派（swordcraft），御剑的计划文档也已经近乎整理完毕，只是尚未实施。而其他三个流派的计划尚处于草案，也未有任何代码实现。

但在设计各个流派的过程中，我有一些新想法，打算重构目前的词条系统。目前我准备了几个新计划，分别是 @plan/greater_affix_rework.md 和 @plan/greater_affix_content_design.md 以及 @plan/exp_array_greater_affix_rework.md。

目前 @plan/greater_affix_rework.md 和 @plan/greater_affix_content_design.md 这两个文档的内容已经完成。

关于本次修改。之前已经做了审核，发现了一些问题，记录在： @plan/greater_affix_review.md 中，我们现在的任务是解决这些问题。

请理解现有设计，系统和代码，给出你的意见，暂时不用修改任何文件，但可以补充意见文档，如果你认为还有一些决策需要我的意见，可以告诉我。

---

绝世卡牌是一种特殊的卡牌，词条id是固定的。但目前我们除了手动生成，并没有获得绝世卡牌的方法。我们一方面要修改card.ht的代码，在随机获取主词条时判断绝世卡牌的特殊逻辑。另外我们也要修改cardpack的逻辑，以及 @lib/scene/card_library/ 中的逻辑，允许卡包中以较低概率 (0.8%左右，此概率应该保存为常量)开出绝世卡牌。需要检查绝世卡牌的rank，卡包是开不出来比自己境界高，或者和卡包本身的流派和种类不符的绝世卡牌的。

---

单一卡组问题

哪些词条没有太古选项？

关于hetu初始化时的特殊配置，是否要写在AGENTS.md里面，避免之后写测试时候踩坑？

删除除了破镜丹之外，直接服用打造材料时的效果。

主词条残留的太古数据