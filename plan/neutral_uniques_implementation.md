# 中立绝世卡牌与装备实施计划

> 状态：卡牌、两件装备及死气结算调整已实施；装备破境不在本次范围内。
> 内容、词条 ID、固定成长与数值口径以 `plan/neutral_uniques.md` 为准；本文负责把设计映射到代码、数据、脚本、本地化、校验器和测试。
> 本阶段不直接修改运行时代码、游戏数据或美术资源。

## 1. 目标与范围

### 目标

- 落地六张中立绝世卡：归元功、先天功、分心诀、参玄功、狭路相逢、万化归墟。
- 落地两件中立绝世装备：乾坤戒、无极佩。
- 优先复用现有卡牌脚本、被动聚合、组牌费修、资源保留和状态回调总线，不为中立内容另建一套战斗流程。
- 将绝世卡与绝世装备的固定成长校验统一收紧为“1 主词条 + 恰好 3 条固定额外词条 + rank 3/4/5 三次太古”。

### 不在本阶段范围内

- 新增中立流派、天赋树节点或中立资源。
- 继续补齐 rank 1～5 的中立装备套装。
- 修改太极之气的生命周期；该规则已单独实现，不在本次重复改动。
- 调整其他流派的卡牌、装备和天赋树。
- 战外装备破境、绝世卡新获取途径和经济系统改造。
- 最终美术验收之外的资源管线重排。

## 2. 当前可复用能力

| 设计需求 | 当前实现与复用方式 |
| --- | --- |
| 绝世固定词条与太古成长 | `BattleCard._addPredefinedAffixes`、装备 `createItemById`、`affixes + greaterAffixes` |
| 归元功消耗元气 | 现有 `heal_vigor_all`，只需在消耗前记录中间结果 |
| 抽牌结果修饰 | `cardFlags['lastDrawnCards']`，参照 `ziwei_draw` |
| 战斗内升级 | `upgradeCard(inBattle: true)` |
| 当回合减费 | `applyTurnCostModifier`，动态费用自动豁免 |
| 动态元气费用与超额支付 | `calculateCardPayment`、`cardFlags['paidCost']`、`defend_by_excess_paid` |
| 下回合元气 | `gain_resource_next_turn` + `turnFlags.pendingResources` |
| 双方易伤与多段攻击 | `opponent_vulnerable`、`self_buff`、`attack_multiple` |
| 元气保留 | 被动 `energyRetain`，在 `clearResourceEffects` 结算 |
| 手牌与抽牌参数 | `statsBonus.handSizeMax`、`statsBonus.battleDrawBonus` |
| 元气产出 | `basicEnergyBonus` 的 stats 聚合、战斗消费、面板与属性本地化已经存在 |
| 战初无极、穿透、暴击阈值 | 现有 `start_battle_with_buff_all_damage`、`penetration`、`critThreshold` |
| 流派加费 | `deckCostReduction: {color: 'all', amount: -1, genres: [...]}` |
| 每回合首张中立加持牌授予无极 | 现有 `self_used_card` 状态回调与 `turnCount`，只需新增永久状态 |

## 3. 卡牌脚本契约

### 3.1 归元功：消耗量中间结果

修改现有 `heal_vigor_all`：

1. 在移除元气前，将本次实际存量写入 `cardFlags['lastVigorConsumed']`；没有元气时也写 0。
2. 保持现有“消耗全部元气并治疗”的主效果与数值顺序不变。
3. 后续固定词条只读取本牌本次结果，不读取上一张牌的残留。

新增词条脚本按以下职责拆分，数值与门槛放在词条数据中：

- `qi_heal_armor`：消耗量达到 3 点后，按消耗量 × `value[0]` 获得护甲。
- `qi_heal_cleanse`：消耗量达到 3 点后，从 `Constants.debuffs` 中实际持有的状态随机移除 1 层；太古为 2 层。没有合法目标时不执行，不影响永久状态和资源阴气。
- `qi_heal_shield`：消耗量达到 3 点后获得 1 层护盾；太古为 2 层。

即使满血、主治疗没有实际回复，额外词条仍按消耗量结算。主治疗自身的随机驱散不归入额外净化计数。

### 3.2 通用资源门槛授予状态

新增一个通用 CardScript 函数，供 `vigor_threshold_defend` 与 `innate_conversion` 共用：

- 读取 `affix.resourceId`、`affix.resourceThreshold`、`affix.buffId`。
- 当前资源达到门槛后，授予 `affix.value?[0] ?? affix.count ?? 1` 层目标状态。
- 不移除资源，不修改费用，不区分元气、太极或其他资源。
- `vigor_threshold_defend` 使用普通 `valueData` 提供护甲数值，太古转换 `value[0]`。
- `innate_conversion` 使用固定 `count: 1`，太古通过 `greater.data` 增加 1 点，不增加或移除元气。

两个效果分别设置 `priority: 20` 与 `priority: 10`，保证先护甲、后太极。`innate_recoil` 使用独立的组合脚本，固定授予护盾与死气，太古只增加护盾，置于 `priority: 0`。

### 3.3 参玄功：只修饰主抽牌

新增两个脚本：

- `draw_cards_upgrade`：遍历 `lastDrawnCards`，对每张实际抽到的牌执行 `upgradeCard(inBattle: true)`；普通 1 级、太古 2 级。
- `draw_cards_cost_reduction`：遍历同一列表，调用 `applyTurnCostModifier`；普通 -1、太古 -2，动态费用继续豁免。

固定执行顺序：

1. 主词条抽牌并写入 `lastDrawnCards`。
2. `draw_cards_upgrade`，`priority: 20`。
3. `draw_cards_cost_reduction`，`priority: 10`。
4. `draw_cards_neutral`，`priority: 0`，最后额外抽牌并覆盖中间结果。

额外抽牌不升级、不减费。手牌已满导致主抽牌为空时，前两条不生效；额外抽牌仍按当时的剩余空间独立判断。

### 3.4 狭路相逢与万化归墟

两张新卡不新增 Dart 机制：

- 狭路相逢复用 `attack_multiple`，固定 3 段；`opponent_vulnerable` 沿用通用 `opponent_debuff` 规则，在主攻击结算后施加，自身易伤与护甲也在主攻击后生效。`mutual_assault_self_vulnerable` 复用 `self_buff`，普通值 5，太古通过 `greater.values` 设置为 2。
- 万化归墟复用 `attack_by_paid_resource`，主词条与 `life_ultimate_defense` 都显式写 `resourceId: energy_positive_life`。超额护甲读取实际支付元气减去 3，不能读取脚本缺省的灵气。
- `life_ultimate_battery` 复用 `gain_resource_next_turn`；`life_ultimate_drawback` 复用 `draw_and_self_buff`，死气层数不随太古增加。

## 4. 装备机制契约

### 4.1 乾坤戒

新增或复用以下被动：

- `cosmos_ring`：合并主词条，`statsBonus: {handSizeMax: 2, battleDrawBonus: -1}`；不写随机池用途标记，不参与太古。
- `basicEnergyBonus`：新被动词条，`base: 1, increment: 0`，太古对 `value[0]` 额外 +1。现有 stats 聚合、战斗消费、属性面板和 `character.json` 本地化直接复用，只需补 `passive.json` 描述。
- `handSizeMax`：复用现有词条与太古配置。
- `energyRetainLife`：新被动词条，`energyRetain: {resourceId: energy_positive_life, max: 1, costPerPoint: 2, costDamageType: pure}`；太古只将 max 增加 1。普通与太古描述分别写清上限和代价，不为插值额外扩展显示机制。

装备 prototype 的 `affixes` 顺序为：

```text
cosmos_ring / basicEnergyBonus / handSizeMax / energyRetainLife
```

`greaterAffixes` 依次为 rank 3 `energyRetainLife`、rank 4 `handSizeMax`、rank 5 `basicEnergyBonus`。

### 4.2 无极佩主状态

新增永久状态 `neutral_card_limitless`：

- 数据字段：`buffId: buff_all_damage`、`statusAmount: 1`、`isPermanent: true`、`callbacks: [self_used_card]`。
- 状态脚本读取 `self.getLastUsedCard()`；主词条 `genre` 非空或 `category != buff` 时直接返回，法身 `avatar` 也按流派卡处理。
- 本回合已经成功触发过时直接返回；回合标记记录在状态实例上，以 `self.turnCount` 区分普通回合与额外回合。
- 只有实际打出中立加持牌后才记录触发回合并授予无极；先打出流派牌或中立攻击牌不消耗本回合机会。
- 状态脚本保持同步、非阻塞，只调用 `addStatusEffect`，不调用异步 API。

无极佩主被动 `limitless_amulet` 同时携带：

- `battleStatus: neutral_card_limitless`。
- `deckCostReduction: {color: all, amount: -1, genres: [spellcraft, swordcraft, bodyforge, vitality, avatar]}`。

主词条合并两项逻辑，不拆成多个“主词条”。其余三个固定词条直接复用现有 `start_battle_with_buff_all_damage`、`penetration`、`critThreshold`，不复制新 ID。

### 4.3 绝世装备数据

两件 prototype 统一遵守：

- `uniqueId == id`，显式 rank，不写 rarity。
- `isUnstackable: true`、`isUnique: true`、`isIdentified: false`。
- `affixes` 第一项为合并主词条，之后恰好三条固定额外词条。
- 乾坤戒使用 `category: jewelry, kind: ring, rank: 1`；无极佩使用 `category: jewelry, kind: amulet, rank: 3`。
- 初版图标可使用 `item/unknown.png`，不因装备图标阻塞战斗验证。

## 5. 数据、脚本与本地化改造范围

### 5.1 卡牌数据

`assets/data/cards.json5`：

- 旧四张卡 rank 调整为归元功 0、先天功 1、分心诀 2、参玄功 3。
- 六张卡都补齐恰好三条 `affixes` 与三条 `greaterAffixes`。
- 新增 `neutral_mutual_assault`、`neutral_ultimate_life`；前者使用 rank 4 标准 3 元气，后者使用 `{life: {base: 3, isDynamic: true}}`。

`assets/data/card_affixes.json5`：

- 新增内容文档列出的中立词条与绝世专属词条。
- 只有 `vigor_threshold_defend` 进入普通随机池；依赖主效果中间结果或承担固定代价的词条写 `inUnpackable: true`。
- 为所有固定额外词条提供合法 `greater`，太古只强化原效果。

### 5.2 装备与状态数据

- `assets/data/items.json5`：新增乾坤戒、无极佩 prototype。
- `assets/data/passives.json5`：新增乾坤戒相关词条和无极佩主词条；复用现有公共词条。
- `assets/data/status_effect.json5`：新增 `neutral_card_limitless`，放在中立装备状态分区。

### 5.3 Hetu 脚本

- `scripts/main/cardgame/card_script.ht`：实现第 3 节的新脚本并修改 `heal_vigor_all`。
- `scripts/main/cardgame/status_script.ht`：实现 `neutral_card_limitless_self_used_card`。
- 不需要修改 `battle_entity.ht` 的聚合逻辑或新增 Dart 回调时机。

### 5.4 本地化与美术

- `assets/locale/zh/rpg/battlecard.json`：新卡名、词条描述、太古描述和关键词。
- `assets/locale/zh/rpg/item.json`：两件装备名称与 flavortext，写清机制、代价和中立卡口径。
- `assets/locale/zh/rpg/passive.json`：新被动词条描述。
- `assets/locale/zh/rpg/status_effect.json`：`neutral_card_limitless` 名称与描述。
- 两张新绝世卡使用专属插画，并同步 `kBattleCardIllustrations` 与 `illustration_` 本地化。
- `neutral_card_limitless` 使用 `icon/status/permanent/` 下的 150×150 状态图标；装备初版可使用占位图。

## 6. 校验器收紧

`utils/data_validate/game_data_validate.dart` 同步完成以下调整，不能只改校验而不补数据：

1. 所有 `isUnique` 卡牌必须显式提供长度恰好为 3 的 `affixes` 与 `greaterAffixes`。
2. 所有 `isUnique` 装备必须在主词条之外具有恰好 3 条固定额外词条，即 prototype 的 `affixes.length == 4`。
3. 三个太古目标不得重复，必须分别对应 rank 3/4/5、已经解锁且具有合法 `greater`。
4. 新 CardScript 的必需字段、资源门槛数值和 `inUnpackable` 约定纳入结构校验。
5. `neutral_card_limitless` 沿用现有 `self_used_card` 合法时机，无需新增时机白名单。
6. 将玩法与 MOD 文档中的“最多三条”统一更新为“恰好三条”，避免契约口径分裂。

## 7. 分阶段实施顺序

### 阶段 1：中立卡牌与校验器

- 先完成六张卡的数据、固定词条、脚本和本地化。
- 同一次变更中收紧绝世卡牌校验并补测试，避免旧四张卡长期校验失败。
- 优先验证归元功、参玄功的中间结果和词条执行顺序，再处理两张新卡。

### 阶段 2：乾坤戒

- 落地主词条、三个固定被动和物品 prototype。
- 验证元气保留在回合开始清理时生效，太极永久保留不受影响。
- 验证抽牌减少、手牌上限和元气产出的聚合结果。

### 阶段 3：无极佩

- 先落地 `neutral_card_limitless` 状态数据、脚本、本地化、图标和被动绑定。
- 再接入物品 prototype、战初无极、穿透和暴击阈值成长。
- 验证中立卡触发、流派加费和每回合限制后，再进行多回合数值复核。

### 阶段 4：文档、美术与场景回归

- 同步玩家规则、MOD 契约和战斗系统上下文。
- 补齐新卡插画与状态图标，检查小尺寸可辨性。
- 运行完整数据校验、脚本编译、静态分析和测试，并进行真实战斗场景验证。

## 8. 验收与测试矩阵

### 构造与成长

- 六张卡均为 1 主 + 3 固定额外词条，rank 0/1/2 解锁数量正确，rank 3/4/5 太古顺序正确。
- 两件装备均为 1 主 + 3 固定额外词条；分别创建不同 rank 的独立实例，解锁与太古结果正确。装备破境未实现，不作逐级破境验收。
- 主词条永不太古，所有太古目标都有合法配置。
- 缺少、超过或重复固定词条，以及错误太古目标均被校验器拒绝。

### 卡牌行为

- 归元功在 0/2/3 点元气时分别正确处理护甲、净化和护盾门槛；满血时额外效果仍生效，0 消耗时不白赚收益。
- 先天功的护甲与太极分别检查 3 点门槛，太极转化不减少元气；死气不被辟邪抵消，太古只强化指定部分。
- 分心诀在 rank 2 初始具有全部三条减益，易伤、破绽和全攻击削弱按各自规则生效。
- 参玄功只升级和减费主抽牌；额外抽牌不获得修饰，动态费用不归零，手牌上限约束保持一致。
- 狭路相逢固定三段；攻击结算后才施加双方易伤，本牌不会读取刚获得的敌方易伤；rank 5 自身易伤为 2 层。
- 万化归墟只按实际支付元气造成伤害；超额护甲、下回合元气和死气互不混淆，太极不能支付元气费用。

### 装备行为

- 乾坤戒正确聚合成手牌上限 +2、正常抽牌 -1；额外词条解锁后数值与太古结果正确。
- 元气保留只处理 `energy_positive_life`，每点造成 2 点纯粹伤害；太极不参与该保留规则。
- 无极佩只响应主词条 `genre` 为空且 `category == buff` 的中立加持牌，法身牌和中立攻击牌不触发；先打出这些牌不消耗机会，每回合最多一次，额外回合重新计算。
- 无极佩对五种流派卡加费，普通费用与动态门槛分别遵守现有规则，中立卡不加费。
- 战初无极、穿透和暴击阈值按境界成长，暴击阈值仍受全局上下限约束。

### 真实场景

至少执行以下实际 `BattleScene` 验证，不只检查数据构造：

1. 参玄功主抽牌升级/减费后再额外抽牌，确认目标与执行顺序正确。
2. 先天功获得元气与太极后支付有色费用，下一回合检查死气先对冲、后扣血且不自动消耗；太极按现行规则永久保留。
3. 乾坤戒保留元气并结算纯粹伤害，随后用于万化归墟的 3+X 支付。
4. 无极佩在连续中立加持牌、中立攻击牌、流派牌、法身牌和额外回合场景下只按约定触发，新增无极不追溯强化触发牌。

## 9. 文档同步与验证命令

实施时同步更新受影响文档，不作为事后可选工作：

- `docs/docs/how2play/rpg/battle/card/readme.md`：绝世固定成长、六张中立卡及新词条规则。
- `docs/docs/how2play/rpg/item/equipment/readme.md`：两件中立装备、元气保留和无极佩中立卡口径。
- `docs/docs/how2play/rpg/battle/resource/readme.md`：仅在元气保留说明需要补充时更新，不重复修改太极生命周期。
- `docs/docs/mod/battle/card/readme.md`：`lastVigorConsumed`、主抽牌修饰、资源门槛和新词条字段契约。
- `docs/docs/mod/battle/readme.md`：绝世成长校验、装备机制字段与 `neutral_card_limitless` 状态契约。
- `.agents/context/battle_system.md`：只写入已经落地的中立内容，不提前记录规划。
- `.agents/skills/`：仅在新脚本或装备约定改变既有内容制作流程时同步。

按改动范围运行：

```bash
python build.py
flutter analyze
dart run utils/data_validate/game_data_validate.dart
flutter test
```

本计划不修改天赋树，因此不需要以 `passive_tree_validate.dart` 的历史失败作为本阶段验收条件。
