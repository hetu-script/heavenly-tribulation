# 战斗系统遗留问题修复计划

范围：额外回合机制断裂、rankIncrement 未实现、护甲保持/护甲穿透结算、increase_damage_\* 生效路径、辟邪按层抵消。
前置共识（已与作者确认）：

- rankIncrement 语义：词条数值随**境界**缩放，`rankIncrement × rank`，化神（rank 5）时为 5 倍；适用于卡牌词条与装备/物品/丹药词条；**天赋树节点不用 rankIncrement**（规则已记录于 `DESIGN_NOTE.md`）。
- persistent（护甲保持）与 penetration（护甲穿透）由丹药/装备获取、常驻，战斗开始后像攻击力一样显示为**永久状态图标**（状态条目与美术已就绪）；因无反面效果，不放入 `kStatsToPermanentEffects`，在 `_prepareBattleStart` 单独处理。护甲保持**每层 +1%**。
- increase_damage_\* 走与攻击力（enhance）相同的管线：属性 → 战斗开始永久状态图标（美术已就绪）。
- critThreshold/ailmentThreshold 只出现在装备（isEquipmentExtraAffix），不出现在临时增益（无 isEphemeral），属有意设计。

---

## 任务一：额外回合（速度阈值）机制修复

**现状**：`speed_quick_self_turn_end` 在 `onEndTurn` 中才写入 `turnFlags.extraTurn`，但 `battle.dart` 只在敌方出牌循环内（`lib/scene/battle/battle.dart:1219`，早于 `onEndTurn`）读取它，英雄分支完全不读；`do {} while(extraTurn)` 的局部变量永远为 false，额外回合永不触发。

**修改**（仅 `lib/scene/battle/battle.dart` `_startTurn`）：

1. 删除敌方出牌循环内的死代码（`:1219-1221` 的 extraTurn 检查）。
2. 在 `await currentCharacter.onEndTurn();`（`:1229`）之后、`_startTurn` 的 do-while 末尾判定前插入：

```dart
if (currentCharacter.turnFlags['extraTurn'] == true) {
  extraTurn = true;
}
```

**行为说明**（与 `docs/docs/mod/battle/readme.md` 第 20 行"额外回合重复 2-9"一致）：

- 额外回合重复整个 do 循环体：摸牌 → `onStartTurn(isExtra: true)` → 资源清空/产出 → 出牌 → `onEndTurn` → 弃牌。摸牌必须包含（否则空手直接结束回合，额外回合无意义）。
- `onStartTurn` 会清空 turnFlags，标记不会泄漏到再下一回合。
- 链式可行：速度 25 / 阈值 10 → 每次回合结束消耗 10 层，可连续获得额外回合。
- 额外回合同样触发 `turn_end_resource_settlement` 与资源产出，属预期（readme 既定行为）。
- 无需改动 `status_script.ht` 与 readme（readme 描述的即目标行为）。

---

## 任务二：rankIncrement 实现

**统一公式**（当前数据中无 increment 与 rankIncrement 混用的条目）：

```
value = (base ?? 0) + (increment ?? 0) × level + (rankIncrement ?? 0) × rank
```

**建议**：在 `scripts/main/data/common.ht` 抽一个公共函数（如 `calcAffixValue(affix, {level, rank})`），供下列各点调用，消除现有的 5 处复制粘贴。

**修改点**：

| 位置 | 用途 | rank 来源 |
| --- | --- | --- |
| `scripts/main/cardgame/card.ht` `_updateAffixValue`（:236）、`_randomizeAffixLevel`（:261） | 卡牌主/额外词条 | `affix.rank`（主词条=卡牌境界；额外词条=其隐藏境界；`upgradeRank`/reroll 已重算，自动正确） |
| `scripts/main/data/item/equipment.ht` 主词条（:83-92）、额外词条（:123-131） | 装备词条 | 装备 `this.rank` |
| `scripts/main/data/item/item.ht`（:137-145） | 通用物品词条 | `item.rank` |
| `scripts/main/data/item/usable.ht` 主词条（:176-184）、额外词条（:211-219） | 丹药词条 | 物品 `this.rank` |
| `scripts/main/data/character/battle_entity.ht` `characterSetPassive`（:456-499） | 天赋 | `character.rank`（防御性实现，见下） |
| 同文件 `characterSetEphemeralPassive`（:733-755） | 临时增益（丹药/聚灵阵） | `character.rank`（防御性实现，见下） |

**设计规则（已写入 `DESIGN_NOTE.md`）**：rankIncrement 词条不得出现在天赋树节点上——天赋数值在学习时按当时境界烘焙，升境后不刷新，会产生陈旧数值。天赋树只用 `increment` 词条。上表后两处的 rankIncrement 支持仅作防御性实现（防止未来误配时静默得到 0 值），当前数据不会走到。

**验证数据**：

- `cards.json5` energy_positive_life（rankIncrement 2 → rank 1 时元气 +2）；energy_positive_spell/weapon/unarmed/ultimate（base 1 + rankIncrement 1 → rank 1 时 +2）。
- `card_affixes.json5` energy_positive_life（rankIncrement 1）。
- `passives.json5` 四个行动阈值（rankIncrement ±1 → 最高境界 ±5，不越上下限）、critThreshold/ailmentThreshold（rank 3+ → -3 起）。

**顺手修的小数据错**（本轮新发现）：

- `passives.json5` slowThreshold 的 description 误用 `passive_quick_threshold_description`（locale 中 `passive_slow_threshold_description` 已存在）。（阈值被动的 keywords 问题作者已修复。）

---

## 任务三：护甲保持 / 护甲穿透显示为永久图标并正确结算

**前提（作者已改）**：persistent / penetration 状态条目已恢复（`status_effect.json5:324-339`，永久图标、无脚本），美术已就绪。两者没有对应的反面效果，因此**不放入 `kStatsToPermanentEffects`**，在 `_prepareBattleStart` 中单独处理。

**战斗开始授予图标**（`lib/scene/battle/battle.dart` `_prepareBattleStart`，:193）：

1. `scripts/main/data/character/battle_entity.ht` `characterCalculateStats` 补充 `character.stats.persistent`（`stats.penetration` 在 :356 已有）：
   `character.stats.persistent = character.passives.persistent?.value + character.ephemeralPassives.persistent?.value`
2. `_prepareBattleStart` 在现有 kStatsToPermanentEffects 循环之后单独处理（与 enhance 相同的"属性 → 永久图标"管线，只是没有负面对）：

```dart
for (final statName in ['persistent', 'penetration']) {
  final int value = character.data['stats'][statName] ?? 0;
  if (value > 0) {
    character.addStatusEffect(statName, amount: value, handleCallback: false);
  }
}
```

**护甲保持结算**（`scripts/main/cardgame/status_script.ht` `defense_self_turn_start`，:151）：

- 每层 +1%（注意：从旧设计的 5% 改为 1%，locale 已是 1% 文案）：
  `reserved = 0.5 + min(persistent, 50) × 0.01`（50 层 = 100% 保留，cap 1.0）；
- `persistent` 继续读 `hasStatusEffect('persistent')`（状态已恢复，图标即真值）；
- 删除 `self.removeStatusEffect('persistent', amount: amount)`——常驻效果不消耗；
- `turnFlags.defensePersisted` 条件维持 `persistent > 0`。

**护甲穿透结算**（`lib/scene/battle/character.dart` `takeDamage`）：

- 合并 cardFlags 修正后增加：
  `damageDetails['penetration'] += opponent!.hasStatusEffect('penetration') * 0.01;`
  （每层 1%；护甲分支已有 0~1 clamp，只作用于物理/真气，真气自带 0.5，逻辑不变。）
- penetration 状态保持无脚本（与 enhance 的"结算收敛进 takeDamage、图标即真值"一致）；删除 `status_script.ht` 中已无注册者的 `penetration_self_doing_damage`（:92-95）。

**清理**：

- `lib/scene/battle/battle.dart` `kStatusOnCircumstance` 中的 `'penetration'` 移除（没有对应的 `start_battle_with_penetration` 被动，死条目）。
- （可选）penetration 被动增加 `isPotionMain: true`，使其也能作为丹药主词条（目前只能作丹药额外词条）。
- 更新 `docs/docs/mod/battle/readme.md` damageDetails 表：penetration 行注明来源为攻击方 penetration 状态（由属性转换）。

---

## 任务四：increase_damage_\* 接入永久状态图标（与攻击力同管线）

**管线**：被动（装备/天赋）→ `stats.increase_damage_X` → 战斗开始 `_prepareBattleStart` 转换为永久状态图标 → 状态脚本 `increase_damage_self_doing_damage` 生效（脚本与 callbacks 已就绪，无需新增）。

1. `scripts/main/data/character/battle_entity.ht` `characterCalculateStats`：为全部 17 个 kind 增加
   `character.stats.increase_damage_X = character.passives.increase_damage_X?.value + character.ephemeralPassives.increase_damage_X?.value`。
   建议用循环 + kind 常量列表（punch, kick, qinna, dianxue, sword, sabre, spear, staff, bow, dart, firebend, airbend, waterbend, earthbend, lightning_control, sigil, power_word），避免 17 行复制。
2. `lib/scene/battle/battle.dart` `_prepareBattleStart`：increase_damage 同样没有反面效果，**不放入 `kStatsToPermanentEffects`**，与任务三的 persistent/penetration 共用单独处理循环——对 `stats` 中 `increase_damage_` 前缀的键，值 > 0 时授予同名状态（`handleCallback: false`）。
3. 修 `status_effect.json5:206`：increase_damage_waterbend 的 description 误指 `status_increase_damage_earthbend_description`。
4. **kind 匹配问题**：`increase_damage_self_doing_damage` 按 `details.kind` 精确匹配，而御剑术卡的 kind 是 `flying_sword`，"剑法和御剑术伤害增加"覆盖不到。方案：状态数据增加可选 `kinds` 列表（sword 条目配 `kinds: ["sword", "flying_sword"]`），脚本改为优先按 `effect.kinds.contains(details.kind)` 判断、回退 `effect.kind`。
5. 数值单位：装备/丹药侧 value 已 floor/round 为整数，1 层 = 1%，与描述一致 ✓。

---

## 任务五：辟邪（buff_ward）按层抵消

**现状**：1 层辟邪即取消整次 debuff 获得（无论叠几层），与描述"每层辟邪抵消 1 层负面效果"不符。

**修改**：

1. `lib/scene/battle/character.dart` `addStatusEffect` 的 isDebuff 分支（:593-610）：
   - `debuffDetails` 增加入参 `{'id': id, 'amount': amount}`；
   - 回调后读取 `cancelAmount`（int，出参；保留对旧 `cancelDebuff == true` 的兼容，视为 `cancelAmount = amount`）；
   - `removed = min(cancelAmount, amount)`，执行 `removeStatusEffect(id, amount: removed)`；
   - `gained_debuff_affect_opponent` 的传播量改为 `amount - removed`（>0 才传播）。
2. `scripts/main/cardgame/status_script.ht` `buff_ward_self_gained_debuff` 改为：

```
final ward = self.hasStatusEffect(effect.id)
if (ward <= 0) return
final canceled = Math.min(ward, details.amount)
details.cancelAmount = (details.cancelAmount ?? 0) + canceled
self.removeStatusEffect(effect.id, amount: canceled)
```

3. 更新 `docs/docs/mod/battle/readme.md` debuffDetails 表：`id`/`amount`（入）、`cancelAmount`（出），注明 `cancelDebuff` 弃用。

**已知边界**（保持现状，与旧全量取消行为一致）：debuff 入场时对反状态的抵消（如缓慢抵消既有速度）发生在回调之前，事后抵消 debuff 不会返还已被抵消的反状态。

---

## 验证

1. `python build.py` 重新编译脚本生成 `.mod`；`flutter analyze` 无新增告警。
2. 手动验证清单：
   - 速度叠满阈值 → 敌我双方回合结束均获得额外回合（hint 显示、可再次出牌）；链式触发正常。
   - 各境界生成 energy_positive_\* 卡，数值 = base + rankIncrement × rank；装备/丹药 Roll 到阈值词条时数值 = ±rank。
   - 穿透装备：物理/真气伤害按比例穿透护甲；护甲保持：回合开始保留 >50% 护甲（含 hint）。
   - increase_damage 词条 → 战斗中显示永久图标且伤害增加；御剑术卡受益于 increase_damage_sword。
   - 对手获得 3 层缓慢、自己持有 2 层辟邪 → 只抵消 2 层、剩 1 层缓慢；辟邪消耗 2 层。
3. 如 `utils/data_validate` 可用，跑一遍 JSON5 数据校验。
4. 更新 `KNOWN_ISSUES.md`：移除本次修复的条目。
