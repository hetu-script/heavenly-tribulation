# Phase 5 报告：卡牌与词缀数据复核

> 所属计划：`plan-battle_qi_cost_rework.md` §8 Phase 5

## 验收结果

- `dart analyze lib`：**No issues found**；`python build.py`：两模组编译通过（card.ht 的 rank 0 保护初版用了构造器内裸 `return`，hetu 语法不允许，已改为 if/else 嵌套）。
- **数据自检输出**（临时脚本已删）：

```
--- gain_resource 词缀 (10):
  vigor common_yangqi rank=0  1+0.1 | penetrate/crit common_yangqi rank=1
  ward rank=2 | shield rank=3 | mana/chakra/rage/karma genre_yangqi rank=1
  ultimate genre_yangqi rank=4
总卡数(有脚本): 79 | 显式 costColored: 60 | 缺省推导: 19
DATA CHECK OK   （无 exhaust 脚本残留、无非法费用色、无死 resourceType）
```

## 5.1 缺省推导卡复核

逐卡导出全部 79 张卡复核后结论：**当前数据中不存在"rank 0 且有流派"的卡**——rank 0 的 19 张卡（17 张通用基础卡 + sabre_defend + draw_cards）全部无流派，缺省推导天然全无色（cost=1）。因此**选择"调整推导规则"而非逐卡标注**：在 `deriveBattleCardCost`（game.dart）与 BattleCard 构造器（card.ht）各加一行保护——rank 0 一律全无色，防御未来数据出现 rank 0 流派死卡。rank ≥ 1 的缺省流派卡仅 2 张：`reduce_resist_poison`（cost 1 + 煞气×1，专职 debuff 非基础工具卡，维持）与 `wind_buff`（Phase 2 已显式 spell×1）。**draw_cards（绝世 rank 0）按 exotic 空间暂不加费用**，全无色 cost 1 维持现状。

## 5.2 产气卡调整清单

| 卡 | 旧 → 新 | 理由 |
|---|---|---|
| gain_resource_vigor | 数值 1+0.2/级 → **1+0.1/级** | rank 0 满 15 级时原可产 4 层元气（=4 点万能费+4 次回血）仅耗 1 费，费效远超 mana 卡（2 费产 3~6 灵气）；改后满级产 2 层，与 genre 产气卡拉平，"低量通用产气"定位 |
| 8 张 gain_resource_* | 新增显式 **`costColored: {}`** | 产气工具卡任何构筑可用（原本就无流派推导全无色，显式标注防未来误加流派） |
| affix_gain_resource_crit / shield 文案 | "豪气"/"浩然之气" → **"幸运"/"护盾"**（battlecard.json） | 状态已改名，顺手对齐；penetrate（正气）/ward（清气）本一致 |

## 5.3 词缀调整清单

- **启用** `gain_resource_chakra` / `gain_resource_rage` / `gain_resource_karma`（原 167-220 行注释块）：参数完全镜像已启用的 mana 版（genre_yangqi 互斥组、rank 1、1+0.1、priority -1），滞后产出模型下补全剑/怒/煞三色牌内产气来源。启用后 genre_yangqi 组共 5 个词缀，一张卡至多带其一。
- **数值复核结论：产气词缀均不调低**。当前产出 1~3 层/次（1+0.1×词缀等级），每点有色气≈1 点费用，作为额外词条占用一个词条槽，属"构筑基石"合理强度；"明显偏高"的是卡版（0.2 斜率）而非词缀版，vigor 卡已处理，mana/chakra 等等级 10~25 产 3~6 层对 2 费卡属设计内价值（§10.5 产气价值上升是既定方向）。
- `gain_resource_ultimate`（rank 4 万能色）：rank 4（mythic）+ genre_yangqi 互斥组限制，稀有度合理，维持。

## 5.4 敌方可用性抽查

`generateBattleDeck` 按 cultivationFavor 集中取流派卡（rank>0 时 genre=favor）→ NPC 卡组约 65% 流派卡带 1 点有色费用；而 enable_chakra/rage/karma 只来自 passives（药剂/天赋数据），**普通 NPC 无滞后产出、无池提取**（灵气至少有 spirituality/10 战斗开始产出 + enable_mana）。结论：NPC 非悟道流派会出现"整手有色死卡"——敌方 AI 费用过滤（Phase 2）保证不崩溃但被动挨打。**标注为遗留问题，归 Phase 6**（计划已安排 NPC 按 cultivationFavor 获节点被动）。

## 修改文件

`assets/data/cards.json5`（vigor 数值 + 8 张 costColored）、`assets/data/card_affixes.json5`（启用 3 词缀）、`assets/locale/zh/rpg/battlecard.json`（2 处旧称）、`lib/data/game.dart`（rank 0 推导保护）、`scripts/main/cardgame/card.ht`（同上 + 编译修正），及构建产物 main.mod/story.mod。

## 遗留问题汇总

1. NPC 有色死卡（上节，Phase 6）。
2. draw_cards 的 exotic 费用设计未定（本 Phase 暂不动）。
3. 产气卡 affix 描述文案（"获得剑气"等 locale 键原有，无需新增）与卡面 exhaust 时代旧文案归 Phase 7 统一清理（已完成）。
