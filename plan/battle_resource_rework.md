# 战斗资源与费用模型重构

## 背景

当前模型：每回合元气 = rank+3、抽牌 = rank+3、卡费总额 = rank+1（无色+有色）、
卡组下限固定 10、NPC 卡组/装备/物品栏物品全为满境界或偏高境界。
问题：境界越高每回合可出牌数越少（(rank+3)/(rank+1) 从 3 递减到 1.3），
决策密度随成长反降；rank 同步缩放是机械性的，不产生策略维度。

目标（已与设计者确认方向）：

1. 元气产出固定 3 点/回合，抽牌固定 5 张/回合（杀戮尖塔式固定基线）；
2. 取消"总费用 = rank+1"设定，无色与有色各自走同一阶梯 L(rank) = ⌊rank/2⌋+1
   （rank0-1 费 1、rank2-3 费 2、rank4-5 费 3）；
3. 卡组构筑下限改为 10 + rank×2（rank0=10 … rank5=20）；
4. 新增三条**仅限装备**的属性词条：每回合元气、抽牌数量、卡组下限减免
   （负值、rank≥3、保底 10），不出现在丹药/聚灵阵临时增益池；
5. NPC 卡牌境界随机化（distantInt 偏向低境界，**防止 NPC 卡手**：
   低境界卡费用低、无使用门槛）；
   NPC 装备与物品栏物品境界均匀随机（nextInt）即可。

关键事实（重构的安全垫）：现有显式 qiCost 公式 {base:0.5, rankIncrement:0.5}
恰好产出 L(rank)，而 无色 = (rank+1) − L(rank) = ⌈rank/2⌉ 也等于 L(rank)。
因此**所有带显式 qiCost 的流派卡费用不变**，改动只影响：
无流派卡（全无色 rank+1 → L(rank)，约减半）和缺省推导的流派卡
（缺省 ⌈(rank+2)/2⌉ 有色与显式公式不一致，顺手统一）。

随机化语义（hetu_script math.dart:92-104，已核实）：

- `nearInt(max)` = max × rand^0.5，偏向**高值**（靠近 max）；
- `distantInt(max)` = max × (1 − rand^0.5)，偏向**低值**（靠近 0），
  distantInt(rank + 1) ∈ [0, rank]；
- `nextInt(max)` 均匀随机 ∈ [0, max)。

## 一、费用模型：双侧阶梯

新规则：

- 无色费用 cost = L(rank) = rank~/2 + 1（所有卡，含无流派卡）；
- 有色费用：显式 qiCost 优先（条目仍可为固定数值或 {base, rankIncrement} 公式，
  现有数据无需改动）；缺省推导 = L(rank) 按 genreCostColors 分色
  （多色对半拆，余数给首位，同现状）；
- 删除 rank 0 特例（L(0)=1 天然覆盖"全无色 1 费"）；
- 删除"有色超额时无色 clamp 为 0"分支——无色不再被有色挤压。

代价（有意简化）：失去"0 无色+全有色"这类预算内互换设计；
如日后需要，可为词条加无色覆盖字段，不在本次范围。

### 改动点

- `scripts/main/cardgame/card.ht` `_updateCardCost()`：重写为上述规则；
- `lib/data/game.dart:1473` `deriveBattleCardCost()`：同步重写（两侧一致性是既有约定）；
- `lib/data/game.dart:526` `_validateBattleCardCostColored()`：
  保留费用色合法性与公式合法性校验；
  删除"ΣqiCost ≤ rank+1"与"cost + ΣqiCost = rank+1"两条规则，
  可改为 ΣqiCost > L(rank)+1 时给出软警告（提示非常规定价）；
- `assets/data/cards.json5` 头部注释中费用相关说明更新。

## 二、元气固定 3 点

### 改动点

- `lib/scene/battle/character.dart:628` `produceTurnStartResources()`：
  `addStatusEffect('energy_positive_life', amount: rank + 3)`
  → `amount: kBattleBaseEnergy + stats 加成`（新常量 kBattleBaseEnergy = 3，
  定义在 `lib/data/common.dart`）；
- `lib/scene/battle/energy_display.dart:23,113`：元气槽位上限显示 rank+3 → 读取新基准；
- 敌我共用同一函数，AI 自动对称，无需单独改。

## 三、抽牌固定 5 张

### 现状（已核实）

- 抽牌数 = `GameLogic.getHandLimitForRank(rank)['limit']`（= rank+3），
  唯一调用点 `lib/scene/battle/battle.dart:1200`；
  该函数经 `lib/app.dart:338` 暴露给脚本侧（`scripts/main/logic/logic.ht:21`）。
- 注意：`getHandLimitForRank` 注释自称返回"卡组下限"，**与事实不符**——
  真正的卡组下限是固定常量 `kBattleDeckSize = 10`（`lib/data/common.dart:1369`），
  'limit' 实际只当抽牌数用；`deckbuilding_zone.dart:246` 曾按 rank 缩放卡组上限的
  代码已被注释掉。此函数重命名/拆分在本次一并处理。

### 改动点

- 抽牌数 → 新常量 kBattleDrawCount = 5 + stats 加成（battle.dart:1200）；
- 手牌上限：当前无上限。固定 5 抽 + 抽牌加成词条会囤牌，
  建议顺手定义手牌上限（待定，参考值 10）。

## 四、卡组构筑下限：10 + rank×2（已确认方向）

由固定 10（kBattleDeckSize）改为 10 + rank×2。配合固定 5 抽，
牌库循环周期 = ⌈卡组数/5⌉：rank0 → 2 回合，rank5 → 4 回合，
与高境界"单卡费高、出牌少、战斗变长"的节奏匹配；同时抑制
"只带最强几张"的退化构筑，并给抽牌加成天赋留出空间。

### 改动点

- `lib/logic/logic.dart:951` `checkDeckRequirement()`：`kBattleDeckSize` →
  `getDeckMinSizeForRank(rank)`（新函数，10 + rank×2，扣除装备词条减免后
  保底 10）；**注意该函数当前不接收角色参数**，读 stats 需改签名；
- `lib/scene/card_library/deckbuilding_zone.dart:131`：构筑 UI 下限同步；
- `lib/scene/battle/battle.dart:308`：不足时补占位卡的数量基准同步；
- `lib/logic/character.dart:721`：NPC 占位卡组生成同步；
- 本地化：构筑界面的"卡组数量不足"提示若含具体数字需更新。

### 风险（实施时实测）

- **获取节奏**：rank5 需 20 张合规卡；若战斗掉落/冥想卡包产出跟不上，
  玩家会吃到占位卡填充（惩罚性体验）。优先提高产出，不轻易降下限；
- **构筑一致性**：rank5 循环 4 回合，关键卡每场战斗只见 1~2 次。
  若"套路打不出来"挫败感强，退路：8+rank×2 或 10+rank。

## 五、NPC 境界随机化（已确认方向）

1. **战斗卡牌：distantInt 低境界偏向（防止 NPC 卡手）**。
   `battle_entity.ht:603` `rank: character.rank` → `maxRank: character.rank`
   （BattleCard 构造器对 maxRank 已走 `random.distantInt(maxRank + 1)`，
   card.ht:84）；同文件 `:558` cardInfoList 路径兜底
   `rank: info.rank ?? character.rank` 同样改为 `maxRank` 兜底。
   安全托底已存在：genre 卡 rank 0 强制提升为 1（card.ht:90）、
   主词条 rank 高于卡牌时顶升卡牌境界（card.ht:165），低 roll 不产出违法卡。
2. **武器/装备：nextInt 均匀随机**。
   `battle_entity.ht:609` `Equipment(kind: ..., rank: character.rank)`
   → `rank: random.nextInt(character.rank + 1)`
   （Equipment 无 maxRank 参数，在调用处 roll）。
3. **物品栏初始物品：nextInt 均匀随机**。
   `character.ht:1234` `characterInitItems()` ——随机角色物品分配函数，
   调用方：`character.ht:564`（随机角色初始化）、`object.ht:179`（商人商品）。
   当前 `:1236` 用 `random.nearInt(character.rank + 1)`，语义偏向**高**境界，
   改为 `random.nextInt(character.rank + 1)` 均匀随机。

注意点：

- **商人连带影响（已确认可接受）**：`object.ht:179` 商人商品同走
  `characterInitItems`，货品境界从高偏向（nearInt）变为均匀随机（nextInt）；
- **疑似 bug（顺带修）**：`character.ht:1252-1253` kRankedPrototypeItems 分支
  `assert(rank > 0); itemRank = itemRank.clamp(1, rank)` 中的 `rank` 不是函数参数，
  应为 `character.rank`；
- **卡组厚度**：卡牌低偏向 + 数据池 rank≤1 卡居多的双重作用下，
  高 rank NPC 卡组会偏"薄"（规则合法：角色境界≥卡境界即可）。
  如需保持威慑，可加 rank 下限（如 distantInt 结果不低于 character.rank − 2），
  待实测决定。

## 六、新增属性词条（仅限装备，已确认）

`assets/data/passives.json5` 新增三条，**只标 `isEquipmentExtraAffix: true`**，
不加 `isPotionMain` / `isEphemeral`（白名单制，天然排除丹药与聚灵阵临时增益；
天赋树节点无视 rank 与用途标记，不受影响）：

| id（待定） | increment | rank 门槛 | 读取处 | 说明 |
|---|---|---|---|---|
| battleEnergyBonus | 1（待定） | 无 | character.dart 产出处 | 元气 = 3 + stats |
| battleDrawBonus | 1 | 建议 rank 2 | battle.dart 抽牌处 | 抽牌 +1 很强，不宜早出现 |
| deckMinSizeReduce | -1 | rank 3 | checkDeckRequirement | 生效值 = max(10, 10+rank×2+value) |

注意点：

- **与现有词条的重叠**：`start_turn_with_energy_positive_life`
  （passives.json5:920，pearl，rank 2，可用于丹药/临时增益）与元气词条
  功能等价（元气即无色费用池）。决策：**并存**——新词条走 stats
  （面板可见、仅限装备、加在固定 3 点基准上），旧词条不动
  （机制不同：基础产出加成 vs 回合开始状态注入）；
- **稀有度手段唯一**：装备词条池无权重机制（equipment.ht:114 过滤后
  均匀随机），rank 门槛即全部稀有度表达；同境界内低概率做不到，
  如需需另加 weight 字段（不在本次范围）；
- **负值词条显示**：stats.dart 默认分支把"低于基础值"标红，
  deckMinSizeReduce 需走类似 `endsWith('Cost')` 的"低者优"分支
  （stats.dart:174），或显式加分支；
- 词条 kinds 建议：元气/抽牌 → amulet/ring/pearl；卡组下限 → pearl/amulet；
- `lib/widgets/character/stats.dart` kMoreStats 增加显示项；
- `assets/locale/zh/rpg/passive.json` 增加三条描述字符串；
- 流派境界节点（plan/swordcraft.md 等）后续各自认领倾向，不在本次范围。

## 七、平衡校准（改后必须实测）

- **软狂暴阈值**：`roundCount > 8` 按当前回合强度标定；固定 3 费后高境界
  每回合输出下降、战斗拖长，劫气触发时机需重新校准（battle.dart 中
  roundCount 判定处）；
- **有色气产出**：阶梯最高有色 3/张，悟道 +1/回合、剑气/怒气滞后产出不变，
  需确认"元气够、有色气不够"不成为常态挫败（流派节点保底规划正好补位）；
- **低 rank NPC 难度**：敌我费用差消失后，跨境界战斗强弱完全由卡组质量决定，
  难度曲线重新看；NPC 境界随机化（第五节）进一步拉低 NPC 强度，一并观察；
- **易逝/符箓/消耗牌**：固定 5 抽后手牌更紧，这些机制价值上升，观察是否过强。

## 八、文档与注释同步

- `docs/docs/how2play/rpg/battle/card/readme.md` 费用小节；
- `docs/docs/how2play/rpg/battle/resource/readme.md` "费用模型"章节；
- `docs/docs/mod/battle/readme.md` 流程第 6 条（元气 rank+3）与费用段落；
- `card.ht` / `game.dart` / `logic.dart:938` 中引用旧规则的注释
  （含 game.dart 中 "plan-battle_qi_cost_rework.md §3.1" 的引用，该文件已不存在，
  改为引用本文件；getHandLimitForRank 的"卡组下限"注释一并修正）。

## 实施顺序建议

1. 费用阶梯化（第一节）——独立可验证，卡牌费用不变的部分占多数；
2. 元气固定 + 抽牌固定 + 卡组下限 + NPC 境界随机化（第二~五节）
   ——一起改，直接决定回合手感；
3. 手动战斗实测 → 校准软狂暴与产出（第七节）；
4. 新属性词条（第六节）——机制稳定后再加；
5. 文档同步（第八节）随各步提交。

验证：每步后 `python build.py` 编译脚本 + 数据校验警告清零 + 实机战斗。

## 附：本次规划过程中发现的其他问题（不在本次范围，仅记录）

- `status_effect.json` 不幸（debuff_crit）描述 "-25%" 与文档/脚本注释 "-50%" 不一致；
- `status_script.ht` 头部触发时机注释陈旧（lose_life 已废弃、kind 空后缀占位、
  条目重复），lib/scene/battle/character.dart:784-786 的 lose_life 派发已注释掉；
- 本地化中 `affix_energy_positive_curse`、`affix_opponent_energy_negative_*`
  无对应卡牌数据（未实现的煞气/阴气卡）；
- `stats.dart:60` `kNonBattleItemsLength` 死常量；
- `card.ht:197` 非 maxOutLevel 时随机等级够不到 maxLevel（nextInt 上界开区间）；
- `card_script.ht:95` heal_lifeMax 缺 await；
- `equipment.ht` 主/额外词条 increment<1 钳制不对称；`:153` experienced 字段疑似遗留。
