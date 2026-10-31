# 御剑流派重构实施计划

> 状态：仅实施规划，尚未执行。
> 内容与数值以 `plan/skill_tree/swordcraft.md` 为准；本文负责把设计映射到当前代码、数据、脚本、文档和测试。
> 本阶段不修改运行时代码、游戏数据、本地化或美术资源。

## 1. 目标与范围

### 目标

- 按三额外词条与太古成长规则落地御剑境界节点、共享分支、普通卡牌、随机额外词条、绝世卡牌和绝世装备。
- 优先复用悟道已经建立的被动聚合、永久状态、动态费用、保留、元素异常和绝世成长机制。
- 将剑意、连斩、保留历史、资源互通等跨内容能力实现为通用机制，避免逐卡硬编码。
- 在正式接入天赋树之前，先完成可独立验证的战斗内容。

### 不在首批战斗实施范围内

- 天赋树节点的位置、连线和最终排布。
- 战外「养剑」分支及其装备升级/破境。
- 新卡牌插画、绝世装备图标和天赋树节点图标的最终美术。
- 对悟道或其他三个流派的内容返工；仅做御剑所必需的公共机制扩展与文档同步。

## 2. 当前可复用能力

| 设计需求 | 当前实现与复用方式 |
| --- | --- |
| 御剑牌减费 | `deckCostReduction`，参照 `spellcraft_rank_2` |
| 化神洗入剑道千秋 | `shuffleIntoDeck`，参照 `spellcraft_rank_5` |
| 下回合剑气 | `turnFlags.pendingResources`，在产出阶段统一授予 |
| 本回合用牌统计 | `turnFlags` 与 `self_used_card`，参照五行轮转 |
| 动态费用与实际支付 | `calculateCardPayment` 与 `cardFlags.paidCost` |
| 普通抽牌、置零和升级 | `drawCardsToHand`、`clearReducibleCardCosts`、`upgradeCard(inBattle: true)` |
| 保留与太古保留升级 | `added_to_hand` / `retained_turn_end` 回调及现有 `retain` 词条 |
| 身法增伤 | `for_attribute_increase_damage` |
| 资源门槛增伤 | `increase_damage_by_energy_count`，资源 id 改为剑气 |
| 元素异常 | `ailment_spread` 与 `require: {elementType: true}` |
| 元气转剑气 | `convert_vigor_all`，目标资源改为 `energy_positive_weapon` |
| 元素共享分支 | 现有 `skilltree_branch_element_1/2`，不重复实现 |
| 绝世固定成长 | `affixes` + `greaterAffixes`，rank 1/2 解锁，rank 3～5 太古 |
| 装备行为 | `battleStatus` + 永久状态脚本；参数行为使用机制字段或 `statsBonus` |

## 3. 新公共机制契约

### 3.1 剑意 `sword_intent`

#### 状态与伤害

- 在 `status_effect.json5` 新增普通状态 `sword_intent`，不设置 `isPermanent`、`isResource` 或 `isDebuff`。
- 图标使用用户已经提供的 `assets/images/icon/status/sword_damage.png`，数据路径写 `icon/status/sword_damage.png`。
- 状态脚本监听 `self_doing_damage` 与 `self_used_card`：
  - 仅当伤害来自当前剑法/御剑术攻击牌时，每层增加 5 点 `baseChange`。
  - 多段攻击逐段调用伤害管线，因此每段都获得加成。
  - 当前卡牌全部主/额外词条结束后，若主词条为 `category: attack` 且 `kind` 为 `sword/flying_sword`，一次性移除全部剑意。
- 通过 `getLastUsedCard()` 和当前 `cardFlags` 判断卡牌身份，不给 Dart 写入具体内容 id。
- 消耗时把本次消耗层数记录到当前牌的结算数据，供 `sword_intent_release_defend` 使用；每回合只兑现一次护甲。

#### 剑意增幅

- 为当前伤害增加一个通用的剑意倍率参数，普通值为 1。
- `sword_intent_surge`、`multi_hit_intent_bonus` 等只修改该参数，不复制一份剑意伤害公式。
- 多段限定增幅需要同时读取多段上下文；非多段攻击不获得 `multi_hit_intent_bonus`。
- `predictDamage` 同步计算确定性的剑意基础值与增幅，保持卡面预测和实际结算的顺序一致。

#### 获得与消耗顺序

- `sword_intent_gain` 使用负 `priority`，在主词条前通过 `self_buff` 获得剑意。
- 七星剑阵、剑道千秋等全部段数完成后才消耗剑意。
- 一剑破万法即使没有驱散目标、没有造成伤害，也在整牌结束后消耗剑意。
- 普通状态图标不调用生图 skill；若后续新增其他普通小像素状态图标，在实施清单中标记“由用户统一手工处理”。

### 3.2 多段攻击上下文

为多段攻击建立统一数据，而不是让各装备猜测脚本函数名：

- 伤害明细提供 `isMultiHit`、当前段序号和本牌总段数等通用信息。
- 当前牌结算数据提供额外段数修正，所有多段攻击脚本共同读取。
- `attack_multiple`、`sword_combo`、七星剑阵、剑道千秋和 `combo_followup` 使用同一段数口径。
- `combo_followup` 追加的攻击段也进入同一伤害管线，因此正常受到剑意、护甲、破绽和装备多段修正影响。
- `turnFlags` 记录本回合是否已打出多段攻击，供剑影分光、七星剑和连斩后迅捷实现“每回合第一次”。
- 剑影分光的额外段数与七星剑的同名效果按数值相加。

### 3.3 保留历史与跨回合费用

#### 保留历史

- 在卡牌战斗实例上记录 `retainedTurnCount` 或等价的保留历史字段；它与 `isRetained` 分离。
- `BattleScene.clearHand(keepRetained: true)` 在卡牌真正留手时统一累加保留历史，再派发 `retained_turn_end`。
- 卡牌未保留而进入弃牌堆时清除保留历史。
- 卡牌打出时，保留历史必须维持到全部词条结算完成，随后清除；这样 `retained_upgrade`、剑道千秋等仍能读取本牌的保留条件。
- 战斗重开通过现有全量重建自然清空，不把战斗内保留历史写回卡库。

#### 保留减费

- `retained_cost_down` 在入手和保留历史变化时重算，必须在费用检查与支付之前生效。
- 采用与调息类似的“先还原、再按当前条件应用”幂等方式，避免入手级联重算重复叠费。
- 离开手牌时还原修正，但不影响已经完成的支付。
- 藏剑的下回合费用修正不能使用当前回合结束即还原的 `applyTurnCostModifier`；需要带明确到期时间的卡牌费修记录，在下回合结束后或离手时清理。
- 藏剑主效果与额外词条分别记录费用修正来源，保证 +1 与 -1/-2 可以独立计算，而不是互相覆盖。

#### 主词条保留

- `sword_nurture`、`sword_sheathing`、`sword_spirit`、`sword_ultimate` 的“本牌保留”通过主词条 `added_to_hand` 回调实现。
- 这些主词条仍必须有打出时基名脚本；不能套用“额外词条纯回调可缺省基名”的例外。

### 3.4 剑气产出与连打统计

优先复用 `pendingResources`，不再新增一套跨回合计数器：

- `swordcraft_rank_1`：
  - `self_produce_resources`：仅 `turnCount == 1` 时按身法整除 10 产出剑气。
  - `self_used_card`：武器牌向 `pendingResources` 登记 1 点下回合剑气，并累加本回合“产气牌”计数。
- `swordcraft_rank_3`：拳法和飞剑牌执行同样的下回合产气登记和计数。
- `swordcraft_rank_4`：按当前已解锁条件判断本牌是否属于产气牌，获得 1 层迅捷；不能因凝气与结丹两个状态各触发一次而获得双层。
- `sword_combo` 与 `combo_followup` 读取同一个本回合产气牌计数；当前牌尚未完成结算，因此不计入“此前打出”。
- 额外回合清空本回合计数，但 `pendingResources` 按现有跨回合规则保留到下一次产出阶段。

### 3.5 气剑同源与支付

在 `card_cost.dart` 扩展现有支付计算，不另建支付入口：

- 新增数据驱动的资源互通配置，由被动聚合后传入支付计算；建议形态为“费用色 → 可替代颜色列表”，不在 Dart 中写死悟道/御剑内容 id。
- 普通有色费用按本色、互通色、太极依次支付。
- 动态费用以达到 N 为目标检查本色 + 互通色 + 太极；X 只耗尽本色，互通色与太极只补 N 的缺口。
- `paidCost` 继续记录各资源实际支付量，伤害和段数只读取主词条指定的本色资源。
- `isWildcardCostForbidden` 只禁止太极，不禁止气剑同源的互通色。
- 队列预占按顺序模拟本色、互通色和太极的消耗。
- 置灰、缺资源提示、玩家支付和敌方 AI 全部使用同一计算结果。
- 剑气/灵气阈值、是否为 0、溢出和止戈/逆灵之气仍只读取对应本色资源。

### 3.6 首张牌费用修正

沉香木剑匣和金丝剑穗的“每回合/每额外回合第一张匹配牌减费”需要在支付前生效：

- 将其实现为支付计算可读取的通用限时费修规则，包含过滤条件、费用变化和每回合使用次数。
- 手牌置灰和队列预占必须模拟“第一张匹配牌打出后优惠被消费”，不能给队列中的后续匹配牌重复优惠。
- 实际打出第一张匹配牌后才消耗次数，而非回合开始随机预选一张手牌。
- 动态费用仍遵守减费豁免；规则只能修改普通费用或动态门槛中允许修改的部分，当前设计统一按普通减费豁免处理。
- 普通回合与额外回合通过 `turnFlags.isExtra` 或等价上下文区分。

### 3.7 资源封锁与产出保底

- 七星剑阵打出后向 `turnFlags` 写入本回合禁止获得的资源集合。
- `addStatusEffect` 在真正获得阳气前检查该集合；已经持有的剑气不移除，下回合才获得的 `pendingResources` 不受本回合封锁影响。
- 剑丸使用新的“全部产出完成后”时机，例如 `self_after_produce_resources`，不能依赖多个永久状态在 `self_produce_resources` 中的遍历顺序。
- 新时机必须同步状态回调契约和校验器；剑丸只读取本色剑气，在其他产出完成后仍为 0 才补 3 点。

### 3.8 飘忽与额外回合时机

- 在闪避达到阈值、实际转化为 `dodge_invincible` 的结算边界分发一次 `self_dodge_triggered`，供金丝剑穗主效果和 `dodge_intent_gain` 使用。
- 不要在每次受到被飘忽减免的伤害时分发，否则会与设计的一次转化一次收益不符。
- 额外回合抽牌涉及异步手牌操作，不放入必须非阻塞的状态脚本。
- 在 Dart 额外回合入口读取聚合机制字段并调用 `drawCardsToHand`；踏雪无痕复用普通费用置零能力，动态费用不归零。
- 新机制字段需要包含抽牌数量、是否普通费用置零及适用回合条件，并同步透传白名单、契约文档和校验器。

### 3.9 驱散与追加攻击

- 为一剑破万法提供通用驱散 API：返回本次实际移除的正面状态 id 集合。
- 可驱散集合限定为非永久、非资源、非减益状态；不通过逐个内容 id 枚举。
- 驱散、按种数造成伤害、无目标抽牌全部由 CardScript 按顺序执行。
- 剑灵附体的状态回调只登记追加攻击请求，不直接在非阻塞状态脚本中调用攻击 API。
- Dart 在当前卡牌结算边界消费追加攻击请求，走正常伤害管线；追加攻击标识为飞剑、多段上下文的一部分，能够接受剑意和七星剑修正。
- 剑灵附体每回合只登记一次，触发后结算生命代价、下回合剑意和迅捷。

## 4. 内容数据改造

### 4.1 `assets/data/cards.json5`

- 调整现有御剑普通卡的 rank 和费用，保留已有动画与插画作为初版资源。
- 将六张元素剑调整为设计文档规定的 rank 2/3，继续显式使用 `spell` 费用。
- 新增 `sword_combo`、`flying_sword_burst`、`sword_energy_conversion`、`dodge_nimble_exhaust_chakra_defend`、`sword_nurture`、`sword_intent_meditation`。
- 新增六张御剑绝世卡；剑道千秋与天赋授予卡一样使用 `isUnpackable: true`，避免进入普通卡包池。
- 每张绝世使用最多 3 条固定额外词条，并按设计文档填写 `greaterAffixes`。
- 动态费用：`flying_sword_burst` 使用 `{weapon: {base: 0, isDynamic: true}}`；剑道千秋使用 `{weapon: {base: 10, isDynamic: true}}`。
- 剑道千秋不使用 `isWildcardCostForbidden`，因为设计允许互通色和太极补足 10 点门槛。

### 4.2 `assets/data/card_affixes.json5`

- 保留现有 `upgrade_hand_cards_swordcraft`、`for_dexterity_increase_damage`、`retain`。
- 新增七条普通随机额外词条：`sword_intent_gain`、`chakra_burst`、`combo_followup`、`sword_ailment`、`retained_upgrade`、`retained_cost_down`、`sword_intent_surge`。
- 为十条随机词条全部提供合法 `greater`，并保证太古只强化原效果。
- 绝世专属固定词条写 `inUnpackable: true`，不进入随机池；可复用的公共词条不必复制新 id。
- 涉及保留、首张、段数和剑意的字段必须先有第 3 节所述消费方，再写入数据。

### 4.3 `assets/data/passives.json5`

- 新增 `swordcraft_rank_1～5`；rank 2 使用减费字段，rank 5 使用洗入字段，rank 1/3/4 绑定永久状态。
- 新增剑影分光、踏雪无痕、气剑同源、养剑等分支被动；抱真守一和五行轮转直接复用现有 id。
- 为五件绝世装备各建立一条合并主词条和三条固定额外词条。
- 绝世专用词条不添加普通随机池用途标记；可进入普通装备池的共享词条另行明确 `isEquipmentExtraAffix`、`kinds` 和 rank。
- 替换 `assets/locale/zh/rpg/passive.json` 中旧御剑境界文案，避免新旧效果并存。

### 4.4 `assets/data/items.json5`

按设计文档新增五个 prototype，统一遵守：

- `uniqueId == id`、显式 rank、不写 rarity。
- `isUnstackable`、`isUnique`、`isIdentified: false`。
- `affixes` 第一项为主词条，之后最多三项。
- `greaterAffixes` 与设计文档中的 rank 3/4/5 顺序一致。
- 初版装备图标可继续使用 `item/unknown.png`，后续由用户统一替换。

### 4.5 状态数据与脚本

预计新增的主要永久状态包括：

- 境界：`swordcraft_rank_1`、`swordcraft_rank_3`、`swordcraft_rank_4`。
- 绝世卡：`sword_spirit`。
- 连斩装备：七星剑主状态、首张多段段数、连斩剑意增幅、连斩后迅捷。
- 身法装备：金丝剑穗主状态、飘忽剑意。
- 养剑装备：温玉剑鞘主状态、保留剑意。
- 剑意装备：剑意守御、剑意释放护甲。
- 其他按机制字段无法实现的首张飞剑收益、剑丸产出保底等状态。

永久状态采用“状态数据 + 状态脚本 + 本地化 + 图标 + 被动绑定”五层同步。行为参数放在状态数据，脚本不写死数值。

### 4.6 本地化

同步维护：

- `battlecard.json`：普通/绝世词条描述、`uniquecard_` 卡名、剑意关键词。
- `status_effect.json`：`sword_intent` 和全部永久状态的名称、描述。
- `passive.json`：境界、分支、装备词条效果行。
- `item.json`：五件装备名称与 flavortext，写清机制、代价和特殊口径。
- 如新增属性或机制说明出现在角色面板，同步 `character.json` 与 `battle.json`。

## 5. Dart、Hetu 与校验器同步范围

### Dart 机制层

预计涉及：

- `lib/scene/battle/card_cost.dart`：资源互通、首张费修、队列预占口径。
- `lib/scene/battle/character.dart`：多段上下文、剑意预测、资源封锁、驱散/追加攻击支撑、产出后与飘忽时机。
- `lib/scene/battle/battle.dart`：保留历史、额外回合抽牌、首张规则模拟和结算边界。
- `lib/scene/battle/hand_zone.dart` 或相关展示代码：仅在现有费用显示无法表达新规则时调整，不新增另一套支付逻辑。

Dart 只实现通用机制，不出现具体卡牌、装备或天赋 id。

### Hetu 内容层

预计涉及：

- `scripts/main/cardgame/card_script.ht`：剑意获得、连斩、保留收益、驱散、动态多段攻击等。
- `scripts/main/cardgame/status_script.ht`：剑意、境界、装备状态行为。
- `scripts/main/cardgame/battle_character.ht`：新增外部 API 声明。
- `scripts/main/data/character/battle_entity.ht`：新机制字段透传与聚合。
- `scripts/main/data/item/`：仅在战外养剑阶段处理装备等级和破境。

### 校验器

- `utils/data_validate/game_data_validate.dart`：新增机制字段结构、状态回调时机、卡牌字段和引用检查。
- `utils/data_validate/passive_tree_validate.dart`：实际排布御剑节点后再处理连通性，不在内容阶段顺带修复历史悬空节点。

## 6. 美术资源计划

- `sword_intent` 使用现有 `icon/status/sword_damage.png`，不生成、不替换。
- 永久状态图标在实施时使用 image-gen skill 的 Gemini 后端与 `--no-style`，缩放到 150×150，并检查小尺寸可辨性；路径统一为 `icon/status/permanent/`。
- 普通状态的小像素图标不调用生图 skill。若第 4 节实施中确需新增除剑意外的普通状态图标，单列资源清单并注明“由用户后期统一手工处理”。
- 绝世卡专属插画按卡牌 skill 同步 `kBattleCardIllustrations` 与 `illustration_` 本地化；不以状态图标代替卡牌插画。
- 绝世装备初版使用占位图，不因美术阻塞数据与战斗验证。

## 7. 分阶段实施顺序

### 阶段 1：公共战斗机制

- 落地剑意、多段上下文、保留历史、剑气产出登记。
- 完成动态费用互通和首张费修的底层设计与测试。
- 先以最小测试数据验证机制，不批量填写御剑内容。

### 阶段 2：境界主轴与普通内容

- 落地五个境界节点。
- 调整普通卡并完成十条随机额外词条。
- 完成剑气、剑意、连斩、养剑的基础战斗闭环。

### 阶段 3：绝世卡牌

- 按论剑、七星剑阵、藏剑、一剑破万法、剑灵附体、剑道千秋的顺序实施。
- 一剑破万法之前完成驱散 API；七星剑阵之前完成资源封锁；剑灵附体之前完成追加攻击队列。
- 每张卡同时完成普通/太古描述、固定成长测试和实际战斗验证。

### 阶段 4：绝世装备与共享分支

- 完成五件装备及其永久状态、参数机制和图标。
- 落地剑影分光、踏雪无痕、气剑同源；复用两个元素分支。
- 验证装备与公共词条、境界节点的叠加不会重复触发。

### 阶段 5：战外养剑与天赋树接入

- 先实现装备等级提升与破境路径，再接入养剑分支。
- 将境界和分支被动分配到天赋树，处理连线与共享节点。
- 运行天赋树连通性校验，并单独处理既有历史问题，不混入战斗内容修复。

## 8. 验收与测试矩阵

### 构造与数据

- 十条普通随机词条都有合法太古配置，元素限定词条不会落到非元素卡。
- 六张绝世卡、五件绝世装备均为 1 主 + 最多 3 固定额外词条。
- rank 1/2 解锁数量正确；rank 3/4/5 太古数量分别为 1/2/3。
- 高起始境界直接生成与逐级成长的结果一致；主词条永不太古。
- 数据校验器无错误，脚本回调、状态引用和本地化键完整。

### 剑意与连斩

- 剑意只强化剑法和御剑术，每段生效，整牌结束只消耗一次。
- 负优先级获得的剑意能用于本牌；非攻击牌不消耗剑意。
- 无伤害的一剑破万法仍消耗剑意。
- 卡面预测与实际确定性伤害一致。
- 首张多段段数加成只触发一次，额外段正常触发护甲、破绽和剑意。

### 保留与费用

- 新抽到的保留牌不满足“从上回合保留至今”；真正留手后满足。
- 打出或弃置后保留历史清除；额外回合保留规则一致。
- 保留减费在支付前生效，入手级联重算不叠加，离手后正确还原。
- 藏剑 +1 与额外词条 -1/-2 按来源独立结算并在到期后清理。
- 首张费修不会被出牌队列重复利用。

### 资源与回合

- 凝气首次行动按身法产气，之后按上回合产气牌数量产气。
- 结丹只扩展拳法和飞剑的产气身份，不改变卡牌类型或剑意适用范围。
- 还婴对每张产气牌只获得一次迅捷。
- 气剑同源支付顺序正确；N 可由互通色和太极补足，X 只计算本色。
- 剑气/灵气阈值、剑丸保底、止戈/逆灵之气不被互通规则混淆。
- 七星剑阵只封锁本回合后续实际获得，不误删已有资源或下回合登记资源。
- 飘忽转化和额外回合效果各触发一次，抽牌仍受手牌上限约束。

### 绝世与装备

- 七星剑阵全部段数完成后消耗剑意，未击杀才登记下回合资源。
- 一剑破万法只驱散允许的状态，按种数结算，没目标时抽牌。
- 剑灵附体每回合只追加一次，追加攻击走完整伤害管线并结算生命代价。
- 剑道千秋的保留飞剑、元素飞剑、实际支付飞剑和打出后代价均正确。
- 剑意守御与消耗剑意转护甲按各自每回合限制触发。

### 完整场景

除脚本级测试外，至少增加一组真实 `BattleScene` 集成验证，覆盖：

1. 武器牌产气 → 下回合支付 → 多段剑意爆发。
2. 保留跨回合 → 减费/升级 → 剑道千秋。
3. 迅捷额外回合 → 资源重新产出 → 每回合效果不重复或不错误漏发。
4. 气剑同源下玩家队列与敌方 AI 的支付一致性。

## 9. 文档同步与验证命令

实际实施各阶段时，同步更新受影响文档，不作为事后可选工作：

- `docs/docs/how2play/rpg/`：御剑玩法、剑意、保留、资源互通、连斩和新绝世规则。
- `docs/docs/mod/battle/`：新机制字段、回调时机、伤害明细和脚本 API 契约。
- `.agents/context/battle_system.md`：已实现的御剑机制与当前进度，不提前写入未落地内容。
- `.agents/skills/`：仅在新机制改变既有内容制作约定时同步。
- `docs/docs/how2play/rpg/battle/readme.md`：顺带修正飞剑卡牌类型与旧费用阶梯的现存偏差。
- `docs/docs/how2play/rpg/battle/resource/readme.md`：移除已经落地节点仍标为规划中的旧描述。

实施时按改动范围运行：

```bash
python build.py
flutter analyze
dart run utils/data_validate/game_data_validate.dart
dart run utils/data_validate/passive_tree_validate.dart
flutter test
```

最后一项天赋树校验只在实际修改树结构时作为本阶段验收；既有历史错误应单独记录，不通过删减御剑内容规避。
