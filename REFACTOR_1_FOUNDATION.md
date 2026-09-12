# 阶段 1 · 地基：伤害结算顺序与既有 bug 修复

> 总览见 `REFACTOR.md`。本阶段是纯代码/文档阶段，不改任何玩法设计，
> 但它是后续所有阶段的地基——尤其是"护甲在乘区之后结算"这一条。

## 目标

1. 护甲（defense 状态）的抵扣从"乘区之前"移到"乘区之后"。
2. 修复 `self_attacking` / `self_buffing` 死回调，让流血、内伤、（当时的）豪气穿透真正生效。
3. 统一易伤（vulnerable）的规则表述：触发即消耗，不衰减。
4. 重写 `resource/readme.md`，消除文档与代码的矛盾。

## 改动清单

### 1.1 护甲结算移到乘区后（核心）

**现状**（`lib/scene/battle/character.dart` `takeDamage` + `scripts/main/cardgame/status_script.ht` `defense_self_taking_damage`）：

- 防御脚本在 `self_taking_damage` 回调里按 `details.baseValue × (1 − penetration)` 计算抵挡量，
  写入 `details.baseChange -= blocked`。
- `takeDamage` 随后执行 `(baseValue + baseChange) × (1+p1) × (1+p2) × (1+p3)`。
- 结果：护甲的吸收量被攻击方的增伤乘区**放大**——攻击方 buff 越多，护甲等效吸收越多。

**目标**：护甲在所有乘区结算完毕后，从最终伤害中按数值扣除（杀戮尖塔式）。

**实施方案（已确认）**：

- `defense_self_taking_damage` 不再修改 `baseChange`，改为把"可抵挡量"记录到 `details`（例如 `details.armorBlock = true`），
  或干脆把防御抵扣逻辑移到 `takeDamage` 的 Dart 侧：
  在 `finalDamage` 计算完成后、扣血之前，查询自身的 `defense_*` 状态（阶段 2 之后是单一 `defense` 状态），
  按 `blocked = min(护甲层数, finalDamage × (1 − penetration))` 抵扣，`finalDamage -= blocked`，并设置 `details['blocked'] = blocked > 0`。
- 穿透（penetration）的读取随之移到 Dart 侧（它已经由 `details['penetration']` 传入，逻辑不变，只是作用时点变化）。
- 注意保持 `defense_self_turn_start`（回合开始减半、persistent 保留）行为不变。

**验收要点**：

- 攻击方有 +50% 增伤时，10 点护甲面对 20 基础伤害的抵扣后伤害 = `(20×1.5) − 10 = 20`，而不再是 `(20−10)×1.5 = 15`。
- 多段攻击每一段仍分别抵扣护甲（杀戮尖塔动态保持不变）。

### 1.2 修复 self_attacking / self_buffing 死回调

**现状**：`lib/scene/battle/character.dart` 只触发 `self_attacked`（攻击牌结算后，约 918 行），
从不触发 `self_attacking` / `self_buffing`。导致：

- `injury_external_self_attacking`（流血：使用攻击牌时失血）——死代码
- `injury_internal_self_buffing`（内伤：使用加持牌时失血）——死代码
- `energy_positive_pure_self_attacking`（豪气穿透）——死代码

**修复（只改脚本，不动 Dart）**：

- `injury_external`：改用 `self_attacked` 回调（或 `self_used_card` + 检查 `self.cardFlags.category == 'attack'`）。
- `injury_internal`：改用 `self_used_card` 回调 + 检查 `self.cardFlags.category == 'buff'`。
- 豪气（阶段 3 才改为暴击）：本阶段先把穿透脚本同样迁移到可用回调上（`self_using_card`，
  在卡牌效果执行前触发，使穿透当回合生效），保证阶段 3 迁移时脚本落在活的回调上。
- 同步检查 `status_script.ht` 头部注释里的回调清单，删除不存在的 `self_attacking` / `self_buffing`，补全实际可用的回调名。

### 1.3 易伤规则统一

- 规则（已确认）：易伤触发对应伤害后自动消耗，回合开始**不**衰减。
- 代码现状已符合（`vulnerable_self_turn_start` 处于注释状态）——保持注释或删除该段死代码。
- 改文档：`docs/docs/how2play/rpg/battle/readme.md` 中"防御和易伤在回合开始时也会自动减少一半"
  改为"防御在回合开始时减半；易伤在触发对应伤害后消耗"。
- 检查本地化中易伤/辟邪（`status_ward_description`）等描述是否与该规则一致。

### 1.4 重写 resource/readme.md

消除以下矛盾（重写为只描述代码现实的参考文档，未实现的提案删除或移入设计日记）：

- 怒气生成："你的伤害被格挡时 +1 怒气"未实现 → 删除或标注为提案。
- 怒气软上限："每点怒气使自身受伤 +3%"未在脚本实现（仅存在于本地化描述）→ 二选一：
  要么补实现（`energy_positive_unarmed_self_taking_damage`），要么从描述中删除。**【待确认】**
- 资源表中清气/浊气、浩然之气/萧索之气从未实现 → 从表格移除或标注"预留"。
- "阳气包括"清单（本地化 `status_energy_positive_description`）与资源表不一致 → 统一。

## 涉及文件

- `lib/scene/battle/character.dart`（takeDamage 结算顺序）
- `scripts/main/cardgame/status_script.ht`（defense / injury / vulnerable / 回调清单注释）
- `docs/docs/how2play/rpg/battle/readme.md`
- `docs/docs/how2play/rpg/battle/resource/readme.md`（重写）
- `assets/locale/zh/rpg/status_effect.json`（如有描述不一致）

## 验证清单

- [ ] `python build.py`（或 VSCode `compileAllGameScripts`）编译通过
- [ ] `flutter analyze` 无新增错误
- [ ] 实机战斗：给角色堆增伤后攻击带护甲的敌人，确认护甲在乘区后扣除
- [ ] 实机战斗：流血/内伤在打出攻击/加持牌时正确扣血
- [ ] 文档中不再有与代码矛盾的规则描述
