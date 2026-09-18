# 符箓卡牌重构计划

范围：符箓（scroll）从"原地转化原卡"改为"复制为独立消耗品卡牌"；ephemeral 卡组上限强制；战斗中 ephemeral 卡用后即碎（粒子动画）；符箓使用次数计数与符纸充能；默认卡（blank_default）赋予基础拳法效果。

前置共识（已与作者确认）：

1. 符箓不再摧毁原卡：转化产出原卡的一个副本，原卡保留在卡库中。
2. 符箓副本 `isEphemeral = true`，加入卡组时受 `kDeckEphemeralCount`（3）数量限制（强制，报错拒绝）。
3. isEphemeral 卡牌在战斗中**打出后**不进弃牌堆，直接消失并播放卡牌碎裂粒子动画；未打出的 ephemeral 卡行为不变（回合末弃牌、可再次抽到）。
4. 战斗结束后，符箓的使用次数 -1；次数为 0 的符箓视为无效卡，战前与其他无效卡一样被替换为默认卡。
5. 空白符纸（scroll_paper）可以给符箓补充使用次数。
6. 使用次数以 `(1/3)` 形式直接显示在符箓卡牌标题上。
7. 默认卡效果：拳法，固定造成 角色境界 × 5 的伤害。

---

## 现状盘点

### 符箓转化（`scripts/main/binding/player.ht:155-182` `Player.craftScroll`，入口 `lib/scene/card_library/card_library.dart:706-745`）

- 当前为**原地变异**：`hero.cardLibrary.remove(card.id)` → 同一对象改 id/name(`xx（符）`)/genre='scroll'/rank=0/isEphemeral=true —— 原卡消失，且**新 id 没有加回 cardLibrary**（重进卡牌库丢卡、战斗 getDeck assert 失败）。
- **不消耗 scroll_paper**（`card_library.dart` 的 `paper` 参数未使用；对比鉴定卷轴在 `:539-543` 有 `Player.lose`）。
- 当前符箓无使用次数概念：战斗结束直接销毁（`battle.dart:1359-1372` 遍历 heroDeck 中 `isEphemeral` 卡调 `Player.dismantleCard`）。

### ephemeral 上限

- `kDeckEphemeralCount = 3`（`lib/data/common.dart:403`）；UI 有"消耗牌数量 n/3"显示（`card_library.dart:346`）。
- **未强制**：`deckbuilding_zone.dart:363-366` 检查条件误写为 `cardData['category'] == 'ongoing'`（数据中不存在该类别），且只 `engine.warning` 不阻止。

### 无效卡/默认卡

- 替换逻辑：`battle.dart:285-309` `getDeck`（仅英雄侧）：`GameLogic.checkRequirements(data, checkIdentified: true)` 不通过 → 替换为 `_createBlankCard()`；卡组不足 `kBattleDeckSize` 时补白。战前提示弹窗已存在（`prebattle_card_invalid_replaced` 等 locale）。
- `blank_default`（`cards.json5:49-54`）无 script/category/valueData，打出什么都不发生（仍扣费 1 无色）。本地化名"什么都不做"（`battlecard.json:8`）。

### 战斗内卡牌数据流

- 战斗卡由 `GameData.createBattleCard(data, deepCopyData: true)` 深拷贝创建，**战斗内修改不回写 cardLibrary**；计数结算需在战斗结束时显式回写。
- ephemeral 卡打出后目前进弃牌堆（`battle.dart:1086-1091`），回合末清手（`:1270`），重开洗回（`:756-759`）。

### 粒子效果

- 项目中无 Flame ParticleSystemComponent 先例；胜利彩带为自绘组件 `ConfettiEffect`（`../samsara-engine/lib/effect/confetti.dart`，手写 update/render 的重力旋转淡出粒子），用例 `lib/scene/mini_game/difference/difference.dart:278-283`，priority 常量参考 `lib/scene/mini_game/common.dart:10`（`kConfettiPriority = 10000`）。碎裂效果照此模式自绘。

### 充能参考实现

- 物品充能机制（chargeData `{current, max, shardsPerCharge}` + 灵石兑换 + 右键菜单）：`lib/logic/logic.dart:1269-1319` `onChargeItem`、UI 入口 `lib/widgets/character/stats_and_item.dart:67-68`。**主游戏物品均未接入**（仅 scripts/story 有一例），作为卡牌充能的结构参考。

### 其他顺带发现（本次不修，记录在案）

- `deckbuilding_zone.dart:93-105` `isRequirementMet` 循环中 `valid = warning == null` 互相覆盖，只有最后一张卡的判定生效。
- `card.ht` 的 `upgradeCard` 词条脚本函数目前无调用方。

---

## 任务一：符箓转化改为复制（craftScroll 重构）

- 脚本侧 `Player.craftScroll` 重写：不再变异原卡，而是**深拷贝原卡数据**生成新卡——新 id、`name = '${原名}（符）'`、`genre = 'scroll'`、`rank = 0`、`equipment = null`、`isEphemeral = true`、附加 `chargeData = {current: kScrollMaxCharges, max: kScrollMaxCharges}`；加入 `hero.cardLibrary`；原卡不动。
  - 深拷贝：hetu 侧若无现成深拷贝工具，则由 Dart 侧（`card_library.dart`，有 `utils.deepCopy`）完成拷贝与字段改写后调脚本注册入库，两侧分工以实施时确认为准。
  - 词条（含打造过的额外词条与数值）随拷贝完整保留；rank 归 0 但词条数值已烘焙，不受影响。费用按 rank 0 重算（全无色 1 点）。
- **修复符纸不消耗**：转化消耗 1 张 scroll_paper（`Player.lose`，参照鉴定卷轴 :539-543 的写法）。
- `kScrollMaxCharges` 新常量（固定 3），加入 `lib/data/common.dart` 并按既有约定经 `lib/data/constants.dart` + `scripts/main/binding/constants.ht` 导出。

## 任务二：使用次数显示与符纸充能

- 卡面标题：`lib/data/game.dart` `createBattleCard` 组标题时，若 `data['chargeData'] != null` 则追加 `(${current}/${max})`。
- 充能入口：卡牌库中符箓卡与空白符纸的操作（与 craftScroll 同一打造入口附近）——使用 1 张 scroll_paper 使 `chargeData.current +1`（不超过 max）；新脚本函数如 `Player.rechargeScroll(cardId)`，含符纸消耗、上限检查与提示文案。
- 次数为 0 的符箓允许保留在卡库/卡组中（战前会被替换为默认卡），是否允许"充能复活"——允许（这正是符纸的用途）。

## 任务三：ephemeral 卡组上限强制

- `deckbuilding_zone.dart` `tryAddCard`：删除错位的 `category == 'ongoing'` 检查，改为统计卡组中 `data['isEphemeral'] == true` 的数量，达到 `kDeckEphemeralCount` 时返回错误字符串拒绝加入（沿用现有弹窗模式，locale 复用 `deckbuilding_limit_ephemeral` 或新增满额提示）。
- `lib/logic/logic.dart` `checkDeckRequirement` 补充 ephemeral 超限校验（战前警告用）。

## 任务四：战斗中 ephemeral 卡用后碎裂消失

- 打出结算处（`battle.dart` `_playCard` 流程，当前 `:1086-1091` 进弃牌堆的分支）：若 `card.data['isEphemeral'] == true`，改为——从手牌移除、播放碎裂动画、**不进弃牌堆**，并在 `card.data` 上标记 `usedInBattle = true`（供任务五计数结算识别）。
- 碎裂粒子组件：新建 `lib/scene/battle/` 下自绘组件（参考 `ConfettiEffect` 模式：若干矩形/多边形碎片，以卡面主色或卡框色飞出+旋转+重力下落+淡出），priority 用战斗场景现有高层级（参考 `kTopLayerAnimationPriority`）；动画结束后组件自毁。卡面 sprite 本身隐藏/移除的时机与动画衔接。
- 未被打出而留在手牌的 ephemeral 卡：回合末 `clearHand` 正常进弃牌堆、洗牌可再抽到（共识 3）。
- 敌方卡组不涉及（敌方无符箓）；练习模式不涉及计数。

## 任务五：战斗结束计数结算 + 无效符箓替换 + 默认卡拳法化

- 战斗结束结算（`battle.dart` `_onBattleEnd` 区域，替换现有"符箓一律销毁"的 :1359-1372 逻辑）：遍历 heroDeck 中 `isEphemeral == true && usedInBattle == true` 的卡，按 id 在 `hero.cardLibrary` 中找到原卡，`chargeData.current -1`（更新卡库数据与标题显示缓存；`engine.clearCachedScene(Scenes.library)` 的缓存失效逻辑保留）。
  - 未使用的符箓不扣次数。
- 无效卡判定扩充（`getDeck`，`battle.dart:285-309`）：`chargeData.current <= 0` 的符箓与未鉴定/境界不足/装备需求不满足同等处理，替换为默认卡（复用现有 `_replacedCardCount` 与弹窗提示链路，提示文案可补充"符箓次数耗尽"情形）。
- 默认卡拳法化：
  - `cards.json5` 的 `blank_default`：补 `category: 'attack'`、`kind: 'punch'`、`cardType: 'unarmed'`、`damageType: 'physical'`、`script: 'attack_rank_scaled'`；本地化名称改为"基础拳法"（`battlecard.json`），描述说明"固定造成角色境界 × 5 的伤害"。
  - `card_script.ht` 新增 `attack_rank_scaled`：`baseValue = self.data.rank * 5`（读**角色**境界而非卡牌境界，valueData 无法表达，故用脚本），其余字段（kind/cardType/damageType/isMain）与 `attack` 相同。
  - 木人/练习模式卡组改用新建的 `placeholder` 卡（保持"什么都不做"，木人无攻击动画），原填充点（`lib/logic/character.dart:717-722`、`scripts/main/event/game.ht:76-78`）同步替换。

## 任务六：文档与本地化同步

- `docs/docs/how2play/rpg/battle/card/readme.md` 符箓小节重写（新定位：消耗品复制卡，次数制，符纸充能）。
- 本地化新增/修改：符箓名称后缀（已有 `scroll2`）、充能提示、次数耗尽提示、blank_default 新名称与描述、ephemeral 满额提示。

---

## 开放问题（已定案）

1. **计数扣减时机**：仅战斗中**实际打出过**的符箓在战斗结束时 -1（未打出不扣）。
2. **使用次数上限**：固定 3（与 ephemeral 卡组上限数值相同纯属巧合，两者是独立概念）。
3. **命名**：该特性中文名为「**易逝**」——"消耗"已被消耗品/丹药与 consumed 回调占用，"易逝"专指卡牌本身用后即碎；代码字段沿用 `isEphemeral`，UI 显示"易逝卡牌 1/3"。
4. **木人/练习模式**：新建 `placeholder` 卡保持"什么都不做"（木人无攻击动画）；`blank_default` 则拳法化，用于无效卡替换。
