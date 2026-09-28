# 战斗气资源重构：费用轴与攻击轴拆分

> 起源：悟道流派设计中发现气资源身份过载（状态/费用/攻击修正/负面抵消四重身份）。
> 结论：把"费用"与"攻击修正"拆成两条独立的轴。本文档为实施计划，待逐项执行。

## 一、最终决策（已拍板）

| 项目 | 决策 |
|---|---|
| 四色阳气（灵/剑/怒/煞） | 删除"攻击 +5/层"，纯费用 |
| 四色阴气（逆灵/止戈/非战/无心） | 删除"攻击 -5/层"，纯费用封锁（生效窗口=无费窗口，原为死效果） |
| 怒气 | 保留"自身受伤 +5%/层"（防御侧效果，与费用身份同向：花怒=卸破绽；不影响伤害预测） |
| 死气 | 保留双重身份（对冲元气 = 阴气通用行为；回合开始耗 1 层 -5% 生命上限 = 独立 DOT，两身份不冲突）。代码已审查无 bug |
| 无极之气 | 保留名称；脱离费用体系，变为普通攻击状态（永久保留、不被每回合清空）；**rank 3 起出现** |
| 虚空之气 | 同上，纯减攻状态；删除"有色费用 +1/层"（费用体系唯一例外规则，随之消失） |
| 太极之气（新） | 万能费用，沿用旧 id `energy_positive_ultimate`，零代码改动继承抵扣逻辑 |
| 混沌之气（新） | 万能费用的阴面对应，沿用旧 id `energy_negative_ultimate`；规则=**万能封锁**：抵消持有者获得的全部四色阳气（元气除外，与太极之气互相抵消），已实现 |
| 万法归宗 `isWildcardCostForbidden` | 语义自动变为"禁止太极之气抵扣"，代码零改动 |

拆分原则：**只拆"费用×攻击修正"的耦合；防御侧/触发式主题效果（怒气受伤、死气 DOT）逐个审议后允许保留。**

## 二、id 与命名映射（关键技巧：复用旧 id，名称转移）

| 旧 id | 新身份 | 新名称 | 图标 |
|---|---|---|---|
| `energy_positive_ultimate` | 万能费用（资源槽位） | 太极之气 | `icon/cost/qi_primal.png`（待人工缩放至 100×100） |
| `energy_negative_ultimate` | 万能费用的阴气 | 混沌之气 | 运行时反色（方案 a）或 `icon/cost/qi_chaos.png`（方案 b，见 §七） |
| `buff_all_damage`（新增） | 攻击状态（普通状态栏） | 无极之气 | `icon/status/buff_all_damage.png`（已有） |
| `debuff_all_damage`（新增） | 减攻状态（普通状态栏） | 虚空之气 | `icon/status/debuff_all_damage.png`（已有） |

复用 `energy_*_ultimate` id 后：`kWildcardStatusId`、费用支付/检查、`_kQiSlots`、`kOppositeStatus`、两个现有被动（§五）**全部零改动**。

## 三、数据层（status_effect.json5）

### 删除攻击修正（8 条）

- `energy_positive_spell / weapon / unarmed / curse`：删 `callbacks: ["self_doing_damage"]`（怒气保留 `self_taking_damage`）
- `energy_negative_spell / weapon / unarmed / curse`：删 `callbacks: ["self_doing_damage"]`
- 对应本地化描述删去 ±5 文案（见 §八）

### 太极/混沌（2 条改）

- `energy_positive_ultimate`：删 `callbacks`；名称→太极之气；描述→"万能费用：支付有色费用时，不足的部分自动抵扣"；icon→`icon/cost/qi_primal.png`
- `energy_negative_ultimate`：删 `callbacks`；名称→混沌之气；描述→"抵消你获得的太极之气"

### 无极/虚空（2 条新增）

```json5
// 无极之气：纯攻击状态，永久保留，不参与每回合清空；与虚空之气互相抵消
buff_all_damage: {
  id: "buff_all_damage",
  title: "status_buff_all_damage",            // 无极之气
  description: "status_buff_all_damage_description",  // 每层使你造成的所有伤害 ±X
  icon: "icon/status/buff_all_damage.png",
  script: "buff_all_damage",
  callbacks: ["self_doing_damage"],
},
debuff_all_damage: {
  id: "debuff_all_damage",
  title: "status_debuff_all_damage",          // 虚空之气
  description: "status_debuff_all_damage_description",
  icon: "icon/status/debuff_all_damage.png",
  script: "debuff_all_damage",
  callbacks: ["self_doing_damage"],
},
```

注意：**不带 `isResource`**——这是脱离资源槽位与统一清空的关键。

### 数值决策点（待拍板）

- 方案 A（沿用）：每层 ±5 固定值（`baseChange`）。rank 3 卡基础约 20-40，1 层 ≈ +12~25%；但**永久累积**放大了强度（5 层 = 每击 +25）
- 方案 B（推荐）：每层 ±5%（`percentageChange1`）。永久累积下更安全，且与卡牌数值自然同缩放
- 方案 C：层数/数值走来源词条的 valueData 指数公式，数值随境界成长

## 四、脚本层（status_script.ht）

- 删除 8 个钩子：`energy_positive_{spell,weapon,unarmed,curse}_self_doing_damage`、`energy_negative_{spell,weapon,unarmed,curse}_self_doing_damage`（怒气 `energy_positive_unarmed_self_taking_damage` 保留）
- 删除 2 个钩子：`energy_{positive,negative}_ultimate_self_doing_damage`
- 新增 2 个钩子（数值按 §三决策点）：

```hetu
function buff_all_damage_self_doing_damage(self, opponent, effect, details) {
  details.percentageChange1 += 0.05 * effect.amount   // 方案 B；方案 A 则 baseChange += 5*amount
}
function debuff_all_damage_self_doing_damage(self, opponent, effect, details) {
  details.percentageChange1 -= 0.05 * effect.amount
}
```

## 五、被动与 circumstance 白名单

- `lib/scene/battle/battle.dart` `kStatusOnCircumstance`：加入 `buff_all_damage`、`debuff_all_damage`（否则 start_*_with_* 被动无法授予）
- `lib/scene/battle/common.dart` `kOppositeStatus`：加入 `buff_all_damage ↔ debuff_all_damage` 双向映射（"虚空只能被无极抵消"零成本继承）
- 现有被动自动转移：
  - `start_turn_with_energy_positive_ultimate`（rank 5，pearl 装备）→ 太极来源，rank 5 不变
  - `start_battle_with_opponent_energy_negative_ultimate` → 混沌来源，建议提至 rank 4
- 新增被动（passives.json5）：
  - `start_battle_with_buff_all_damage`：战斗开始无极之气 +{0}，rank 3，装备词条（kinds 待定：weapon/amulet）
  - （可选）`start_battle_with_opponent_debuff_all_damage`：战斗开始对手虚空之气 +{0}，rank 4，丹药/装备

## 六、新卡牌词条（无极/虚空从 rank 3 进入卡池）

card_affixes.json5 新增（通用词条，不限流派）：

```json5
// 无极真言：打出时获得无极之气（永久攻击增益的入口词条，rank 3 起）
infuse_all_damage_up: {
  id: "infuse_all_damage_up",
  uniqueId: "infuse_all_damage_up",
  categories: ["buff", "attack"],
  rank: 3,
  description: "affix_infuse_all_damage_up",   // 打出时：无极之气 +{0}
  keywords: ["status_buff_all_damage"],
  script: "self_buff",
  buffId: "buff_all_damage",
  valueData: [{ base: 1, maxLevel: 0 }],
},
// 虚空侵蚀：给对手施加虚空之气
infuse_opponent_all_damage_down: {
  id: "infuse_opponent_all_damage_down",
  uniqueId: "infuse_opponent_all_damage_down",
  categories: ["buff", "attack"],
  rank: 4,                                    // 压制类略高于增益类
  description: "affix_infuse_opponent_all_damage_down",  // 打出时：对手虚空之气 +{0}
  keywords: ["status_debuff_all_damage"],
  script: "opponent_debuff",
  buffId: "debuff_all_damage",
  valueData: [{ base: 1, maxLevel: 0 }],
},
```

太极/混沌的高境界来源：

- 重新启用注释中的元气转换卡（`cards.json5:700` 段）：buffId 保持 `energy_positive_ultimate`，语义即"元气 1:0.5 → 太极之气"，rank 5
- （可选）各流派心法转换卡系列（灵气/剑气/怒气/煞气，同段注释中）是否一并重新启用，另行决策

## 七、UI（资源槽位）

- 槽位数量不变（6 对）：无极/虚空退出槽位，太极/混沌沿用同一槽位 id，**`_kQiSlots` 零改动**
- 阴面图标两个方案：
  - **方案 a（零代码）**：混沌显示为反色太极（黑白互换恰好契合"太极逆转即混沌"）
  - **方案 b（小改动）**：`energy_display.dart` `updateQi` 按 `_isYin` 加载阴面 icon 字段 → `qi_chaos.png` 生效；顺带让死气的 `decay.png` 引用生效（当前文件缺失，需补图或删引用）

## 八、本地化清单（assets/locale/zh/rpg/）

status_effect.json：

- 改：`status_energy_positive_ultimate` →"太极之气"+新描述；`status_energy_negative_ultimate` →"混沌之气"+新描述
- 改：四色阳气描述删"攻击 +5/层"；四色阴气描述删"攻击 -5/层"；虚空之气描述删"有色费用 +1/层"
- 新增：`status_buff_all_damage`"无极之气"+描述；`status_debuff_all_damage`"虚空之气"+描述

passive.json / craft.json / battlecard.json：

- `passive_start_turn_with_energy_positive_ultimate_description`：文案"无极之气"→"太极之气"
- `passive_start_battle_with_opponent_energy_negative_ultimate_description` + `craft.json:70` 丹药名：→"混沌之气"
- 新增：`affix_infuse_all_damage_up`、`affix_infuse_opponent_all_damage_down`、`passive_start_battle_with_buff_all_damage_description` 等
- 清理孤儿键：`battlecard.json:209` `affix_opponent_energy_negative_ultimate`（card_affixes.json5 无对应词条）

## 九、顺手清理（审查中发现）

- `battle.dart:1677` 注释"死气…失去 10% 生命"→ 实际为 5%，改注释
- `status_effect.json5:668` 死气 `icon/status/decay.png` 文件缺失：方案 b 下补图，方案 a 下删除该 icon 字段
- 废弃的旧勾玉图 `qi_primal.png` / `qi_chaos.png`（1254×1254 初版）：人工取舍

## 十、文档更新

- `docs/docs/how2play/rpg/battle/resource/readme.md`：6 阳 6 阴表重写为"费用轴 6 对 + 攻击轴（无极/虚空）"；删虚空增费例外；太极抵扣规则；死气/怒气保留条款
- `docs/docs/how2play/rpg/battle/readme.md`：伤害修正相关段落同步
- 敌人数值复核：靠气堆攻击的敌人全体变弱，需重调（本次重构最大平衡风险）

## 十一、验证

1. `python build.py`（脚本编译，含 status_script.ht 改动）
2. `flutter analyze`（Dart 改动：kStatusOnCircumstance / kOppositeStatus / 可选 energy_display）
3. 战斗实测清单：
   - 四色气打出攻击牌不再增伤；预测伤害在入队多张牌后保持稳定
   - 太极可抵扣任意有色费用缺口；万法归宗禁止太极抵扣
   - 混沌只对冲太极，不影响四色
   - 无极/虚空：状态栏显示、永久保留、互相抵消、±伤害生效
   - 怒气 +5% 受伤保留；死气 DOT 与对冲元气并存
