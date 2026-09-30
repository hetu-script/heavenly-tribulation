---
name: unique-equipment
description: |
  在《天道奇劫》中创建/修改绝世装备（isUnique 装备）时使用。
  涵盖完整链路：装备数据（assets/data/items.json5 prototype 约定）、词条设计
  （assets/data/passives.json5 机制字段组合与主词条合并原则）、新机制落地
  （battle_entity.ht 透传白名单 + Dart 消费点 + readme 契约 + 校验器）、
  本地化（item.json / passive.json）、图标（占位与 image-gen 草稿）。
  当任务涉及新增绝世装备、装备固定词条、rank+1 词条解锁时加载本技能。
---

# 绝世装备创建技能

核心认知：

- **装备词条与天赋词条同通道汇合**（`character.passives`），战斗侧只读被动数据，装备在战斗中无活实例。
- **绝世装备 = items.json5 prototype + 固定 affixes 列表**：第一个词条是主词条，
  生成时按 `rank + 1` 顺序解锁（与绝世卡同规则，见 `createItemById` item.ht:130）；
  装备破境（升境）未实现，解锁数在生成时固定。
- **一件装备的逻辑效果合并为一条主词条**（见第 2 节），affixes 列表当前只写主词条，
  给后续额外词条留出解锁位。

现成样板（先读再改）：悟道五件 `items.json5:276-360` + `passives.json5` 绝世装备专用区
（窥天镜/五行珠/天机盘/蓄灵佩/聚灵旗），实施记录见 `plan/skill_tree/spellcraft_equipment.md`。

## 0. 设计原则

沿用绝世通用原则（详见 battlecard-content skill §4）：正反双段式（强正面 + 方向性限制/对称效果/
自伤自异常，避免全民通用纯强度）；流派锁优先做软限制（非本流派费用 +X）。

分流判断（详表见 passive-status skill §0）：

| 效果类型 | 做法 |
| --- | --- |
| 行为型（时机 X 反复触发做 Y） | 永久状态 + 状态脚本（passive-status skill 五层流程），词条带 `battleStatus` |
| 参数型（观星深度、费用修正、资源保留、异常层数等） | 机制字段 / `statsBonus` 直加（本技能 §2） |
| 纯属性/单值修改（攻防、抗性、伤害增加） | stats 聚合管线（新 stat 见 passive-status skill §6） |

## 1. 装备数据（items.json5）

字段照模板注释（items.json5:235-252）。**必须字段与常见坑**：

```json5
heaven_peeking_mirror: {
  id: "heaven_peeking_mirror",
  uniqueId: "heaven_peeking_mirror",   // 必须等于 id！isUnstackable 使运行时 item.id 变随机 UID，唯一性检查只能用 uniqueId
  name: "heaven_peeking_mirror",       // 本地化键（item.json）
  flavortext: "flavortext_heaven_peeking_mirror",
  type: "equipment",
  category: "talisman",                // 法器 = talisman/pearl；护符 = jewelry/amulet|ring（kEquipmentCategoryKinds）
  kind: "pearl",
  rank: 1,                             // 境界需求 1~5。**显式写 rank、不要写 rarity**——
                                       // createItemById 里 rarity 优先推导 rank，rarity:"arcane" 会把装备压成 rank 5
  icon: "item/unknown.png",            // 初期占位图，后续手动替换专属图标
  isEquippable: true,
  isUnstackable: true,                 // 必须！否则重复获得时背包堆叠
  isUnique: true,
  isIdentified: false,                 // 必须！绝世装备默认未鉴定
  affixes: ["heaven_peeking_mirror"],  // 第一个 = 主词条；生成时解锁前 rank+1 个
},
```

- id 用 snake_case 英文含义（禁止拼音）。
- 词条等级/数值在生成时按 item.level 随机 roll——固定值词条用第 2 节的定值手段规避。
- prototype 的 affixes 只支持**字符串 id 列表**（不能逐条指定 level/value）。

## 2. 词条设计（passives.json5）——主词条合并原则

**一件装备的逻辑效果合并为一条词条**：机制字段允许共存于一条词条（battleStatus +
deckCostReduction + statsBonus 随意组合）；被拆开的词条是历史错误，合并它们。

机制字段（契约以 `docs/docs/mod/battle/readme.md` 被动字段表为准）：

| 字段 | 形态 | 语义 |
| --- | --- | --- |
| `battleStatus` | 状态 id | 战斗开始授予永久状态（行为在 status_script.ht，走 passive-status skill 流程） |
| `deckCostReduction` | `{color, amount, genres?, notGenres?}` | 组牌费修；amount 负 = 加费；`color: 'all'` 命中首个费用条目 |
| `shuffleIntoDeck` | `[卡牌主词条 id]` | 战斗开始洗入牌库 |
| `turnStartScry` | 整数 | 每回合开始抽牌前观星 N |
| `energyRetain` | `{resourceId, max, costPerPoint?, costDamageType?}` | 回合结束资源保留 + 每点代价 |
| `turnStartExtraDraw` | `{count, costIncrease?: {amount, notGenres?}}` | 额外抽牌 + 命中牌本回合临时加费 |
| `statsBonus` | `{statsId: 数值}` | **通用 stats 直加**（观星深度 scryBonus、异常层数 ailmentInflictBonus 等），固定词条喂 stats 的首选通道 |

- 词条注释标「绝世装备专用，不进随机词条池」，**不写** `isEquipmentMain`/`isEquipmentExtraAffix`。
- 数值定值：机制字段内嵌数值（如 energyRetain 的 max）；stats 用 `statsBonus` 直加；
  需要随等级缩放的数值词条才用 `base + increment×level`（`base:N, increment:0` 即恒定值）。
- 词条本地化 `passive.json`：`passive_{id}_description`，数值占位 `{0}`。
- 需要**新机制字段**时走第 3 节；需要**新 stat** 时走 passive-status skill §6 五处同步。

## 3. 新机制字段落地清单（现有字段表达不了时）

机制必须通用化、参数化（Dart = 机制层，数据 = 内容层，Dart 代码中不出现具体装备/词条 id）。
一处新机制 = 五处同步：

1. **透传白名单**：`scripts/main/data/character/battle_entity.ht` 的机制字段透传列表
   （约 :512，**漏加则字段永远到不了战斗侧**）。
2. **Dart 消费点**：`battle.dart` / `character.dart` 读取 `character['passives']` 中的字段实现行为；
   涉及伤害预览的同步 `predictDamage`。
3. **契约文档**：`docs/docs/mod/battle/readme.md` 被动字段表加一行。
4. **校验器**：`utils/data_validate/game_data_validate.dart` 加字段结构检查。
5. **计划/文档留痕**：设计计划文档记录机制语义与偏差。

## 4. 本地化（assets/locale/zh/rpg/）

- `item.json`：`"{装备id}": "装备名"` + `"flavortext_{装备id}": "..."`。
  flavortext 写清**机制与代价**（含特殊语义注记，如「保留的灵气不触发阴阳五行结算」），中国风措辞。
- `passive.json`：`passive_{词条id}_description`（面向装备/天赋界面的词条效果行）。
- 涉及状态/新 stat 的本地化按 passive-status skill 对应章节。

## 5. 图标

- 初期一律占位 `item/unknown.png`，用户后续手动替换，**不要**为生图阻塞数据落地。
- image-gen 草稿：小图标工具只能出「合集网格图」（用户手动裁切缩放）；
  像素风用 `--no-style`（避免水彩全局风格污染），输出到 `assets/images/item/equipment/unique_drafts/`。
- 战斗状态图标是另一套资源（`icon/status/permanent/`，150×150，Gemini 后端），见 passive-status skill §4。

## 6. 验证（必做）

- `dart run data_validate/game_data_validate.dart`（在 `utils/` 下）——
  覆盖 passives/status/items 的 id/引用/本地化/字段结构，含绝世装备约定检查
  （uniqueId == 键名、isUnstackable、isIdentified: false、显式 rank、affixes 非空）。
- 脚本改动（item.ht/battle_entity.ht/status_script.ht 等）：`python build.py` 重编译
  （hetu PATH 问题时用 dart install 绝对路径的 hetu.bat）。
- Dart 改动：`flutter analyze`。

## 7. 自查清单

- [ ] 效果已按 §0 分流（行为→状态 / 参数→机制字段或 statsBonus / 纯属性→stats 管线）。
- [ ] 装备显式写 `rank`（1~5）且**没有**写 `rarity`；`uniqueId == id`；`isUnstackable/isUnique/isIdentified: false` 齐全。
- [ ] affixes 第一个为主词条；词条数 ≤ rank+1 时生成即全量生效。
- [ ] 单件装备的逻辑效果已合并为一条词条（多机制字段共存）；标注「不进随机词条池」。
- [ ] 机制字段在 `docs/docs/mod/battle/readme.md` 契约表中存在；新机制已五处同步（§3）。
- [ ] stats 直加走 `statsBonus`；新 stat 走 passive-status §6 五处同步。
- [ ] 本地化：item.json 双键 + passive.json 描述键齐全；flavortext 写明机制与代价。
- [ ] 校验器 0 错误；`python build.py` 编译通过；改动 Dart 则 `flutter analyze` 通过。
