# Phase 2 报告：结算核心

> 所属计划：`plan-battle_qi_cost_rework.md` §8 Phase 2

## 修正项（用户审查 Phase 1 后的要求）

**范围收窄** ✅ 未触碰 passive_skills.json5、passives.json5、lib/scene/card_library/、lib/widgets/character/stats.dart。

## Phase 2 任务

**2.1 费用数据落地** ✅

- game.dart 新增 `deriveBattleCardCost`（game.dart:1425-1461）：显式 qiCost 优先（cost = rank+1−Σ）；缺省推导有色 = ⌈(rank+1)/2⌉、无色 = ⌊(rank+1)/2⌋、无流派全无色、多色对半拆且余数给列表首位（avatar 奇数时多点给 unarmed）。`createBattleCard` 写入 `cardData['cost']`/`['qiCost']` 且卡面 `cost:` 用推导出的无色费用（game.dart:1481-1484, 1537）。
- card.ht BattleCard 构造器在 rank 定稿后计算 `this.cost`/`this.qiCost`（card.ht:136-165），逻辑与 Dart 侧一致（注释互相指引）。

**2.2 支付与检查（battle.dart）** ✅

- 新增 5 个辅助方法（battle.dart:807-905）：`_cardCostColored`、`_costYinStatusId`（无色↔死气、有色↔kOppositeStatus 反查）、`_effectiveCostNeed`（基础 + min(阴气, 2)）、`_canPayCardCost`（全有或全无；queued 参数把已入队卡牌费用一并累计，阴气增费按每卡单独计算后求和）、`_payCardCost`（支付前二次校验，先扣本色气、缺口自动扣 kWildcardStatusId，失败不扣任何东西并返回 false）。查询入口用现成的 `BattleCharacter.hasStatusEffect`（character.dart:253），未新增 getter。
- `_enqueueCard`：改为整队费用预占检查；`_playCard`：改走 `_payCardCost`，失败时退回手牌防御性兜底；敌方 AI（battle.dart:1184-1200）：过滤与扣费同步新逻辑。

**2.3 exhaust 删除与迁移** ✅

- card_script.ht 删除 10 个 `_exhaust` 变体；新增 5 个基础变体：`attack_slow`、`attack_clumsy`、`heal_lifeMax`（百分比回血，保持 wood_heal 语义）、`lifemax_buff`、`lifemax_debuff`。
- **valueData 语义结论**：9 个变体均为"value[0]=消耗量"前缀式，与基础变体索引不一致 → 迁移时统一删除首个 valueData 条目。唯一本质差异是 `heal_exhaust`（百分比 vs flat），用新基础变体 `heal_lifeMax` 保留百分比语义。`speed_quick_exhaust_defend`/`dodge_nimble_exhaust_defend` 的 value[0] 兼作产气量，恰好与基础变体语义一致，删除消耗条目后自然对齐。
- **迁移卡数**：脚本驱动的 51 张全部迁移 + `wind_buff`（漏网之鱼，见下）= **52 张**。数量 = ⌊base+increment×minLevelForRank(rank)⌋ 截断到 rank+1；51 张原卡均为 rank 1（原消耗 1~2）。**全有色卡仅 1 张**：`kick_attack_exhaust_rage`（原消耗 2 = rank+1 → `{unarmed: 2}`，无色 0），无"消耗量 > rank+1"需截断的卡。同时移除 51 张卡的 `resourceType` 死字段与 `exhaustResource` 关键字（产气卡的 resourceType 保留）。

**2.4 过渡期卡面文本** ✅ getBattleCardDescription 在描述区附加"另需：剑气×2、煞气×1"行（game.dart:1389-1406），颜色名复用 `status_energy_positive_*` 键，多色用"、"分隔。新增本地化键 `battlecard_qiCost_hint`（"另需：{0}"）与 `enumeration_separator`（"、"）。

**2.5 验收** ✅ dart analyze 全仓仅 3 条预存 pubspec 警告；`python build.py` 两模组编译成功（反查 main.mod 确认 10 个 exhaust 函数清零、5 个新函数已编入）；数据自检脚本程序化验证 80 张卡：**DATA CHECK OK**（52 张显式 qiCost 不变量全过、无 exhaust 脚本/关键字残留、valueData 长度与脚本匹配）。

## 修改文件

`assets/data/cards.json5`、`assets/data/status_effect.json5`、`assets/locale/zh/rpg/battlecard.json`、`lib/data/game.dart`、`lib/scene/battle/battle.dart`、`scripts/main/cardgame/card.ht`、`scripts/main/cardgame/card_script.ht`，及构建产物 `assets/mods/main.mod`、`story.mod`。

## 意外发现与处理（重要）

1. **wind_buff 漏网**：script 已是基础变体但 valueData 是 exhaust 三段式（描述也一直声称"消耗灵气"）——旧系统中它从未真正消耗，属预存数据 bug。已按 exhaust 卡同法迁移（`{spell: 1}`），等于补上描述一直声称的费用。
2. **flying_sword_defense / scripture 缺产气条目**：原 valueData 只有 [消耗, 护甲]，旧脚本下速度/闪避实际 +0。迁移时按同类卡补齐（速度/闪避 1/0.2），恢复其描述声称的设计意图。
3. **lifemax_debuff_exhaust 旧实现 bug**：`opponent.setLifeMax(self.lifeMax - X)` 用己方上限做基准（可能反而抬高敌方上限）。新基础变体 `lifemax_debuff` 修正为 `opponent.lifeMax - X`。
4. **sigil 的 resourceType 是非法 ID** `energy_positive_karma`（旧系统中 removeStatusEffect 静默无效=免费卡），按明显意图映射为 curse。
5. **draw_cards（绝世）**：keyword/描述声称消耗灵气但脚本从不消耗，是 unique 卡的设计残留，未动（exotic 费用归后续定夺）。`reduce_resist_poison` 的 resourceType/关键字是死数据（描述未声称消耗、脚本不消耗），已清除但未加费用。
6. **hetu 测试未写**：支付检查/无极抵扣/阴气增费逻辑在 Dart 侧（battle.dart），hetu 测试无法触达；`scripts/_tests/*.hts` 无任何运行器接入（build.py 跳过 `_` 目录），项目也无 Dart 测试基建（无 test/ 目录）。已用数据自检 + 静态分析 + 编译替代；建议实战验收时覆盖支付路径。

## 遗留（按计划属后续 Phase）

- 迁移卡的 affix 描述文案（"消耗 {0} 灵气：…"）与插值索引错位（interpolate 缺参只留占位符、不崩），归 Phase 7 本地化清理；卡面 pip 美术与"另需"行文案定稿同理。
- 卡面无色费用徽章对全有色卡显示 "0"，归 Phase 4 UI 处理（已在 Phase 4 完成）。
