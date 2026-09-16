# Phase 3 报告：气的产出与回合行为

> 所属计划：`plan-battle_qi_cost_rework.md` §8 Phase 3

## 验收结果

- `dart analyze lib`：**No issues found**（全仓仅 3 条预存 pubspec 资产目录警告）。
- `python build.py`：main/story 编译成功；反查 main.mod 确认 7 个旧回调函数（enable_chakra_self_used_card / enable_rage_opponent_used_card / enable_mana_self_turn_end / energy_positive_life_self_turn_end / energy_positive_spell_self_overflowed_energy / energy_positive_spell_self_deck_end / energy_positive_weapon_self_overflowed_energy / energy_positive_unarmed_self_turn_end）全部清零，`turn_end_resource_settlement` 已编入。
- locale JSON 校验通过。

## 改造后的回合时序

**回合开始（battle.dart `_startTurn`，do 循环内）**

| 步骤 | 动作 | 说明 |
|---|---|---|
| 0 | 每 16 回合叠劫气 | tribulation 替换原死气叠层（非资源，不清空、不对冲、不影响费用） |
| 1 | 摸牌 | 现有逻辑不变 |
| 2 | `onStartTurn` 回调 | 死气消耗 1 层 -10% 生命、劫气 -10%、点燃/感电 DOT、缓慢跳过判定、幻觉等。**保留死气伤害**：它是回合开始回调，必须先于清空执行，否则层数被清永不触发 |
| 3 | 跳过检查 | skipTurn 则 break（不清空不产出） |
| 4 | `clearResourceEffects()` | 清空全部 12 种资源气（6 阳 6 阴）；煞气剩余层数 1:1 返回 `data['karma']` 池（带跳字提示，locale 键 `karmaPoolReturnHint`） |
| 5 | `produceTurnStartResources()` | 元气 rank+3（走 addStatusEffect，若有死气会自然对冲——因先清空，实际对冲发生在回合内获得场景，如产元气卡）；剑气 = 上回合武器攻击牌数（需 enable_chakra）；怒气 = 上回合受伤 ÷10（需 enable_rage）；灵气 = enable_mana 未满上限 +1（节点加成留注释接口）；煞气 = min(karmaMax, max(1, 池÷10)) 从池提取 |
| 6 | `energyDisplay.setEnergy(元气层数)` | 能量瓶改读状态 |
| 7 | start_turn 被动注入 → 玩家/敌方出牌阶段 | `_canPayCardCost`/`_payCardCost` 无色部分读元气层数，存量经校验后 `removeStatusEffect('energy_positive_life', amount: N)` 精确扣除（全有或全无不会截断） |

**回合结束（character.dart `onEndTurn`）**

| 步骤 | 动作 | 说明 |
|---|---|---|
| 1 | `turn_end_resource_settlement`（hetu，显式调用） | ① 灵气按**剩余层数**触发 overflowed_mana_*：convert_to_vigor → 剩余灵气 1:1 转元气；随机元素伤害 → 每层 5 点。② 元气回血：每剩余 1 层 `max(1, round(lifeMax×2%))`，不消耗层数、不超过缺失量。**顺序在函数内显式保证**，转化的元气赶上同回合回血 |
| 2 | 其余 self_turn_end / opponent_turn_end 回调 | 速度、冰缓/中毒 DOT 等，现有逻辑不变 |
| 3 | — | 资源图标保留显示至下个回合开始清空（对方可见剩余费用） |

**回合统计结转**：`onStartTurn` 内、回调分发前归档——`lastTurnWeaponAttackCards`/`lastTurnDamageTaken` ← 本回合值，本回合清零。武器攻击牌数在 `onUseCard` 累计（category==attack 且 cardType==weapon，hero/enemy 共用）；受伤在 `takeDamage` 的 finalDamage>0 分支累计（DOT 的 changeLife 不计入，见"偏离"第 3 条）。

## energy → 状态转换的引用点清单

`character.dart`：删除 `int energy`/`_energyMax`/`energyMax` 字段及 onLoad 赋值，改为 `int get energy => hasStatusEffect('energy_positive_life')`（计算 getter，调用方零改动）；`reset()` 补回合统计清零。`battle.dart`：删除 `hero.energy = 0`/`enemy.energy = 0`（reset 已清状态）、`energy = energyMax` 回满（改产出模型）、战前 karma→煞气转换（192-199）；`_payCardCost` 扣费改 `removeStatusEffect`。读取点（`_canPayCardCost`、敌方 AI 循环条件 `energy > 0`、`heroHandZone.energy`、`setEnergy` 各处、日志）经 getter 自动转读状态层数。`hand_zone.dart` 的 `energy` 字段是另一个对象上的未读遗留字段，未动。

## 数据与脚本变更

- **status_effect.json5**：enable_chakra/rage/mana 回调清空（改为纯标记）；新增 **enable_karma** 条目（permanent 标记，图标 qi_karma.png，battle start 双方按天赋注入）；energy_positive_life 去掉回调；spell 去掉 `self_overflowed_energy`/`self_deck_end`（后者 Dart 从不派发，死回调清理）；weapon 去掉 overflow 回调；unarmed 去掉 `self_turn_end`（最后一处减半删除）。addStatusEffect 的 manaMax/chakraMax 单次获得截断保留（Dart 侧 overflow 派发因无注册者成为无害空转）。
- **status_script.ht**：删 8 个旧函数；新增 `turn_end_resource_settlement(self, opponent)`。
- **本地化**：enable_chakra/rage/mana/karma 与元气/剑气/怒气描述改为新模型措辞；新增 `karmaPoolReturnHint`。

## 偏离与决策（需知悉）

1. **enable_mana 从回合末移到回合开始**：统一生命周期下"回合末 +1 灵气"会在下个回合开始被清空，天赋完全失效；移入 `produceTurnStartResources`（先清空后产出）使其在本回合可花。
2. **怒气产出只统计 takeDamage 路径**：DOT/换血类 changeLife 不计入"受伤 ÷10"（设计未明确，取"被攻击"口径）。
3. **跳过回合不结转统计**：skipTurn 时结转已发生，滞后产出被跳过回合"吞掉"（设计未明确，属边缘情况）。
4. **overflowed_mana_keep_to_deck_end 与 overflowed_chakra_debuff_affect_opponent 两个天赋失效**：前者对应的"溢出保留"机制已不存在，后者对应的剑气溢出 debuff 惩罚已按 4.6 删除。属设计既定后果，Phase 6 天赋重做时处理。
5. **hetu 侧无需新增 extern**：产出/清空/统计全在 Dart 侧，hetu 不读新字段，`battle_character.ht` 未动。
6. 节点种子/加成全部以注释预留位形式缺省 0（§4.2/4.3/4.4/4.5 各一处）。

## 请用户重点实测的场景

1. **怒气跨回合保留与风险代价**：持有怒气进入对方回合，受到攻击时伤害是否明显放大（+5%/层）；自己回合开始时怒气清空。
2. **怒气滞后产出**：上回合故意挨打 → 本回合开始获得 怒气=受伤÷10（需 enable_rage 天赋）；不上回合被打 → 本回合怒气为 0。
3. **剑气滞后产出**：上回合打武器攻击牌 → 本回合剑气 = 所打数量；不打 → 断档为 0。
4. **元气循环**：回合开始 rank+3 → 支付扣层 → 回合结束剩余层回血（每层 2%、保底 1 点）→ 对方回合可见剩余 → 下回合开始清空重发。
5. **煞气池**：战斗不再带入存量煞气；每回合开始从池提取（池÷10、至少 1、封顶 karmaMax）；回合结束剩余返回池（看跳字）；战斗胜利池 +5；跨战斗池持久。
6. **劫气**：第 16/32/48… 回合双方叠劫气，回合开始 -10% 生命上限并消耗 1 层；确认不影响费用、不占资源栏。
7. **灵气溢出天赋**：convert_to_vigor 时回合结束先转元气再回血（一次结算两个跳字）；随机元素伤害按剩余层数结算。
8. **阴阳对冲**：持有死气时获得元气（如产元气卡）应先抵消死气；回合开始产出时因先清空则无对冲（符合"先清空后产出"）。
9. **敌方对等功能**：敌方回合开始同样清空+产出，AI 费用检查与新模型一致（NPC 有 enable_chakra/rage 天赋时表现滞后产出）。
10. **额外回合**：speed_quick 额外回合会再次清空+产出（与旧"再次回满能量"语义对齐）。
