# Phase 5 报告：卡牌与词缀数据复核

> 所属计划：`plan-battle_qi_cost_rework.md` §8 Phase 5

## 5.1 缺省推导卡复核

逐卡导出全部 79 张卡复核后结论：**当前数据中不存在"rank 0 且有流派"的卡**——rank 0 的 19 张卡（17 张通用基础卡 + sabre_defend + draw_cards）全部无流派，缺省推导天然全无色（cost=1）。因此**选择"调整推导规则"而非逐卡标注**：在 `deriveBattleCardCost`（game.dart）与 BattleCard 构造器（card.ht）各加一行保护——rank 0 一律全无色，防御未来数据出现 rank 0 流派死卡。rank ≥ 1 的缺省流派卡仅 2 张：`reduce_resist_poison`（cost 1 + 煞气×1，专职 debuff 非基础工具卡，维持）与 `wind_buff`（Phase 2 已显式 spell×1）。**draw_cards（绝世 rank 0）按 exotic 空间暂不加费用**，全无色 cost 1 维持现状。

## 5.2 产气卡调整清单

| 卡                                    | 旧 → 新                                                                | 理由                                                                                                                                                             |
| ------------------------------------- | ---------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| gain_energy_positive_life             | 数值 1+0.2/级 → **1+0.1/级**                                           | rank 0 满 15 级时原可产 4 层元气（=4 点万能费+4 次回血）仅耗 1 费，费效远超 mana 卡（2 费产 3~6 灵气）；改后满级产 2 层，与 genre 产气卡拉平，"低量通用产气"定位 |
| 8 张 gain*yangqi*\*                   | 新增显式 **`qiCost: {}`**                                              | 产气工具卡任何构筑可用（原本就无流派推导全无色，显式标注防未来误加流派）                                                                                         |
| affix_gain_buff_crit/ward/shield 文案 | "豪气"/"清气"/"浩然之气" → **"幸运"/"辟邪"/"护盾"**（battlecard.json） | 状态已改名                                                                                                                                                       |

## 5.4 敌方可用性抽查

`generateBattleDeck` 按 cultivationFavor 集中取流派卡（rank>0 时 genre=favor）→ NPC 卡组约 65% 流派卡带 1 点有色费用；而 enable_chakra/rage/karma 只来自 passives（药剂/天赋数据），**普通 NPC 无滞后产出、无池提取**（灵气至少有 spirituality/10 战斗开始产出 + enable_mana）。结论：NPC 非悟道流派会出现"整手有色死卡"——敌方 AI 费用过滤（Phase 2）保证不崩溃但被动挨打。**标注为遗留问题，归 Phase 6**（计划已安排 NPC 按 cultivationFavor 获节点被动）。

## 修改文件

`assets/data/cards.json5`（vigor 数值 + 8 张 qiCost）、`assets/data/card_affixes.json5`（启用 3 词缀）、`assets/locale/zh/rpg/battlecard.json`（2 处旧称）、`lib/data/game.dart`（rank 0 推导保护）、`scripts/main/cardgame/card.ht`（同上 + 编译修正），及构建产物 main.mod/story.mod。

## 遗留问题汇总

1. NPC 有色死卡（上节，Phase 6）。
2. draw_cards 的 exotic 费用设计未定（本 Phase 暂不动）。
3. 产气卡 affix 描述文案（"获得剑气"等 locale 键原有，无需新增）与卡面 exhaust 时代旧文案归 Phase 7 统一清理（已完成）。
