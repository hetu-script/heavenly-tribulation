@plan/demo_scope.md 这是当前项目 Demo 目标的总体定位、范围与边界

---

@.agents/context/battle_system.md 这个文档可以让你从总体上理解本项目中和战斗有关的部分。

@lib/scene/battle/battle.dart 这是一个类似杀戮尖塔玩法的游戏。但做了一些扩展，比如卡牌是用类似暗黑破坏神的词缀系统随机生成的 (数据 @scripts/main/cardgame/card.ht 主词缀 @assets/data/cards.json5 额外词缀 @assets/data/card_affixes.json5 )。卡牌脚本 @scripts/main/cardgame/card_script.ht, 状态数据：@assets/data/status_effect.json5 状态脚本 @scripts/main/cardgame/status_script.ht。另外以上这些都使用了本地化字符串，(@assets/locale/zh/rpg/)。 同时关于这些系统我也写了文档，位置在 @docs/docs/how2play/rpg/

我正在重构各个流派的关键天赋，卡牌和装备，以形成各个流派的特色风味和玩法。设计文件在 @plan/skill_tree 下。

我们目前已经完成了悟道流派（spellcraft）的境界节点词条和关键分叉节点词条，流派卡牌的主词条和额外词条，绝世卡牌和绝世装备，以及中立（neutral）流派的绝世卡牌和绝世装备的整理工作。

---

这是当前的装备系统： @scripts/main/data/item 主要用脚本写成。

文档在： @docs/docs/how2play/rpg/item/equipment 但文档可能不全或者和实现不一致

装备的词条在： @assets/data/passives.json5 装备和天赋树共享这些词条。

物品打造： @lib/widgets/view/workshop.dart

UI侧的装备显示和互动在： @lib/widgets/character 下，包括物品和装备栏 stats_and_items.dart。

---

@lib/scene/cultivation/cultivation.dart 这是一个用于角色升级，天赋树，聚灵阵和打坐的共用场景。但目前我们只针对天赋树部分代码进行重构。

天赋树节点的词条定义在： @assets/data/passives.json5 （和装备词条共用），天赋树的节点形状则定义在 @assets/data/passive_skills.json5 里面。

玩家从最小的圆的五个节点出发（代表游戏中的五种流派），然后通过连接线进入下一个节点，直到最外层的节点。

每个节点可能有也可能没有挂载词条，词条定义在 @assets/data/passives.json5 中。这些词条和另外的装备系统的词条共享。

没有挂载词条的节点则会提供基础属性加成，玩家可以从五种属性中选择一个。

关于修炼，文档在 @docs/docs/how2play/rpg/cultivation/ 目录中，但目前文档也可能和实际实现不一致。

每种流派会提供四种不同的构筑思路，分别从境界节点所在的主线上，向左或者向右分支。同时相邻的流派会共享这个构筑思路。

按照顺时针，分别是：御剑，悟道，炼魂，法身，锻体。

玩家可以自由决定怎么加点。但NPC其实是从一个固定的加点路线随机选择的。定义在 @lib/data/common.dart 中的 kCultivationRankPaths 里面。由 \_characterAllocateSkills 调用并自动分配。

目前我正在分配天赋树节点功能和连线。暂时只完成了悟道主轴以及相关支线。

---

目前御剑的计划文档已经近乎整理完毕，只是尚未实施。而其他三个流派的计划尚处于草案，也未有任何代码实现。

在设计其他流派之前，我们还需要完善悟道的天赋树，并先以悟道这单独一个流派出发。跑通一个地牢秘境玩法的完整循环。

秘境玩法的计划是： @plan/scene_chain_dungeon.md 
秘境卡组锁定、卡牌生命周期与永久卡库的相关约定： @plan/dungeon_deck_lock.md
后续可选的格子房间扩展： @plan/grid_dungeon.md

---

请理解现有设计，系统和代码，如果你感觉之前的代码，文档，数据有问题，也可以给出你的意见，不过暂时不用修改任何文件。

因为这个项目比较复杂，你当下可以不用深入各个系统的具体实现细节。只是从总体上了解项目的结构和代码、数据、脚本的关系等等。如果你认为有必要深入了解的也可以现在看看。

之后我可能对这整个项目的一些细节，或者设计提问。

---

绝世卡牌是一种特殊的卡牌，词条id是固定的。但目前我们除了手动生成，并没有获得绝世卡牌的方法。我们一方面要修改card.ht的代码，在随机获取主词条时判断绝世卡牌的特殊逻辑。另外我们也要修改cardpack的逻辑，以及 @lib/scene/card_library/ 中的逻辑，允许卡包中以较低概率 (0.8%左右，此概率应该保存为常量)开出绝世卡牌。需要检查绝世卡牌的rank，卡包是开不出来比自己境界高，或者和卡包本身的流派和种类不符的绝世卡牌的。

