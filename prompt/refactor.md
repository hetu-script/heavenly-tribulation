@lib/scene/battle/battle.dart 这是一个类似杀戮尖塔的玩法游戏场景。但我做了一些修改，目前敌人和玩家是平等的，都有自己的卡牌库，也会有类似的流程（具体流程参考 @docs/docs/mod/battle/readme.md) 。在此之外，我还构建了一个更复杂的框架，用来让这个战斗作为一个此项目的更大的框架的一部分。比如每张卡牌都是用类似暗黑破坏神的词缀系统随机生成的 (卡牌脚本数据 @scripts/main/cardgame/card.ht 主词缀 @assets/data/cards.json5 额外词缀 @assets/data/card_affixes.json5 )。而且玩家还可以像流放之路那样打造卡牌。另外，玩家还有一个装备系统，装备本意是提供卡牌之外的永久性加成，类似流放之路中的神器。但目前这个基础设计中的装备只是提供了一些简单的属性。同时，角色本身还有装备 ( @scripts/main/data/item/equipment.ht ) ，装备和角色天赋以及丹药等其他系统（在本次探讨中暂时先略过天赋树等其他部分）共享一部分词条 (@assets/data/passives.json5 )，另外以上所有这些系统，都使用了本地化字符串，具体字符串保存在@assets/locale/ 中。另外还有装备属性显示(@lib/widgets/character/stats.dart) 同时关于这些系统我也写了文档，位置在 @docs/docs/how2play/rpg/battle/ （文档中也提到了一些尚未落地的设计） 这些文档可以让你从总体上理解目前我设计的这个游戏框架。

不久前，我刚刚对战斗，卡牌，被动词条进行了一次整体refactor，修改了许多方面的内容。请你帮我整体检查一下。主要检查下面这些文件：

@assets/data/cards.json5
@assets/data/card_affixes.json5
@assets/data/status_effect.json5
@assets/data/passives.json5

以及他们的数据中引用的本地化文件：

@assets/locale/zh/rpg/battlecard.json
@assets/locale/zh/rpg/status_effect.json
@assets/locale/zh/rpg/passive.json

以及脚本文件：

@scripts/main/cardgame/card_script.ht
@scripts/main/cardgame/status_script.ht

请先不要修改任何任何文件，只需要理解现有系统，并指出你发现的潜在的错误。

之后我们会针对战斗相关系统进行一些修改。
