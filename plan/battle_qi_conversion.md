# 元气转换卡重构 + 费用返还词条 + 卡面预测气增伤

> 本文档是"元气→有色气转换卡"、"费用返还额外词条"与"卡面伤害预测纳入气增伤"改动的实施依据。
> 上游依据：`plan/battle_resource_rework.md`（已删除，可从 git 恢复）——其 4.4 节遗留
> "产气卡转换率需测试后调整"与"先天功净收益需人工核对"两项，本文档落实前一项。
> 经济锚点沿用该文档第 3 节：**稳态产出目标 每回合 ≈ 2.5~3.5 气**。

## 1. 决策摘要

| # | 决策 | 状态 |
|---|------|------|
| 1 | 四色转换卡（灵气/剑气/怒气）改为 **0 费 + 打出时耗尽所有元气，1:1 转化** | 已拍板 |
| 2 | 无极转换卡改为 **0 费 + 1:0.5 转化，向下取整**（少于 2 点元气无产出） | 已拍板 |
| 3 | **新增煞气转换卡**（rank 1，与其他三色对齐；插画引用 `xinfa_karma.png`，文件暂缺、另行制作） | 已拍板 |
| 4 | 转换卡**保持中立**，不限定流派 | 已拍板 |
| 5 | 费用返还做**单一额外词条**「返还本牌消耗的气」（不分颜色），rank 3；删除 card_affixes.json5 中旧的 energy_positive_life / energy_positive_ultimate 两条按色词条 | 已拍板 |
| 6 | 删除参玄功（draw_cards）的预定义 `affixes` 列表；绝世卡固定词条后续统一设计补充 | 已拍板 |
| 7 | 先天功（energy_positive_life，绝世）数值**本次不动**，列为遗留项 | 已拍板 |
| 8 | **卡面伤害预测纳入气增伤**：按**扣费后**口径模拟本牌费用支付，`5 × 剩余层数`（含无极与阴气净值），插入基础值后、乘区前 | 已拍板 |

## 2. 设计理由

### 2.1 为什么改为 0 费耗尽制

- 现状（rank 1 固定 2 元气 → 约 1.5~2.25 点有色气）低于 1:1，且固定费用导致：
  1 点元气时是死牌，4 点以上元气（装备 battleEnergyBonus）时多余部分烂掉。
- 0 费耗尽制下，基础收入 3 元气/回合 → 3 点有色气，精确落在经济锚点区间；
  元气加成（装备、先天功）自动转化为有色气收益，构筑联动自然成立。
- 先例现成：`heal_vigor_all`（气疗术）即"0 费 + 消耗所有元气走效果而非费用"
  （card_script.ht:100），转换卡完全同构。
- 元气反正会在回合开始清空，"耗尽"几乎不是代价；真实代价是**卡位与摸牌位**，
  这才是构筑级资源牌应有的定价。玩家仍可通过**打出顺序**控制转换量
  （先打 2 元气中立卡再转换 = 只转 1 点）。
- 转换后未花掉的气各有性格，不构成纯浪费：剑气干净；灵气待接 overflowed_mana 天赋；
  怒气持有每层使自己受伤 +5%（对方回合生效，自残风险）；煞气未用回流业力池（跨战斗储蓄）。

### 2.2 为什么无极不同步 1:1

无极是万能色（可支付任意有色费用 + 全攻击 +5/层），1:1 会抹掉四色转换卡的存在意义。
1:0.5 向下取整保留"灵活但昂贵"的定位；不足 2 点元气打出 = 无产出（气仍被消耗），
是有意的风险设计，描述中须写明。

### 2.3 为什么转换卡保持中立（是否限定流派专属）

**结论：保持中立。** 五条理由：

1. **机制冲突**：单资源模型下"流派卡 = rank 点流派色"。一张剑气流派的剑气转换卡
   必须花剑气产剑气——循环矛盾。要限定流派就得发明费用之外的限制机制
   （requirement 字段或构筑规则），为一个限制新增机制不值得。
2. **法身（avatar）唯一通道**：法身不产出任何有色气，其阴气负债机制（rework 计划 2.4）
   暂缓未实现。中立转换卡是法身外溅流派卡的唯一气源；限定流派后法身将彻底无法打有色卡。
3. **混血构筑**：多流派卡组（如御剑+悟道）依赖转换卡润滑，限定流派会掐死溅射玩法。
4. **NPC 经济**：敌方卡组由 generateBattleDeck 从 buff 池自动生成，中立转换卡天然可得；
   限定流派需同步改造 deckgen（rework 计划已把 NPC 气源列为天赋树重构的硬依赖）。
5. **时机**：天赋树初始节点的各流派产出落地后，转换卡本就走弱，届时再评估是否限制不迟。

### 2.4 为什么返还词条合并为单一词条、放在高 rank、主词条后执行

- **单一词条**：现行单资源模型下每张卡至多消耗一种有色气（或纯元气），
  按色分开的返还与单一"返还全部所耗"对普通卡完全等价；合并后词条池更干净，
  且天然兼容未来多色卡（rework 计划：多色不设计不禁止）和无极抵扣混合支付的场景
  （例：费用 3 剑气、实扣 2 剑气 + 1 无极 → 一条词条全返，无需两个词条位）。
- **rank 3** 门限 = 高境 chase 词条，且天然规避 0 费特例卡
  （转换卡 rank 1/3、气疗术 rank 1 roll 不出 rank 3 词条，不会空返占词条位）。
  注：rank 3 的无极转换卡理论上可 roll 出，0 费打出时返还为空效果，无害。
- **不设 priority**（默认 0，主词条后执行，character.dart:1167-1182）：
  当次攻击不吃到返还层的持有增伤，避免"返还即增伤"的双重获益；
  返还的气供**后续**出牌使用（支付费用或提供 +5/层 增伤），节奏上是"先返后用"。

### 2.5 为什么气增伤预测按扣费后口径

气增伤的实际结算在 `_payCardCost`（battle.dart:1082）之后、`onUseCard`（:1093）
内的 doing_damage 回调（character.dart:819），即**按扣费后剩余层数**生效。
预测必须与实战同口径，否则卡面数字系统性虚高 `5 × 费用`。扣费后口径同时保证：
一层气对同一张牌付费 XOR 增伤，不可兼得（与返还词条后执行的哲学一致）。

## 3. 转换卡改动

### 3.1 数据（assets/data/cards.json5）

| 卡 | rank | 改动 |
|----|------|------|
| energy_positive_spell | 1（不变） | coloredCost → `{ life: 0 }`；script → `convert_vigor_all`；valueData → `[{ base: 100 }]`；description → `affix_convert_vigor_spell`；buffId 保留 |
| energy_positive_weapon | 1（不变） | 同上，description → `affix_convert_vigor_weapon` |
| energy_positive_unarmed | 1（不变） | 同上，description → `affix_convert_vigor_unarmed` |
| energy_positive_ultimate | 3（不变） | 同上，valueData → `[{ base: 50 }]`，description → `affix_convert_vigor_ultimate` |
| **energy_positive_curse（新增）** | 1 | 照 spell 卡复制：category buff / kind xinfa / cardType xinfa / script convert_vigor_all / valueData `[{base: 100}]` / buffId energy_positive_curse / keywords `["status_energy_positive_curse"]` / description `affix_convert_vigor_curse` / image `battlecard/illustration/xinfa_karma.png`（**文件暂缺**，另行制作） |

- valueData 的 base 是**转换率百分数**（100 = 1:1，50 = 1:0.5），沿用 heal_vigor_all
  "词条值按百分数存储、脚本内 ÷100"的惯例；无 increment，等级不再影响数值。
- 显式 `{ life: 0 }` 免费已被 updateCardCost 支持（键存在即采纳），
  数据校验对全 0 费卡跳过（_validateBattleCardCostColored），无阻碍。

### 3.2 绝世卡预定义词条清理

- 删除参玄功（draw_cards，cards.json5:85-115）的 `affixes` 字段
  （当前为 `["defend", "heal", "energy_positive_life", "buff_shield", "buff_ward", "energy_positive_ultimate"]`）。
- `_addPredefinedAffixes` 对缺失列表安全（card.ht:367-368 `is! List` 直接返回），无需改脚本。
- 经核对，四张绝世卡（参玄功/先天功/分心诀/气疗术）中**只有参玄功有**预定义 affixes，
  其余三张本无，无需处理。绝世卡固定词条后续统一设计补充（见第 8 节）。

### 3.3 脚本（scripts/main/cardgame/card_script.ht 新增）

```hetu
/// 气转换（中立主词条）：消耗所有元气，按 词条值% 的比例转化为目标气
/// 词条值 100 = 1:1（四色）；50 = 1:0.5（无极，向下取整，不足 2 点元气无产出）
/// 模板同 heal_vigor_all：消耗走效果而非费用
function convert_vigor_all(self, opponent, affix, mainAffix) {
  final vigor = self.hasStatusEffect('energy_positive_life')
  if (vigor <= 0) return
  self.removeStatusEffect('energy_positive_life', amount: vigor)
  final amount = (vigor * affix.value[0] / 100).floor()
  if (amount > 0) self.addStatusEffect(affix.buffId, amount: amount)
}
```

### 3.4 本地化（assets/locale/zh/rpg/battlecard.json 新增 5 键）

- `affix_convert_vigor_spell`：`"消耗所有元气，每点元气转化为 1 点灵气"`
- `affix_convert_vigor_weapon`：`"消耗所有元气，每点元气转化为 1 点剑气"`
- `affix_convert_vigor_unarmed`：`"消耗所有元气，每点元气转化为 1 点怒气"`
- `affix_convert_vigor_curse`：`"消耗所有元气，每点元气转化为 1 点煞气"`
- `affix_convert_vigor_ultimate`：`"消耗所有元气，每 2 点元气转化为 1 点无极之气（向下取整）"`

描述为静态文本（不带 {0}），value 不显示在卡面。

## 4. 费用返还额外词条（单一词条）

### 4.1 数据（assets/data/card_affixes.json5）

**删除** 2 条旧词条（旧"获得气"效果被返还方案取代，且参玄功 affixes 列表已删、无引用）：
`energy_positive_life`（:261-276）、`energy_positive_ultimate`（:279-294）。

**新增** 1 条：

```json5
// 返还本牌消耗的气（按实际支付量，含无极抵扣部分；主词条后执行）
refund_cost: {
  id: "refund_cost",
  uniqueId: "refund_cost",
  categories: ["buff", "attack"],
  rank: 3,
  description: "affix_refund_cost",
  script: "refund_cost",
},
```

- 无 valueData = 非数值词条，等级恒 1（card.ht:295-298），脚本不读 affix.value。
- rank 门限 = `affix.rank ≤ card.rank` 才可 roll 出（card.ht:229-253）。
- 无 priority → 主词条后执行（见 2.4）。

### 4.2 脚本（card_script.ht 新增）

```hetu
/// 费用返还（额外词条）：按此牌实际支付量返还全部所消耗的气
/// 依赖 Dart 侧在支付时写入 self.cardFlags['paidCost']（键 = 状态 id，值 = 实际扣除层数）
function refund_cost(self, opponent, affix, mainAffix) {
  final paidCost = self.cardFlags['paidCost']
  if (paidCost == null) return
  for (final statusId in paidCost.keys) {
    final amount = paidCost[statusId]
    if (amount > 0) self.addStatusEffect(statusId, amount: amount)
  }
}
```

### 4.3 Dart 管线：记录实际支付量

改动点只有 `_payCardCost`（lib/scene/battle/battle.dart:880-933）一处，
两条出牌路径（玩家 :1082、敌方 :1283）都经过它，无需改调用点：

- 在成功支付后、`return true` 前，把扣除明细写入
  `character.cardFlags['paidCost'] = <String, int>{...}`：
  - 元气：`['energy_positive_life'] = colorlessNeed`（>0 时）
  - 本色气：`pending` 列表中各 `(statusId, ownPaid)`（:911-915）
  - 无极抵扣：`[kWildcardStatusId] = ultimateNeed`（>0 时）
- **每次出牌无条件覆写**（包括 0 费卡写入空 map），避免残留上一张牌的明细。
- 语义：返还以**实际扣除**为准。例：剑气卡费用 3，持有 2 剑气 + 无极抵扣 1，
  则返还 2 剑气 + 1 无极；虚空之气增费也已计入实际扣除，天然一致。

### 4.4 本地化（battlecard.json 新增 1 键）

- `affix_refund_cost`：`"打出后返还此牌所消耗的气"`

旧键 `affix_energy_positive_*` 中 5 个（spell/weapon/unarmed/curse/ultimate）此后无引用，本次顺手删除；
`affix_energy_positive_life` 仍被先天功（energy_positive_life 绝世卡）引用，**保留**。

## 5. 卡面伤害预测纳入气增伤

### 5.1 背景与目标

现状 `predictDamage`（lib/scene/battle/character.dart:270-336）只算
基础值 → 增减益净值（pct1）→ 元素抗性 → 暴击/异常，**不含气的 ±5/层增伤**，
玩家无法从卡面感知气系统的双重设计（增伤机制见 status_script.ht:317-393）。
本次把气增伤按**扣费后**口径纳入预测，与 takeDamage 实际结算同序（理由见 2.5）。

### 5.2 计算公式

对攻击类主词条（cardType = T），在 `predictDamage` 取得基础值后、乘区（pct1）前插入：

```
增伤 = 5 × ( 阳气T_扣后 + 无极_扣后 − 阴气T − 虚空 )
```

其中"扣后"层数按 `_payCardCost`（battle.dart:880-933）的同款规则对本牌费用模拟：

- 无色（life）费用不影响增伤；
- 每个有色费用条目：需求 = 费用 + 虚空层数（其增费效果）；
  本色扣 `min(本色存量, 需求)`，缺口从无极存量扣（无极全色共享）；
- 阴气T（energy_negative_T）与虚空（energy_negative_ultimate）全额计入减项
  （阴阳对冲后通常不与阳气共存，公式按净值通用处理；结果可负，与实战一致）。

多色费用卡按条目依次模拟（现行单资源模型下只有单条目，公式前向兼容）。
0 费 / 纯元气费用攻击牌不扣任何气 → 全额气增伤，与实际结算一致。

### 5.3 实现要点

- `predictDamage` 增加可选参数（如 `cardCost`）：调用点
  `refreshHandCardDescriptions`（battle.dart:802-813）在逐卡循环处传入
  `_cardCostColored(card)`（battle.dart 已有的规范化 int 费用表），
  避免在 character.dart 重复 updateCardCost 的公式求值。
- 插入位置：`int damage = value[0]`（character.dart:283）之后、
  pct1 计算（:285-295）之前——与 takeDamage 中 baseChange 在乘区前合并的顺序一致，
  增伤因而被百分比与暴击放大，和实战相同。
- 更新 predictDamage 的 doc 注释（character.dart:265-269）：
  说明包含气增伤（扣费后口径），仍不含护甲/穿透/pct2/pct3/by_damage 等。
- 多段攻击（attack_multiple）每段增伤相同（层数不因增伤消耗），单段预测天然一致。
- **已知局限**：不模拟队列预占——按"立即打出"的当前状态估算，
  与现有预测口径一致；队列中前序卡对同色系气的消耗不反映在预测里。

### 5.4 验证（手动）

1. 5 剑气 + rank 3 御剑攻击牌（费 3）→ 预测含 +10（= 5 × (5−3)）。
2. 纯元气费用攻击牌（拳法）持有 4 怒气 → 预测含 +20（不扣气）。
3. 虚空之气 1 层 + 费 3 剑卡 → 按费 4 模拟扣后层数。
4. 2 剑气 + 1 无极打费 3 剑卡 → 剑气扣 2、无极扣 1，剩余 0 + 0 → 增伤 +0。
5. 持有阴剑气 2 层 → 预测含 −10。

## 6. 已知边界（均为既有局限或可接受行为）

- **队列预占无法预测动态消耗**：入队费用预占（_canPayCardCost 的 queued 参数）
  看不到转换卡的"耗尽元气"效果；队列中转换卡先于元气卡结算时，后者会在
  _payCardCost 处支付失败并退回手牌（battle.dart:1083-1087 已有兜底）。
  与气疗术同类既有局限，不在本次范围。
- **敌方 AI 循环条件 `energy > 0`**（battle.dart:1274）：AI 打出转换卡后元气归零即
  停止出牌，可能浪费已转换的有色气。既有 AI 局限，转换卡会放大其出现频率；
  可选后续优化（循环条件计入有色气，或 AI 把转换卡排在回合末），单列待办。
- 返还词条在 0 费卡上为空效果；0 费卡 rank 均 ≤ 3，仅无极转换卡（rank 3）可能
  roll 出返还词条，打出时返还为空，无害（见 2.4）。

## 7. 改动清单

### 7.1 必做（已全部实施）

- [x] `scripts/main/cardgame/card_script.ht`：新增 `convert_vigor_all`、`refund_cost`
- [x] `assets/data/cards.json5`：改 4 张转换卡 + 新增 energy_positive_curse + 删除 draw_cards 的 affixes 字段
- [x] `assets/data/card_affixes.json5`：删除 energy_positive_life / energy_positive_ultimate 两条 + 新增 refund_cost
- [x] `assets/locale/zh/rpg/battlecard.json`：新增 6 个键（5 转换 + 1 返还）；删除无引用旧键 5 个
      （spell/weapon/unarmed/curse/ultimate；life 键因先天功仍在用而保留）
- [x] `lib/scene/battle/battle.dart`：`_payCardCost` 写入 `cardFlags['paidCost']`；
      `refreshHandCardDescriptions` 调用点传 `_cardCostColored(card)`
- [x] `lib/scene/battle/character.dart`：`predictDamage` 纳入气增伤（扣费后口径，见 5.2/5.3）+ doc 注释更新
- [x] 文档同步：`docs/docs/mod/battle/readme.md`（cardFlags.paidCost 键说明）、
      `docs/docs/how2play/rpg/battle/resource/readme.md`（产出模型表改为转换卡 0 费耗尽制，
      删除过时的法身怒气+煞气重复行）

### 7.2 验证

- [x] `python build.py` 重新编译脚本（改了 .ht 必须执行）——通过
- [x] `flutter analyze` 无新增问题——No issues found
- [x] 数据校验：三份数据文件解析通过；五张转换卡字段、refund_cost 词条、本地化键、
      已删词条/旧键的残留引用、先天功描述键有效性均经脚本核验通过
- [ ] 手动场景（需进游戏实测）：
  1. 3 元气打剑气转换 → 3 剑气 → 打出 rank 3 御剑卡
  2. 1 元气打无极转换 → 0 无极（描述与行为一致）；2 元气 → 1 无极
  3. 带"返还"词条的 rank≥3 武器牌：费用 3、持有 2 剑气 + 1 无极 → 打出后 +2 剑气 +1 无极
  4. 返还词条在主词条后执行：当次攻击不吃返还层增伤，后续同流派牌吃到
  5. 0 费转换卡连续两张：第一张耗尽元气，第二张无产出不报错
  6. 参玄功各 rank 生成正常（无预定义词条、不报警）
  7. 卡面预测气增伤 5 个场景（见 5.4）

### 7.3 可选 / 后续

- [ ] 煞气转换卡插画 `xinfa_karma.png`（用户另行制作，数据先行引用）
- [ ] 先天功（energy_positive_life 绝世）数值核对（rework 计划 4.4 遗留）
- [ ] 绝世卡固定词条统一设计补充（参玄功已清空，待新词条体系）
- [ ] AI 转换卡使用时机优化（见第 6 节）

## 8. 明确不做

- 转换卡流派限定（保持中立，理由见 2.3；天赋树产出落地后再评估）
- 先天功数值调整（列为遗留项）
- 无极转换卡同步 1:1（会破坏四色 identity）
- 绝世卡固定词条设计（参玄功本次仅清空，后续统一补充）
- 法身阴气负债机制（rework 计划暂缓项，不属本文档）
- 卡面预测纳入护甲/穿透/pct2/pct3 等其余修正项（维持既有估算口径，仅加气增伤）
- `plan/battle_card_equipment_overview.md` 的同步修订（按当前决定暂缓）
