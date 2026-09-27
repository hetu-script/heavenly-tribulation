@lib/scene/battle/battle.dart 这是一个类似杀戮尖塔的玩法游戏场景。但我做了一些修改，比如每张卡牌都是用类似暗黑破坏神的词缀系统随机生成的 (数据 @scripts/main/cardgame/card.ht 主词缀 @assets/data/cards.json5 额外词缀 @assets/data/card_affixes.json5 )。卡牌脚本 @scripts/main/cardgame/card_script.ht, 状态脚本 @scripts/main/cardgame/status_script.ht。另外以上这些都使用了本地化字符串，(@assets/locale/zh/rpg/)。 同时关于这些系统我也写了文档，位置在 @docs/docs/how2play/rpg/

这些文档可以让你从总体上理解本项目。目前只是规划阶段，只需要理解现有系统，不要修改任何文件。

---

目前我有几个需求：

1, 绝世卡牌是一种特殊的卡牌，词条id是固定的。但目前我们除了手动生成，并没有获得绝世卡牌的方法。我们一方面要修改card.ht的代码，在随机获取主词条时判断绝世卡牌的特殊逻辑。另外我们也要修改cardpack的逻辑，以及 @lib/scene/card_library/ 中的逻辑，允许卡包中以较低概率 (0.5%左右)开出绝世卡牌。需要检查绝世卡牌的rank，卡包是开不出来比自己境界高的绝世卡牌的。

2，

---

@plan/battle_card_equipment_overview2.md 这个文档可以让你从总体上理解本项目中和卡牌战斗有关的部分。目前你只需要理解现有系统，不要修改任何文件。稍后我会发给你更具体的指示。同时也请留意 battlecard-content 这个 skill 稍后的任务会和它有关。

我们目前正在进行各个流派的重构，包括天赋树，卡牌词条，装备等等。

相关计划在 @plan/skill_tree/ 下。

目前我们正在进行悟道流派，spellcraft.md。

目前我们已经完成了境界节点，分支节点，以及流派主词条的整理和设计。现在我们准备进行额外词条的设计。我们需要单独为这个步骤写一个计划。

---

@plan/battle_card_equipment_overview2.md 这个文档可以让你从总体上理解本项目中和卡牌战斗有关的部分。目前你只需要理解现有系统，不要修改任何文件。稍后我会发给你更具体的指示。同时也请留意 battlecard-content 这个 skill 稍后的任务会和它有关。

目前我正在重构各个流派的关键天赋，卡牌和装备，以形成各个流派的特色风味和玩法。设计文件在 @plan/skill_tree 下。目前我正在进行悟道流派的开发。 @plan/skill_tree/spellcraft.md

目前我已经完成了悟道流派的境界节点，分叉节点，主词条和额外词条的整理工作。请阅读相关文档。并审查现有代码。理解相关流程。

在这个过程中，如果你认为有任何bug可以记录下来，另外如果有值得补充进入玩法文档 @docs/docs/how2play/rpg/battle/card/readme.md 的内容可以记录下来。有值得补充进入模组开发文档 @docs/docs/mod/battle/card/readme.md 的脚本细节也可以记录下来。


---

在生成卡牌主词条之前，我们需要为每个新的主词条增加卡牌插画，可以调用 skill 完成，注意同步更新 kBattleCardIllustrations 以及 battlecard.json 本地化文件中的 illustration_xxx 系列。这两个和新插画有关的操作也可以同步到 battlecard-content skill 中，我之前写那个skill时候漏了。以后只要创建了新插画，都要同步这两个地方。
