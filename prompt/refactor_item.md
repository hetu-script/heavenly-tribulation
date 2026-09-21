这是当前游戏项目的装备系统： @scripts/main/data/item 主要用脚本写成。

文档在： @docs/docs/how2play/rpg/item/equipment 但文档可能不全或者和实现不一致

装备的词条在： @assets/data/passives.json5 装备和天赋树共享这些词条。

UI侧的装备显示和互动在： @lib/widgets/character 下包括 物品打造 item_craft.dart 以及物品和装备栏 stats_and_items.dart。

目前只是规划阶段，只需要理解现有系统，不要修改任何文件。如果在这个过程中你发现了某些错误，可以顺便暂时记录下来。
