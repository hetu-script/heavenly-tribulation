# Phase 7 报告：本地化收尾 + 文档同步

> 所属计划：`plan-battle_qi_cost_rework.md` §8 Phase 7（构筑面板暂缓，未做）
> 注：Phase 6（流派节点赋能）按用户要求暂缓，无报告。

## 任务 1：本地化改动摘要

**battlecard.json（38 条重写）**

- **插值错位修正（核心）**：37 条迁移卡词条描述原形如"消耗 {0} 灵气： 徒手攻击造成 {1} 火焰伤害"——valueData 已在 Phase 2 删除 exhaust 槽，{0} 会显示为伤害值、{1} 悬空。全部改为纯效果描述并下移索引（如"徒手攻击造成 {0} 火焰伤害"、"徒手攻击造成 {0}×{1} 物理伤害"、"护甲 +{0}"、"速度 +{0}, 护甲 +{1}"、"对手生命上限 -{0}"等）；有色费用由卡面"另需"行展示，描述不再重复费用措辞。
- `uniquecard_draw_description`/`affix_draw_cards`：删"消耗 {0} 灵气"（draw_cards 从不消耗，Phase 5 已定不加费用），保留 {1} 取值（value[0] 是遗留显示槽，不动数据）。
- `exhaustResource_description`：改为"某些卡牌需要特定的气作为有色费用才能打出"。

**status_effect.json（8 条）**：无极之气描述从"可被视为灵气/剑气/怒气/煞气"改为准确的"支付有色费用时优先扣除本色气，不足自动以无极之气抵扣"；死气描述补"无色费用 +1/层（至多 +2）"；5 种资源阴气描述补对应颜色增费说明；阴气总览区分资源阴气（增费）与普通负面状态。

**passive.json（13 条）**：豪气→幸运、浩然之气→护盾（start_battle 描述）；enable_mana/chakra/rage/karma 四条描述与 Phase 3 实际行为对齐（此前是旧模型措辞）；karmaMax"煞气带入上限"→"煞气提取上限"（战前一次性导入已移除）；灵气溢出天赋两条改为"回合结束时按剩余层数"表述；剑气溢出天赋（机制已删）标注"暂无效果"；`mana_is_also_chakra`（无任何代码实现，旧模型措辞）标注"尚未实装"；spellcraft_rank_2/4 节点描述同步新溢出时机。

**craft.json（2 条）**：药水名 豪气→幸运、浩然之气→护盾。

## 任务 2：文档改动摘要

- **resource/readme.md（重写）**：顶部列表按新体系重组（6 阳 6 阴资源对含增费说明、普通状态表含新旧名、劫气小节）；新增费用模型（无色+有色、流派→颜色、硬检查）、统一生命周期（含设计理由）、滞后产出模型表（元气/灵气/剑气/怒气/煞气含业力池提取公式）、溢出与剩余利用；删除旧"链条模型/差异化节奏/双重功能/提案记录"等整节旧设计，未落地的节点产出、剩余剑气利用、pips 均标"规划中"；充能/淬毒小节保留（淬毒原有规划中标注不动）。
- **card/readme.md**：新增"费用"小节（总费用=rank+1 模型、置灰提示、无极抵扣、阴气增费、pip 暂缓）；删除"每个词条都会有自己的灵气消耗…之和"旧模型；"符箓消除流派需求"改写为待定标注（对应计划 §11.3）。
- **battle/readme.md**：豪气→幸运 ×2、护盾旧称 ×1；"消耗X气的攻击大多数是×N次数"段落改为费用模型表述；新增"资源回合节奏"小节（回合开始 4 步、回合结束 3 步，显式顺序）。
- **mod/battle/readme.md**：顶部玩家/敌方回合流程合并为与实际 `_startTurn` 一致的 10 步（回调→跳过→清空→产出→注入→出牌→回合末结算→切换，含支付路径名词）；`self_overflowed_energy` 时机标注"无状态注册、空转"；回合末结算函数与费用增费规则补记；turnFlags 表豪气→幸运。
- **plan-card_cost_pip.md**：文件**已不存在**（此前已被吸收删除），无需加弃用说明。

## 仍残留的旧术语及原因

1. **cultivation 文档**（`docs/docs/how2play/rpg/cultivation/readme.md` 41/55/63 行、passive_skills/readme.md 37 行）：仍是旧产出模型描述（灵气转化剑气、怒气=造成伤害等），**不在本 Phase 的四篇文档清单内**，留待 cultivation 文档单独同步。
2. **`passive_exhaust_life_for_insufficient_rage`**（passive.json 143 行"怒气枯竭时消耗的生命减半"）：旧 exhaust 兜底机制已随硬检查消失，该天赋当前无生效路径，但其新效果设计属天赋重做范围（Phase 6），文案暂保留。
3. **card/readme.md "精炼需要消耗灵气"**：此处"灵气"是打造货币（灵石体系），与战斗气无关，依任务要求"卡牌打造表述保持"未动。
4. 各处"（原豪气）""（原浩然之气）"为**有意保留**的改名对照标注。

## 修改文件

`assets/locale/zh/rpg/{battlecard,craft,passive,status_effect}.json`、`docs/docs/how2play/rpg/battle/{readme.md, resource/readme.md, card/readme.md}`、`docs/docs/how2play/rpg/item/consumable/readme.md`、`docs/docs/mod/battle/readme.md`。
