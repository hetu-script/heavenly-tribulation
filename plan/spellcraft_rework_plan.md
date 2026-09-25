# 悟道流派重构 + 状态重命名落地计划

> **后续更名（已落地）**：`ziwei_doushu` → `spellcraft_draw_cards_reduce_cost`（效果并入抽牌脚本 `draw_cards`，由词条 `reduceCost`/`filter` 条件子表驱动，独立 external `ziweiDoushu` 已移除）；`wanfa_guizong` → `spellcraft_ultimate_spell`；四个分支节点 `skilltree_branch_guiyuan/tiandao/shouyi/wuxing` → `skilltree_branch_draw_1/draw_2/element_1/element_2`；`handleWuxingRotation`/`wuxingRotation` → `handleElementRotation`/`elementRotation`。同时修复 `retain`/`isEphemeral` 未从主词条合并到卡牌实例的问题（card.ht）。本文其余内容为当时计划的原始记录，文中旧 id 已批量替换为新 id。
>
> **观星机制重设计（已落地）**：原规则（选一张入手、其余沉底、牌库空则洗牌）在抽 5 张+回合清手牌框架下不成立——沉底无意义、直接入手送卡差偏强。新规则：选中牌放回【牌库顶】、未选牌进【弃牌堆】、牌库为空不触发（观星永不洗牌，不足 3 张则全显）。分支「天道推演」在回合开始抽牌【前】触发，选中牌随本回合抽牌入手（替代一张随机抽牌，不产生卡差）；另新增卡牌词条版 `scry`（CardScript.scry + BattleCharacter.scry 绑定 + battle_character.ht 声明），打出时触发，供后续卡牌数据使用。

## 一、对用户修改的审查意见

### 1. status_effect.json 重命名

**肯定**：元素异常统一为七元素家族（金木水火土风雷）并与五行设定咬合；描述改为确定性行为（冰缓恒迟钝、幻觉恒缓慢），比随机版本更适合战术规划。

**问题（均已在 Part 1 处理）**：

1. 拼写不一致：status_effect.json / common.dart 用 `ailement`，passives.json5 keywords 与项目既有命名（ailment_charge/ailmentThreshold/ailmentMultiplier/docs）用 `ailment` → **统一为 ailment**（已与用户确认）。
2. `lib/data/common.dart:399-401` kDebuffs 残留 `injury_external/internal/hallucination` 三个旧 id（locale 键已删，属漏改）。
3. 新描述隐含行为修改，现状脚本不符 → 按新描述同步（已与用户确认）：
   - 中毒：现在永不自动衰减 → 回合结束移除 1 层
   - 冰缓：现在随机缓慢/迟钝 → 恒转迟钝
   - 幻觉：现在随机且不耗层 → 每层转 1 点缓慢并耗尽层数
   - 删除「获得元气减内伤」「获得灵气减幻觉」两个消层脚本
   - 治疗随机驱散机制（character.dart:774-783）**保留不动**，仅不再写进负面效果描述，改在治疗相关文本处说明（用户指示）
4. 过渡性不一致（本次不动，仅记录）：七元素映射里金（流血）/土（内伤）/风（幻觉）没有对应 damageType（现有元素伤害仅 fire/ice/lightning/poison），这三种异常暂时只能经 kDebuffs 随机池进入战斗，无法被元素伤害触发；`elementType` 卡牌字段目前是死数据。建议未来把异常触发从 damageType 驱动改为 elementType 驱动。
5. `plan/skilltree/vitality.md:26` 残留旧 id `element_dot_poison`。

### 2. spellcraft.md 设计修改

**肯定**：

- 境界节点命名与 locale 同步，一致性好。
- 结丹改为「未用灵气转随机元素伤害」——消除了旧「灵气保留」与现行"阳气持有者下回合开始清空"规则的冲突，且 `character.dart:1246` 的 `_settleTurnEndResources` 空钩子就是为此预留的。
- 万法归宗定为雷系单发，与御剑多段随机元素核弹形成镜像；「万法归一」改名「一气化三清」消除了命名混淆。
- 返朴归元重定义为紫微斗数入手，比全局保留规则克制；紫微斗数从绝世卡池移到分支奖励，获取路径清晰。
- 五行轮转明确为灵气+1，可落地；抱真守一放开同类限制，适配多元素构筑。

**注意点（实现假设，执行时可调整）**：

1. 五气朝元轮转覆盖水火土风雷、不含金/木——与七元素异常映射一致（金=流血属物理系、木=中毒属炼魂系），合理；但悟道卡池现有 `plant_control`（木系）kind 被排除在外，确认是否有意。
2. 五行轮转按「每回合内每使用一种不同的元素牌，灵气+1」实现（与额外词条"本回合已使用过不同元素牌"同口径）。
3. 分支名「返朴归元」与效果「精准抽牌」主题偏移（归元关键字原指保留/蓄力）；抱元功已从绝世卡移除、「手牌批发保留」由御剑藏剑承接——命名体系轻微漂移，建议后续统一。
4. 紫微斗数费用未写明，按计划按 0 费、消耗品（isEphemeral=打出碎裂）处理。
5. swordcraft.md 还婴、vitality.md 结丹被清空待填；vitality.md 主词条"对对手施加 X 层指定阴气"尚未命名——均记录，不在本次范围。

**顺带发现的既有问题（报告项）**：

- `passive_skills.json5:37` track_4_0（御剑凝气）错误引用 `spellcraft_rank_1`——本计划内修复（该词条即将获得真实效果，不修会让御剑玩家白拿悟道效果）。
- 御剑 rank 节点引用不存在的 `swordcraft_rank_2..5`（passive_skills.json5:63,89,115,141），解锁会触发 `battle_entity.ht:489` 的 assert——留待御剑阶段。
- `assets/locale/zh/rpg/passive_skills.json:40` 键名 typo `passivetree_bodyforge_rank_7_comment`。

---

## 二、Part 1：状态重命名落地

### 步骤 1：拼写统一 ailment

- `assets/locale/zh/rpg/status_effect.json`：`status_element_ailement` → `status_element_ailment`；`status_ailement_*` → `status_ailment_*`（fire/lightning/ice/poison/bleeding/internal_injury/hallucination 共 7 组键，描述文本不动）。
- `lib/data/common.dart:399-405` kDebuffs：`injury_external`→`ailment_bleeding`、`injury_internal`→`ailment_internal_injury`、`injury_hallucination`→`ailment_hallucination`、`ailement_*`→`ailment_*`（4 个）。

### 步骤 2：status_effect.json5 数据改名（505-582 行区段）

7 个状态条目改 `id`、`title`/`description` 本地化键（`status_ailment_*`）、`script`、`icon`：

- `injury_external` → `ailment_bleeding`（script→`ailment_bleeding`，callbacks 保持 `self_attacked`）
- `injury_internal` → `ailment_internal_injury`（script→`ailment_internal_injury`，callbacks 移除 `self_gained_energy_positive`，保留 `self_used_card`）
- `injury_hallucination` → `ailment_hallucination`（script→`ailment_hallucination`，callbacks 移除 `self_gained_energy_positive`，保留 `self_turn_start`）
- `element_dot_fire/lightning/ice/poison` → `ailment_fire/lightning/ice/poison`（script 统一 `element_dot`→`ailment`，callbacks 不变）
- icon 字段同步为新文件名（见步骤 5）。

### 步骤 3：status_script.ht 函数改名 + 行为同步

- 改名：`injury_external_self_attacked`→`ailment_bleeding_self_attacked`（231）、`injury_internal_self_used_card`→`ailment_internal_injury_self_used_card`（235）、`injury_hallucination_self_turn_start`→`ailment_hallucination_self_turn_start`（247）、`element_dot_self_turn_start`→`ailment_self_turn_start`（270）、`element_dot_self_turn_end`→`ailment_self_turn_end`（286）。
- 删除：`injury_internal_self_gained_energy_positive`（242-245）、`injury_hallucination_self_gained_energy_positive`（257-260）。
- 行为修改：
  - `ailment_hallucination_self_turn_start`：改为 `addStatusEffect('speed_slow', amount: effect.amount)` 后 `removeStatusEffect(effect.id)` 耗尽。
  - `ailment_self_turn_end` 冰缓分支：恒 `addStatusEffect('dodge_clumsy', amount: 1)`（去掉随机）；中毒分支：末尾加 `removeStatusEffect(effect.id, amount: 1)`。
- 注释更新：文件头时机表（30/36 行的 gained_injury 提及）、DOT 注释块（262-269，改写毒/冰缓/幻觉的新行为；"治疗时统一随机驱散"一句保留，机制仍在）。

### 步骤 4：Dart 侧同步

- `lib/scene/battle/character.dart:1038`：`'element_dot_$damageType'` → `'ailment_$damageType'`。
- `lib/data/game.dart:1380`：`'status_element_dot_${affix['damageType']}'` → `'status_ailment_${affix['damageType']}'`。
- 治疗驱散代码块（character.dart:774-783）**保留不动**。

### 步骤 5：图标文件改名

`assets/images/icon/status/`：`element_dot_fire/lightning/ice/poison.png` → `ailment_fire/lightning/ice/poison.png`；`injury_external/internal/hallucination.png` → `ailment_bleeding/internal_injury/hallucination.png`。改名前 grep 确认这些文件名无其他引用。

### 步骤 6：文档同步

- `docs/docs/how2play/rpg/battle/readme.md`：224 行旧 id 列表改为新 id；233-244 机制描述同步新行为（毒衰减、冰缓/幻觉确定性、删能量消层提及）；治疗驱散机制保留，其说明从负面效果描述中移除、改在治疗/恢复相关文本处补充（"每次恢复生命时，随机减少 1 层持有的负面效果"）。
- `docs/docs/how2play/rpg/battle/resource/readme.md:36-37`：删"获得元气减内伤、获得灵气减幻觉"。
- `docs/docs/mod/battle/readme.md:61`：gained_injury 时机条目处理（该时机 Dart 从未派发，删除或改写为 gained_debuff 说明）；全文复查旧 id。
- `plan/skilltree/vitality.md:26`：`element_dot_poison` 改为新表述。

### 步骤 7：Part 1 验证

- `flutter analyze` 无错；`python build.py` 重编译 hetu 脚本；grep 全仓复查 `element_dot`、`injury_`、`ailement` 无残留（计划文档内的历史叙述除外）。

---

## 三、Part 2：悟道境界节点 + 分支节点实现

总原则：所有节点效果通过 `character.passives` 中对应词条的**存在性**检查触发（equipment_sword 先例）；NPC 无天赋树，天然不触发。境界节点词条挂进天赋树，分支节点只建数据与效果代码、**不进天赋树**（用户后续手动排布）。

### 步骤 0：计划存档

将本计划复制到 `plan/spellcraft_rework_plan.md`（AGENTS.md 约定）。

### 步骤 1：passives.json5 数据

- 修 `spellcraft_rank_1`（1006-1010）description typo → `passive_spellcraft_rank_1_description`。
- 新增 `spellcraft_rank_2`/`_3`/`_4`/`_5` 标记词条（无 increment，priority 沿用 3799 序列，description 键 `passive_spellcraft_rank_N_description`）。
- 新增 4 个分支标记词条：`skilltree_branch_draw_1`（返朴归元）、`skilltree_branch_draw_2`（天道推演）、`skilltree_branch_element_1`（抱真守一）、`skilltree_branch_element_2`（五行轮转），description 键 `passive_skilltree_branch_*_description`。
- 顺带修复：`passive_skills.json5:37` track_4_0 移除对 `spellcraft_rank_1` 的引用（保留其 lifeMax）。

### 步骤 2：天赋树挂载（仅境界节点）

`passive_skills.json5` 五个悟道大节点的 passives 列表各追加 `{id: "spellcraft_rank_N"}`（保留 lifeMax）：track_4_4（483）→rank_1、track_8_8（504）→rank_2、track_12_8（525）→rank_3、track_16_8（546）→rank_4、track_20_4（567）→rank_5。

### 步骤 3：本地化

`assets/locale/zh/rpg/passive.json`：

- 更新悟道 rank_1..5 描述：①回合开始时，每 10 点灵力获得 1 点灵气 ②悟道牌灵气费用 -1 ③回合结束时，未使用的灵气每层造成 5 点随机元素伤害 ④每个回合开始时，轮流获得御水术、御火术、土遁、御风术、雷法的伤害 +10% ⑤战斗开始后将「绝世·万法归宗」洗入你的牌库。
- 新增 4 条分支描述（返朴归元=战斗开始将「紫微斗数」加入手牌；天道推演=每回合开始观星一次；抱真守一=使用元素牌后随机一张手牌元素牌升级；五行轮转=每回合每使用一种不同元素牌获得 1 点灵气）。

### 步骤 4：新卡牌数据（cards.json5 + battlecard.json）

头部注释登记新字段 `retain`（保留：回合结束不弃牌）。参照现有 isUnique 卡（85-175 行区段）新增：

- `spellcraft_draw_cards_reduce_cost` 紫微斗数：genre spellcraft、category buff、`retain: true`、`isEphemeral: true`（消耗=打出碎裂）、`coloredCost: {life: 0}`、script `spellcraft_draw_cards_reduce_cost`。**确认其不进入随机生成池**（参照 blank_default 的排除方式，必要时在 BattleCard 构造器过滤）。
- `spellcraft_ultimate_spell` 万法归宗：genre spellcraft、category attack、cardType spell、kind lightning_control、damageType lightning、isUnique、`retain: true`、`coloredCost: {spell: {base: 10, rankIncrement: 0}}`、script `spellcraft_ultimate_spell`、valueData 提供每层灵气伤害（base 8 起步，数值可调）。
- `assets/locale/zh/rpg/battlecard.json` 按现有模式补两卡的名称/描述键。

### 步骤 5：战斗机制——保留（retain）

`lib/scene/battle/battle.dart:720-729` `clearHand` 增加参数 `{bool keepRetained = false}`：为 true 时跳过 `card.data['retain'] == true` 的卡。回合结束调用点（1343）传 `keepRetained: true`；战斗重开清理（755-756）保持 false（全部回库）。

### 步骤 6：战斗机制——观星（scry）

- `battle.dart` 新增 `Future<void> scry(int count)`：取当前角色牌库顶 N 张（`deck.cards` 末尾，不足全取、不触发弃牌重洗）→ 英雄：参照 `card_library.dart:857-950` onOpenCardpack 的卡片排布/翻转动画，在场景中央展示并等待点选一张加入手牌区，其余按原顺序放回牌库底（列表头部）；敌方（预留）：自动取顶张。新增提示文本 locale 键。
- 触发点：`_startTurn` 中 `_prepareStatus(start_turn)`（battle.dart:1245-1251）之后，`currentCharacter` passives 含 `skilltree_branch_draw_2` → `await scry(3)`（常量 `kScryCardCount = 3` 入 common.dart，绝世装备"+1 张"后续在此加成）。

### 步骤 7：战斗机制——抽牌返回与紫微斗数改费

- `drawCardsToHand`（battle.dart:772-797）记录并返回所抽卡牌列表；`BattleCharacter.drawCards`（character.dart:1290-1300）相应透出。
- 新增 external 方法（绑定照抄 `character_binding.dart:95-97` drawCards 模式）：Dart 侧完成"抽 1 张 → 若 `cardType == 'spell' && category == 'attack'` 则将其 `coloredCost` 清零 → `refreshHandCardDescriptions()`（802-823）"，供 `spellcraft_draw_cards_reduce_cost` 脚本调用（避免把 CustomGameCard 对象暴露给 hetu）。

### 步骤 8：战斗机制——元素牌判定

Dart 私有辅助 `isElementCard(cardData)`：`cardData['elementType'] != null || {fire,ice,lightning,poison}.contains(cardData['damageType'])`（elementType 优先，激活死数据并覆盖七元素；damageType 兜底兼容未标 elementType 的旧卡）。

### 步骤 9：境界节点效果（character.dart / battle.dart）

- **凝气·太上感应**：`produceTurnStartResources`（character.dart:662-667）追加——passives 含 `spellcraft_rank_1` 时 `addStatusEffect('energy_positive_spell', amount: stats.spirituality ~/ 10)`（>0 才加；实现时核实灵力在 stats 中的键名）。
- **筑基·天道循环**：`getDeck`（battle.dart:267-316）组牌后——该角色 passives 含 `spellcraft_rank_2` 时，卡组内 `genre == 'spellcraft'` 的卡 `coloredCost['spell']` 减 1（下限 0；战斗卡费用已是求值后 int）。
- **结丹·阴阳五行**：实装 `_settleTurnEndResources`（character.dart:1246-1264）——passives 含 `spellcraft_rank_3` 且持有 `energy_positive_spell`：每层 5 点、火/冰/雷随机、受对方元素抗性减免（沿用草案的 changeLife 直扣方式，不算攻击），被动 id 用 `spellcraft_rank_3`，删除草案中 convert_to_vigor 分支并更新注释。
- **还婴·五气朝元**：新增 `handleElementRotation()`，在 `_startTurn` 的 start*turn 注入之后调用——passives 含 `spellcraft_rank_4` 时：先按 `data['elementRotation']` 记录移除上轮所授层数，再按 `[waterbend, firebend, earthbend, airbend, lightning_control][turnCount % 5]` 授予对应 `increase_damage*{kind}`×10 层并记录。常量`kElementRotationKinds`、`kElementEnhanceAmount = 10` 入 common.dart；实现时校准 turnCount 初值使首回合为御水术（waterbend）。
- **化神·万法归宗**：战斗开始 `getDeck` 调用点（battle.dart:443 附近）之后——hero passives 含 `spellcraft_rank_5` 时，参照 `_createBlankCard`（318-325）经 hetu `BattleCard(affixId: 'spellcraft_ultimate_spell')` 造卡、入牌库并洗牌。

### 步骤 10：分支节点效果

- **返朴归元**：战斗开始（同步骤 9 化神注入点）——passives 含 `skilltree_branch_draw_1` 时造 `spellcraft_draw_cards_reduce_cost` 加入英雄手牌区（翻开）。
- **天道推演**：步骤 6 的 scry 触发。
- **抱真守一 / 五行轮转**：`character.dart` `onUseCard` 末尾（全部词条脚本执行完、cardFlags 就绪后）追加——当前卡经 `isElementCard` 判定为元素牌时：
  - 含 `skilltree_branch_element_1`：从对应手牌区随机取一张元素牌，经 hetu `upgradeCard`（card.ht:609，参照 game.dart:1516-1518 的调用方式）升级，hero 侧随后 `refreshHandCardDescriptions()`。
  - 含 `skilltree_branch_element_2`：元素键（`elementType ?? damageType`）不在 `turnFlags['usedElements']` 集合中 → 入集合并 `addStatusEffect('energy_positive_spell', amount: 1)`（turnFlags 每回合自动清空，天然实现"每回合每种一次"）。

### 步骤 11：卡牌脚本（card_script.ht）

- `spellcraft_draw_cards_reduce_cost(self, opponent, affix, mainAffix)`：调用步骤 7 的新 external。
- `spellcraft_ultimate_spell(self, opponent, affix, mainAffix)`：读 `cardFlags['paidCost']['energy_positive_spell']`（已付 10 点，refund_cost 同款先例）+ `hasStatusEffect('energy_positive_spell')` 剩余层数 → `removeStatusEffect(force: true)` 清空 → 总耗费 × `affix.value[0]` 为 baseValue，damageDetails（damageType: 'lightning'，cardType: 'spell'）→ `opponent.takeDamage(...)`（参照 attack 脚本 21-29 与 convert_vigor_all 111-117 的写法）。

### 步骤 12：Part 2 验证

- `python build.py` 重编译 hetu → `assets/mods`；`flutter analyze` 无错。
- 数据校验：确认 unlock 悟道五个境界节点不再触发 assert；grep 确认新 id 拼写一致。
- 手动测试清单（用户侧执行）：新档/编辑模式点满悟道线 → 战斗内验证①回合开始灵气数 ②悟道牌费用-1 ③回合结束灵气转伤害 ④五气轮转增伤与更换 ⑤万法归宗在牌库且保留/耗尽灵气结算 ⑥分支词条临时赋予后验证观星/紫微斗数/升级/灵气+1。

---

## 四、执行顺序

Part 1（步骤 1-7）→ Part 2（步骤 0-12）。每部分结束后各跑一轮 `flutter analyze` + `python build.py`。
