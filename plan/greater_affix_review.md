# 太古词条重构审查记录

> 本文是对 `plan/greater_affix_rework.md`、`plan/greater_affix_content_design.md` 与 `plan/exp_array_greater_affix_rework.md` 的只读审查结论。
> 审查时未修改实现、数据或文档；本文仅保存结论，供后续修正使用。

## 1. 总体结论

重构方向正确，基础架构值得保留，但当前不宜判定为“已完成验收”。

“最多 3 条额外词条＋太古不占槽位＋显式 `greater` 配置＋按来源聚合”能够解决词条过多、主词条辨识度下降和统一倍率误伤机制的问题。临时增益计划采用待生效配置和事务式提交，整体设计也基本合理。

在将相同模式复制到御剑及其他流派前，应优先处理下列高优先级问题。

## 2. 高优先级问题

### 2.1 低境界绝世装备的后续太古成长目前不可达

`createItemById` 对非 `isRankedItem` 原型忽略传入的 `rank`，只使用原型自身境界，见 `scripts/main/data/item/item.ht:129-153`。同时当前计划明确不实现装备破境。

因此：

- 窥天镜、五行珠：永远没有太古；
- 天机盘：只能获得 rank 3 的第一条太古；
- 蓄灵佩：只能获得 rank 3、4 的两条太古；
- 只有聚灵旗能直接得到全部三条太古。

`test/unique_equipment_test.dart:138-144` 的预期也反映了这一现状：窥天镜和五行珠的太古数量均为 0。

后续需要明确选择一种处理方式：

1. 允许绝世装备按指定 rank 直接生成，并提供实际获取途径；
2. 实现装备升境；
3. 若刻意留待以后，则将文档和完成状态标为“尚未开放”，不按完整成长验收。

### 2.2 窥天镜的 `scry_upgrade` 太古在完整链路中不会生效

`scry_upgrade` 当前配置顶层 `greater.data.upgradeChosen`，见 `assets/data/passives.json5:1539-1546`。

被动聚合只把 `statusParams` 传入 `battleStatusParams`，见 `scripts/main/data/character/battle_entity.ht:415-435`。顶层 `upgradeChosen` 不会传给状态实例，状态因此继续使用默认值 1，见 `assets/data/status_effect.json5:906-914`。

实际结果是：卡面写“等级 +2”，实际仍然只升 1 级。

建议统一改用 `statusParams.upgradeChosen`，并补充“装备生成 → 被动聚合 → 状态实例 → 观星升级”的端到端测试。现有测试只直接给状态脚本传入 2，没有覆盖中间链路。

### 2.3 `scry_focus` 在窥天镜上确定没有实际效果

当前规则：

- 普通观星基础查看 3 张；
- 最终最多查看 5 张，见 `lib/data/common.dart:1271-1274`；
- 窥天镜主词条已经提供 `scryBonus: 2`，见 `assets/data/passives.json5:1434-1439`。

装备窥天镜后，普通观星已经固定达到 5 张上限。`scry_focus` 的 +1 以及太古后的 +2 都不会再改变实际查看数。

这不是收益较低，而是该固定词条在当前内容中始终无效。需要重新分配这个槽位，或共同调整主词条深度与观星上限。

## 3. 其他实现偏差

### 3.1 混元会阻断纯机制词条的太古判定

`rerollAffix` 在没有任何带 `valueData` 的可变额外词条时提前返回，见 `scripts/main/cardgame/card.ht:646-664`。

因此，只带属性增伤等纯机制词条的卡，无法执行计划规定的“重随后进行一次 5% 太古判定”。提前返回条件不应阻止合法太古候选继续判定，并应补充对应测试。

### 3.2 五条属性增伤太古的卡面数值错误

身法、体魄、念力、神识、灵力五条词条实际从每点 0.5% 提升到 0.75%，但没有配置 `greater.description`，卡面仍显示 0.5%，见 `assets/locale/zh/rpg/battlecard.json:308-312`。

这也影响即将实施的御剑词条，需要同步更新御剑设计说明。

## 4. 数值与内容风险

天机盘的两条太古不是必然无效，但倍率收益经常被实际上限吞噬：

- `battleDrawBonus`：基础抽牌已是 5，手牌上限通常为 10。高等级普通词条和太古都远超剩余手牌空间，×1.5 经常不产生额外抽牌。
- `deckMinSizeReduce`：rank 3 的基准牌库下限为 16，绝对下限为 5。普通词条等级较高时已经触底，太古继续 ×1.5 没有差异。

太古时的“自动满级”仍可能让低 roll 词条获得提升，所以不能称为全场景无效；但“×1.5”并不代表稳定的实战收益。

后续验收应比较普通与太古经过手牌、牌库、观星等上限截断后的最终效果，而不只比较原始数值。

## 5. 对临时增益计划的评价

`plan/exp_array_greater_affix_rework.md` 的整体方案合理：

- 战前配置与 `standalone` 分离，避免误删渡劫减难等独立效果；
- 聚灵阵先构建待生效配置，最终确认后再提交；
- 仅主词条丹药保留旧配置；
- 同批去重、定向凝炼、失败保留旧配置，规则闭环完整。

实施时最关键的是显式整理来源分类。当前被动数据没有现成的 `isPermanent` 内容标记，不能仅凭文档所称“永久效果”推定来源已正确分类。丹药、聚灵阵、直接服用的打造材料都应在接入前确定 `ephemeralScope` 和永久语义。除此之外，不需要改变总体设计。

## 6. 文档与验证

仍有以下旧规则残留：

- `docs/docs/how2play/rpg/battle/readme.md:49`：仍写绝世卡额外词条等于境界、化神 5 条；
- `docs/docs/mod/battle/readme.md:189-190`：同样保留旧规则；
- `.agents/context/battle_system.md:156`：仍称太古未实现、词条数为旧公式；
- `assets/locale/zh/rpg/item.json:142`：灵宝丹仍写每境界增加词条上限；
- `assets/data/passives.json5:1430`：注释仍写绝世装备额外词条等于 rank。

审查时执行结果：

- `dart run utils/data_validate/game_data_validate.dart`：通过，0 错误、0 提示；
- `flutter test test/card_affix_test.dart test/greater_item_test.dart test/passive_aggregation_test.dart test/unique_equipment_test.dart`：30 个测试全部通过；
- 未进行游戏内战斗和打造的人工端到端验收。

## 7. 建议修正顺序

1. 解决绝世装备成长可达性、`scry_upgrade` 聚合链路和窥天镜无效词条；
2. 修复混元提前返回与五条属性增伤文案；
3. 重新审核受手牌、牌库和其他系统上限影响的太古收益；
4. 同步残留文档并补充端到端测试；
5. 完成上述修正后，再将这些规则作为御剑及其他流派的模板。
