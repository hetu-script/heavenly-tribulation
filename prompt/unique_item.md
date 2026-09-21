这是当前游戏项目的装备系统： @scripts/main/data/item 主要用脚本写成。

文档在： @docs/docs/how2play/rpg/item/equipment 但文档可能不全或者和实现不一致

装备的词条在： @assets/data/passives.json5 装备和天赋树共享这些词条。

UI侧的装备显示和互动在： @lib/widgets/character 下包括 物品打造 item_craft.dart 以及物品和装备栏 stats_and_items.dart。

最近我正在重构天赋树，但在那之前，我打算加入一个之前尚未实现的设计，那就是绝世装备。绝世装备和绝世卡牌类似，词条是固定的，并且同种类的绝世装备身上只能装备一件（绝世卡牌在卡组中也只能有一张）。目前确实有一个预定义的物品数据文件： @assets/data/items.json5 脚本中的 createItemById 可以利用这些数据创造物品。请检查如果要创造绝世装备，目前的这个数据形式和接口是否够用？

目前只是规划阶段，不要修改任何文件。