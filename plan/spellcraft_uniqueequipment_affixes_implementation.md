# 悟道绝世装备额外词条实施方案

## 目标与现状

依据 `plan/spellcraft_uniqueequipment_affixes.md` 和 `plan/skill_tree/spellcraft.md`，完成 5 件悟道绝世装备各 5 条固定额外词条，保持最新定稿顺序，不改动流派效果与数值。

当前工作区只修改了 `items.json5` 的额外词条列表，且存在两个阻断问题：

1. 5 件装备原主词条被替换而非保留，导致主效果丢失、解锁窗口多算一条。
2. 10 条公共被动、5 个状态、4 个状态脚本及对应本地化尚未实现，当前有 13 个悬空被动引用。

另一个前置问题是：`createItemById` 只做 `item.level ??= level`，未传 level 时数值词条会执行 `getRandomLevel(minAffixLevel, null)`。原主词条都是机制型所以未暴露；加入 `spirituality` 等数值词条后必须先修复。

本方案不新增 Dart 战斗机制字段，但需要修改现有 Dart 观星入口以限制最多查看 5 张。所需 `battleStatus` / `statsBonus` / `turnStartExtraDraw` / `deckCostReduction` 均已在透传白名单和聚合、消费链路中实现；观星保留直接使用现有 `self_scry` 回调的 `details.chosen`。观星分工定为：天道推演等天赋提供触发源，装备提供观星深度与观星后修饰，不再由装备复制 `turnStartScry`。

## 阶段 0：修复物品等级与解锁前提

### `scripts/main/data/item/item.ht`

- 保留显式传入的 `level`。
- 当物品带 affixes 且 `item.level` 仍为 null 时，按物品 rank 调用：
  `getRandomLevel(minLevelForRank(item.rank), maxLevelForRank(item.rank))`。
- 在逐条 roll 词条前完成兜底；不改变显式 level 的既有行为，不为本批增加 clamp 或装备破境。
- 保持绝世装备生成规则：`min(affixes.length, rank + 1)`，列表含主词条。

验收：5 件装备不显式传 level 也能生成；数值词条 level 落在本境界区间，机制词条仍跳过 level roll。

## 阶段 1：限制观星上限并落地 5 个永久状态及脚本

### `lib/data/common.dart` / `lib/scene/battle/battle.dart`

- 在 `kScryCardCount` 附近新增 `kScryCardCountMax = 5`，作为所有观星入口共用的最终查看上限。
- `scry` 必须在合计基础数量、角色 `stats.scryBonus` 与 `options.scryBonus` 之后执行 `count = math.min(count, kScryCardCountMax)`，再按牌库剩余数计算 `actualCount`。
- 上限同时约束 `turnStartScry`、卡牌观星和其他调用方；空牌库仍在取牌前直接返回，不分发 `self_scry`。
- 当前 UI 已按 `actualCount` 动态布局，钳制后最多 5 张即可，不另做固定位置布局重写。
- 达到 5 张后额外 `scry_focus` 等深度加成饱和，不改为触发第二次观星，也不影响 `scry_retention` 等观星后修饰。

### `assets/data/status_effect.json5`

在「悟道绝世装备状态」区追加：

| 状态 | script / callback | 参数与行为 |
| --- | --- | --- |
| `scry_retention` | `scry_retention` / `self_scry` | 无额外参数；每回合首次观星后，选中牌获得保留 |
| `first_ailment_to_mana` | `first_ailment_to_mana` / `self_gained_debuff` | `resourceId: energy_positive_spell`；每回合首次元素异常获得事件 +1 灵气 |
| `turn_start_spell_mana_1` | 复用 `turn_start_mana_bonus` / `self_produce_resources` | `manaBonus: 1`；产出阶段 +1 灵气 |
| `mana_threshold_guard` | `mana_threshold_guard` / `self_taking_damage` | `resourceId: energy_positive_spell`、`threshold: 5`、`reductionPercent: 20`；达标受伤 -20% |
| `mana_empty_defend` | `mana_empty_defend` / `self_turn_end` | `resourceId: energy_positive_spell`、`defense: 8`；回合结束灵气为 0 时 +8 护甲 |

全部写 `isPermanent: true`，图标使用 `icon/status/permanent/<状态id>.png`。

### `scripts/main/cardgame/status_script.ht`

新增 4 个非 async 函数：

- `scry_retention_self_scry`
  - 用独立 `turnFlags` 标记保证每回合最多触发一次；额外回合按既有 turnFlags 重置规则重新计算。
  - 读取 `details.chosen`，设置 `details.chosen.isRetained = true`；空牌库不会分发 `self_scry`，无需补触发。
  - 多个 `scry_retention` 来源合并为同一状态，仍只保留本次观星选中牌，不叠加次数。
- `first_ailment_to_mana_self_gained_debuff`
  - 用 `Constants.elementAilments.values` 判定 `details.id` 是否元素异常。
  - 用独立 `turnFlags` 标记保证每回合最多触发一次；额外回合按既有 turnFlags 重置规则重新计算。
  - 通过 `effect.resourceId` 产 1 层资源，不在脚本写死资源 id。
- `mana_threshold_guard_self_taking_damage`
  - 灵气达到 `effect.threshold` 时，`details.percentageChange2 -= effect.reductionPercent / 100`，作为独立受伤乘区。
- `mana_empty_defend_self_turn_end`
  - 当前灵气为 0 时，`self.addStatusEffect('defense', amount: effect.defense)`。

`turn_start_spell_mana_1` 不新增脚本，复用现有产出阶段函数，确保灵气在清残留之后授予。

注意：`self_gained_debuff` 是获得事件回调，辟邪的 `cancelAmount` 在回调后结算。本批沿用该契约，不新增“辟邪结算后”时机；walkthrough 记录此语义，避免误称为“未被抵消才产能”。修正后层数 <=0 时 `addStatusEffect` 会提前返回，不触发回调。

### 图标与本地化

- 按 passive-status 规范，用 image-gen 的 Gemini + `--no-style` 生成 5 个无文字徽章，缩放为 150×150，并用 ReadMediaFile 检查小尺寸可辨性。
- `assets/locale/zh/rpg/status_effect.json`：补 5 组 `status_*` 名称与描述，写清触发时机和数值。

## 阶段 2：新增 10 条公共被动词条

### `assets/data/passives.json5`

放在绝世装备主词条区之后，priority 从 3487 起递减，避免与现有词条冲突。

B 层 2 条（进随机池）统一写 `isEquipmentExtraAffix: true`、`kinds: ["amulet", "ring", "pearl"]`：

| id | rank | 机制 |
| --- | --- | --- |
| `ailment_ward` | 2 | `statsBonus: {ailmentReceiveBonus: -1}` |
| `ailment_inflict_focus` | 2 | `statsBonus: {ailmentInflictBonus: 1}` |

C 层 8 条（可被固定列表/天赋引用，但不进随机池）不写用途标记：

| id | 机制 |
| --- | --- |
| `scry_focus` | `statsBonus: {scryBonus: 1}` |
| `scry_retention` | `battleStatus: scry_retention` |
| `ailment_to_mana_echo` | `battleStatus: first_ailment_to_mana` |
| `spell_mana_trickle` | `battleStatus: turn_start_spell_mana_1` |
| `non_spellcraft_tax` | `deckCostReduction: {color: all, amount: -1, notGenres: [spellcraft]}` |
| `spellcraft_cost_down` | `deckCostReduction: {color: spell, amount: 1, genres: [spellcraft]}` |
| `mana_threshold_guard` | `battleStatus: mana_threshold_guard` |
| `mana_empty_defend` | `battleStatus: mana_empty_defend` |

机制词条不写 increment，避免无意义的等级 roll；随机池按 id 自然去重，不额外制造 uniqueId 互斥组。

### `assets/locale/zh/rpg/passive.json`

补齐 10 条 `passive_<id>_description`。数值固定直接写清，不使用不存在的 `{0}` 占位；装备 flavortext 继续只描述主词条，额外词条由词条 UI 展示。

## 阶段 3：恢复主词条并组装 5 件装备

### `assets/data/items.json5`

只在当前列表首位恢复主词条，保留工作区最新额外词条顺序。每件 prototype 共 6 条（1 主 + 5 额外），生成时只解锁前 rank+1 条：

| 装备 | 完整 affixes 顺序 | 生成时生效 |
| --- | --- | --- |
| 窥天镜 | `heaven_peeking_mirror` → `spirituality` → `scry_focus` → `scry_retention` → `ailment_ward` → `ailment_to_mana_echo` | rank 1：主 + 前 1 条，共 2 条 |
| 五行珠 | `five_elements_pearl` → `spirituality` → `ailmentMultiplier` → `ailmentThreshold` → `ailment_inflict_focus` → `ailment_to_mana_echo` | rank 2：主 + 前 2 条，共 3 条 |
| 天机盘 | `turnStartExtraDraw` → `non_spellcraft_tax` → `scry_focus` → `scry_retention` → `deckMinSizeReduce` → `battleDrawBonus` | rank 3：主 + 前 3 条，共 4 条 |
| 蓄灵佩 | `energyRetainSpell` → `spirituality` → `lifeMax` → `persistent` → `basicEnergyBonus` → `spell_mana_trickle` | rank 4：主 + 前 4 条，共 5 条 |
| 聚灵旗 | `spirit_gathering_banner` → `spirituality` → `mana_threshold_guard` → `mana_empty_defend` → `spellcraft_cost_down` → `turnStartExtraDraw` | rank 5：主 + 5 条，共 6 条 |

聚灵旗槽位统一为：槽 4 `spellcraft_cost_down`、槽 5 `turnStartExtraDraw`。不实现装备破境，后续槽位按定稿休眠。

## 阶段 4：回归测试与文档同步

### 自动化测试

项目已有 Flutter/Hetu 测试，新增 `test/unique_equipment_test.dart`，直接执行真实 Hetu 状态脚本和物品生成路径，并为 Dart 观星数量钳制补充测试：

1. **生成与解锁**：5 件装备均不传 level 创建；断言主词条 id、实例词条总数和前 N 条顺序，prototype 仍保留完整 6 条。
2. **观星上限**：合计深度 6 且牌库不少于 6 张时只查看 5 张；合计深度超过牌库数时查看全部剩余牌；空牌库不展示也不分发 `self_scry`。
3. **观星保留**：同回合两次 `self_scry` 只处理第一次的选中牌；选中牌写入 `isRetained`；清理 turnFlags 后可再次触发。
4. **首次异常转灵气**：非元素 debuff 不触发；同回合两次元素异常只产 1 灵气；清理 turnFlags 后可再次触发。
5. **聚气成势**：灵气 4 不减伤，灵气 5 时乘区 2 为 -0.20。
6. **一炁**：回合结束灵气 0 获得 8 护甲，灵气非 0 不获得。
7. **灵气细流**：复用脚本在产出阶段获得 1 灵气。
8. **聚合组合**：两个 `scry_retention` 或 `ailment_to_mana_echo` 来源仍只触发一次；聚灵旗与天机盘的 `turnStartExtraDraw` count 合计为 2，costIncrease 不冲突。

若物品生成测试需要的完整游戏上下文过重，优先做真实 `createItemById` 的轻量 Hetu 测试夹具，不用仅检查 JSON 文本的测试代替。

### 文档

- `plan/spellcraft_uniqueequipment_affixes.md`：记录 level 兜底与完成状态。
- `plan/skill_tree/spellcraft.md`：将装备线待办更新为实际完成情况，保留装备破境、数值方差等后续风险。
- `plan/battle_system_overview.md`：更新 5 件装备已含固定额外词条的现状，并记录观星最多查看 5 张。
- 相关玩家与 mod 文档补充观星上限；无新 Dart 机制字段，因此不改 `_kPassiveMechanismFields`，也不需要扩展被动字段契约表或校验器字段形状。

## 阶段 5：验收

依次执行：

1. `flutter test`：全部测试通过，含新装备/状态与观星上限用例。
2. `dart run utils/data_validate/game_data_validate.dart`：本批 13 个悬空引用全部消失，校验达到 0 错误。
3. 使用本机绝对路径 `C:/Users/Administrator/AppData/Local/Dart/install/bin/hetu.bat` 编译 main/story；`python build.py` 的 PATH 失败不作为跳过编译的理由。
4. `flutter analyze`：无新增 error（当前 7 条既存 unnecessary_import info 分开报告）。
5. 战斗 walkthrough：
   - 窥天镜只有主词条 + spirituality，观星深度/自异常正确；高阶词条不误解锁。
   - 天道推演提供观星触发源时，`scry_focus` 正常增加深度；合计深度超过 5 时仍只展示 5 张，不发起第二次观星；`scry_retention` 每回合只令第一次观星的选中牌获得保留，装备不再额外发起回合开始观星。
   - 五行珠双向异常修正、异常伤害与阈值生效；与窥天镜同穿首次异常产能每回合一次。
   - 天机盘组牌课税与额外抽牌课税可叠加；纯悟道牌不受罚。
   - 蓄灵佩保留上限与纯粹伤害正确，spell_mana_trickle 仍休眠。
   - 聚灵旗 5 条全部生效；灵气 5 阈值减伤、灵气 0 护甲、悟道减费及与天机盘合计额外抽 2 张正确。
   - 普通随机装备只在指定 kind/rank 池中出现 B 层词条，C 层永不随机出现；穿脱后 stats 与 battleStatus 重算无残留。

## 明确不在本批范围

- 装备破境、重铸、低境界休眠词条提前解锁。
- 重新平衡现有 A 层词条的等级方差；先按定稿接受 roll，walkthrough 后再决定是否收敛。
- 为已有两个装备状态重制图标；本批只保证新增 5 个状态五层同步。
