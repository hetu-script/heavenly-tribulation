# 悟道流派（spellcraft）机制深化设计

## 〇、前置讨论：硬流派限制 vs 软标签系统

### 当前系统的双重限制

目前卡牌使用有两层限制：

1. **硬流派锁**：`checkRequirements()` 检查角色是否拥有 `{genre}_rank` 被动。没有 → 不能用。
2. **资源软限制**（已存在但未充分利用）：卡牌消耗特定资源（灵气/剑气/怒气/业力），而这些资源通过天赋被动（`enable_chakra`、`enable_rage` 等）不对称地分配给各流派。

实际上第二层已经构成了软限制，硬流派锁是冗余的。

### 对比分析

| 维度 | 硬流派锁（现方案） | 软标签系统（提议） |
|------|-------------------|-------------------|
| 构筑自由度 | 低。跨流派构筑完全不可能 | 高。任何角色可使用任何卡牌 |
| 流派辨识度 | 强。"我只能用悟道卡" | 中。需要靠天赋加成差异体现 |
| 新玩家认知 | 简单。"灰色的卡不能带" | 复杂。"都能带，但有些不好用" |
| 卡牌获取体验 | 差。拿到非本流派卡牌 = 无用 | 好。拿到任何卡都可能有用 |
| 平衡难度 | 低。只在一个流派内平衡 | 高。需防止跨流派组合过强 |
| 构筑深度 | 低。选择范围受限 | 高。跨标签混搭是高级构筑乐趣 |
| 天赋树价值感 | 低。只是"解锁使用权" | 高。让你"更好地使用"而非"可以使用" |

### 推荐：软标签系统 + 强天赋加成

删除卡牌上的硬流派 `genre` 需求，替换为标签（tag）系统。任何角色可使用任何标签的卡牌，但天赋树提供显著的流派内加成。软限制通过三个机制实现：

**1. 资源不对称（基础限制）**
- 灵气（mana）主要通过 `spellcraft` 天赋节点和 `mana` 卡牌生成
- 剑气（chakra）通过 `enable_chakra` 被动生成（需要御剑天赋节点解锁）
- 怒气（rage）通过 `enable_rage` 被动生成（需要锻体天赋节点解锁）
- 没有对应天赋的角色基本无法高效生成对应资源

**2. 能量效率（深层限制）**
- 天赋节点可使本流派标签的卡牌能量消耗 -1（最低为 1）
- 每回合能量 = `rank + 2`，跨标签使用意味着更多能量压力

**3. 机制加成（构筑驱动力）**
- 天赋节点提供的机制（如元素共鸣）仅对本标签卡牌生效
- 流派专属额外词条仅出现在对应标签的卡牌上

### 五大标签体系

| 流派 | 标签 | 主要资源 | 资源生成方式 | 卡牌特征 |
|------|------|----------|-------------|----------|
| spellcraft | `元素` | 灵气（mana） | talent + `mana` 卡 | 元素法术，共鸣机制 |
| swordcraft | `法器` | 剑气（chakra） | `enable_chakra`（造成伤害换剑气） | 武器攻击 + 飞剑 |
| bodyforge | `武术` | 怒气（rage） | `enable_rage`（受到伤害换怒气） | 徒手/武器，越挫越强 |
| vitality | `咒语` | 业力（karma） | 战斗胜利积累 | 真言术，诅咒，生命操控 |
| avatar | `经文` | 混合资源 | 多途径 | 符印，经文，混合攻击 |
| 通用 | 无标签 | 无特定资源 | — | 基础拳脚/防御，人人可用 |

通用卡牌（当前无 `genre` 的卡牌）不设标签，所有角色平等使用，不受任何天赋加成也不受任何限制。

### 对后续设计的影响

- `cards.json5` 中的 `genre` 字段可以保留用于标注来源（决定哪些卡包可以开出），但不再作为使用条件
- 卡牌使用条件改为检查 `tags` 而非 `genre`（如果有硬性限制需要）
- 天赋节点的效果从"允许使用某流派卡牌"改为"使用某标签卡牌时获得加成"
- 能量成本统一为 `rank + 1`，天赋加成可在此基础上减免

---

## 一、三种机制载体分析

在开始具体设计前，先对三种引入流派独有机制的方式做一个系统比较。

### 1. 绝世卡牌（Unique Card）

**本质**：把机制封装在卡牌中，玩家通过抽到并打出它来触发。

优点：

- 打出时有"表演时刻"的仪式感，符合炉石橙卡那种"一张卡改变局势"的体验
- 可以设计得非常激进和大胆，因为被卡组中只有一张、且需要抽到的 RNG 所平衡
- 实现相对简单——只需要一个新脚本函数 + 卡牌数据定义

缺点：

- 抽不到就毫无作用，构筑依赖单卡时方差极大
- 被 counter（如被弃牌、被消耗）时构筑崩盘
- 占用一个卡组位置

**适合承载**：峰值体验、终结技、规则改写类效果。设计语言应该是"我做了一件不可思议的事"。

### 2. 绝世装备（Unique Equipment）

**本质**：把机制封装在装备中，始终生效，无抽牌 RNG。

优点：

- 稳定性最高——每场战斗都能依赖它
- 不占用卡组空间
- 培养感强——一件绝世装备可以陪伴角色很久
- 可以实现"被动型"机制（如每回合开始时触发、条件触发等）

缺点：

- 缺少"打出"的主动感和仪式感
- 装备槽位有限（6 个），与普通装备形成机会成本竞争
- 如果效果太强，会让玩家觉得"是装备在赢，不是我在赢"

**适合承载**：持续性规则修改、条件触发、资源管理优化。设计语言应该是"改变我玩牌的方式"。

### 3. 天赋节点（Talent Node）

**本质**：把机制绑定在境界突破上，角色永久获得。

优点：

- 最有仙侠味——"突破境界 → 领悟大道"是非常自然的设计
- 五层境界天然提供了五个机制层级，可以逐级深化
- 不占用卡组或装备槽位，是一种独立的成长维度
- 可以在 UI 上做文章（天赋树界面中突出显示流派核心机制）
- **机制始终可用**，不受抽牌或装备选择的限制

缺点：

- 目前 `spellcraft_rank` 等被动只是布尔标记（解锁卡牌用），需要扩展为携带实际数值/效果
- 机制效果需要在多个战斗系统中注册回调，实现复杂度高于单卡设计
- 如果做错了调整成本高——修改天赋节点比修改一张卡牌影响大得多

**适合承载**：定义流派核心玩法的基础规则。设计语言应该是"我修道的方式与众不同"。

### 推荐整合：三层模型

三种载体不是互斥的，而是各司其职：

```
┌─────────────────────────────────────┐
│  绝世卡牌  ← 峰值表达               │
│  "我用全部灵气轰出这一击"            │
├─────────────────────────────────────┤
│  绝世装备  ← 定制偏好               │
│  "我更喜欢火系法术"                  │
├─────────────────────────────────────┤
│  天赋节点  ← 基础规则               │
│  "我修炼的是悟道，所以我这样用灵气"   │
└─────────────────────────────────────┘
```

- **天赋节点**定义"悟道之人如何运用灵气"——这是所有悟道流玩家共享的基础玩法
- **绝世装备**允许玩家在同一流派内选择不同的侧重方向——火系专精 vs 万金油全修
- **绝世卡牌**提供"终于来了！"的高光时刻——每张绝世卡牌都是对该流派核心理念的一次极致演绎

---

## 二、核心机制：元素共鸣

### 设计目标

悟道流的核心玩法应该是**安排法术使用顺序以触发共鸣加成**。这利用了悟道流派拥有五种元素（土/火/风/雷/木）的独特优势——其他流派没有类似的"元素多样性"。

### 机制定义

**元素标签**：每张法术卡牌拥有一个元素标签，来自其 `kind` 字段：

- `earthbend` → 土
- `firebend` → 火
- `airbend` → 风
- `lightning_control` → 雷
- `plant_control` → 木

**共鸣规则**：

- 游戏记录"上一张打出的法术的元素"（初始为空）
- 当打出一张法术卡时：
  - 若当前记录的元素不为空，且新卡元素**不同于**记录的元素 → 触发共鸣
  - 无论是否触发共鸣，记录更新为新卡的元素
- 同一回合内打出的共鸣不计入下一回合的起始记录（每回合结束时清除记录？还是保留？——建议**保留**，让回合间的顺序规划更有深度）

**共鸣不适用于**非法术攻击（如 `punch_attack_exhaust_mana` 虽然是悟道流派但 kind 是 punch，不是元素法术）。

---

## 三、天赋节点设计

目前 `spellcraft_rank` 只是一个空的布尔标记。扩展为携带实际的效果描述，每突破一个境界，获得一层更深的共鸣能力。

### 数据结构

每个 `spellcraft_rank` 的被动效果可以在 `passives.json5` 中扩展，或通过脚本侧的 `characterCalculateStats` 判断 rank 等级来赋予机制。

建议的方式：不修改 `spellcraft_rank` 结构本身，而是在解锁对应天赋节点时，额外 `characterSetPassive` 一个 `elemental_resonance_N` 被动。这样可以保持现有的 rank 门禁逻辑不变。

### 五层共鸣

| 境界     | 被动 ID                 | 效果                                                                                | 设计意图                                               |
| -------- | ----------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------ |
| 凝气 (1) | `elemental_resonance_1` | **元素印记**：使用法术时记录其元素。当使用与上一张不同的元素法术时，获得 1 点灵气。 | 引入共鸣概念——最简单的正反馈：换元素=赚灵气            |
| 筑基 (2) | `elemental_resonance_2` | **元素精进**：共鸣时，法术伤害 +15%。                                               | 给共鸣增加伤害维度，玩家开始有意识地规划顺序           |
| 结丹 (3) | `elemental_resonance_3` | **元素循环**：达成"三元素共鸣链"（连续打出 3 张不同元素的法术）时，额外抽 1 张牌。  | 引入"链"的概念——不只是相邻两张，连续的链条有额外奖励   |
| 还婴 (4) | `elemental_resonance_4` | **元素融汇**：共鸣链达到 4 时，下一次共鸣的灵气获取翻倍。                           | 鼓励长链——越长的链奖励越大                             |
| 化神 (5) | `elemental_resonance_5` | **五行归一**：完成五元素全循环后，重置所有元素记录，下一张法术消耗为 0 且伤害翻倍。 | 终极奖励——完成五元素全循环是天大的成就，值得天大的奖励 |

### 关键设计约束

- 共鸣追踪需要跨回合保留，否则长链不可行
- 非元素法术（如通用 punch/kick 类、其他流派卡牌）不计入也不打断共鸣链
- 重复使用同一元素不触发共鸣，但也不打断链（链长度保持不变）
- 打出非共鸣法术只是不获得奖励，不会惩罚玩家

---

## 四、现有悟道卡牌的修改

### 当前悟道卡牌清单

**攻击：**

| ID                        | kind              | 元素 | 脚本                  | 问题                               |
| ------------------------- | ----------------- | ---- | --------------------- | ---------------------------------- |
| punch_attack_exhaust_mana | punch             | 无   | attack_exhaust        | 非元素法术，应保留但标注为"无元素" |
| falling_stone             | earthbend         | 土   | attack_exhaust        | 纯伤害，无元素特性                 |
| fireball                  | firebend          | 火   | attack_exhaust        | 纯伤害，无元素特性                 |
| wind_blade                | airbend           | 风   | attack_slow_exhaust   | 有减速，不错的起点                 |
| lightning                 | lightning_control | 雷   | attack_clumsy_exhaust | 有笨拙，不错的起点                 |

**增益：**

| ID                        | kind          | 元素 | 脚本               | 问题                           |
| ------------------------- | ------------- | ---- | ------------------ | ------------------------------ |
| mana                      | xinfa         | 无   | mana               | 通用的灵气生成，保留           |
| punch_defend_exhaust_mana | punch         | 无   | defend_exhaust     | 保留作为通用防御               |
| wind_buff                 | airbend       | 风   | speed_quick_defend | 有元素特性                     |
| wood_heal                 | plant_control | 木   | heal_exhaust       | 有元素，但有 resourceType 消耗 |
| wood_defense_physical     | plant_control | 木   | defend_exhaust     | 有元素特性                     |

### 建议的修改

**1. 为每种元素的基础攻击赋予独特行为（替换纯 `attack_exhaust`）**

土（falling_stone）：

- 当前：`attack_exhaust` — 消耗灵气，单次伤害
- 改为：消耗灵气，造成伤害，**对护盾造成双倍伤害**（破盾特性）
- 增加 `tags: ["earth_element"]`

火（fireball）：

- 当前：`attack_exhaust` — 消耗灵气，单次伤害
- 改为：消耗灵气，造成伤害，附加 1 层**灼烧**（回合结束时造成少量伤害，持续 2 回合）
- 增加 `tags: ["fire_element"]`

风（wind_blade）：

- 当前：`attack_slow_exhaust` — 消耗灵气，伤害 + 减速
- 保持现有机制（已有差异化），增加 `tags: ["wind_element"]`

雷（lightning）：

- 当前：`attack_clumsy_exhaust` — 消耗灵气，伤害 + 笨拙
- 保持现有机制，增加：若目标已有减速（`speed_slow`），额外触发一次 50% 伤害（导电效果）
- 增加 `tags: ["lightning_element"]`

**2. 添加元素标签到所有元素卡牌**

所有元素法术的 `tags` 中添加对应的元素标签：`earth_element`、`fire_element`、`wind_element`、`lightning_element`、`wood_element`。

这些标签的作用：

- 共鸣系统追踪"上一张法术的元素"时读取
- 未来可以设计"对火系法术伤害 +X%"的装备或被动
- 可以在 UI 上为不同元素显示不同颜色的边框

**3. 木系需要一张攻击卡**

目前木系（plant_control）只有 buff 卡，缺少攻击卡。见下文"新增卡牌"。

---

## 五、新增悟道主词条卡牌

### 木系攻击卡

**vine_whip（藤鞭）**

```json5
vine_whip: {
    id: "vine_whip",
    genre: "spellcraft",
    category: "attack",
    kind: "plant_control",
    resourceType: "energy_positive_spell",
    attackType: "spell",
    damageType: "physical",
    rank: 1,
    description: "affix_spell_attack_vine_whip",
    tags: ["exhaustResource", "wood_element"],
    image: "battlecard/illustration/spellcraft_wood_attack.png",
    animation: {
        startup: "spell_attack",
        recovery: "spell_attack_recovery",
        overlays: "wood_buff",
        sound: "timber-tree-falling-1-40384.mp3",
    },
    script: "attack_heal_exhaust",  // 新脚本：伤害 + 自愈
    valueData: [
        { base: 0, increment: 0.1 },   // 灵气消耗量
        { base: 12, increment: 1.2 },  // 伤害值
        { base: 3, increment: 0.5 },   // 自愈量（造成伤害的百分比？还是固定值？）
    ],
},
```

设计意图：木系攻击附带生命回复，体现"生生不息"的主题。这是唯一可以边攻击边回血的元素，给木系一个明确的防守反击定位。

### 冰/水系攻击卡

虽然传统五行是金木水火土，但你的游戏已经用了土/火/风/雷/木（更像元素流派而非严格五行）。不过可以考虑增加水系来丰富元素池：

**water_blast（水弹/寒冰）**

```json5
water_blast: {
    id: "water_blast",
    genre: "spellcraft",
    category: "attack",
    kind: "waterbend",
    resourceType: "energy_positive_spell",
    attackType: "spell",
    damageType: "elemental",
    rank: 1,
    description: "affix_spell_attack_water",
    tags: ["exhaustResource", "water_element"],
    image: "battlecard/illustration/spellcraft_water_attack.png",
    animation: { ... },
    script: "attack_freeze_exhaust",  // 新脚本：伤害 + 冻结（减对手下回合能量）
    valueData: [
        { base: 0, increment: 0.1 },   // 灵气消耗量
        { base: 14, increment: 1.4 },  // 伤害值
        { base: 1, increment: 0.2 },   // 对手下回合能量 -X
    ],
},
```

### 火系 buff 卡

目前火系没有 buff 卡，可以加一张：

**fire_rage（烈焰之心）**

```json5
fire_rage: {
    id: "fire_rage",
    genre: "spellcraft",
    category: "buff",
    kind: "firebend",
    resourceType: "energy_positive_spell",
    rank: 1,
    description: "affix_fire_rage",
    tags: ["exhaustResource", "fire_element", "status_energy_positive_spell"],
    image: "battlecard/illustration/spellcraft_fire_buff.png",
    animation: { ... },
    script: "mana_damage_buff",  // 新脚本：获得灵气 + 下张攻击卡伤害提升
    valueData: [
        { base: 0, increment: 0.1 },   // 灵气消耗量
        { base: 1, increment: 0.3 },   // 获得灵气量
        { base: 20, increment: 2 },    // 下张攻击卡伤害提升百分比
    ],
},
```

### 土系 buff 卡

**earth_armor（土灵护体）**

```json5
earth_armor: {
    id: "earth_armor",
    genre: "spellcraft",
    category: "buff",
    kind: "earthbend",
    rank: 1,
    description: "affix_earth_armor",
    tags: ["earth_element", "status_defense", "shield_physical"],
    image: "battlecard/illustration/spellcraft_earth_buff.png",
    animation: { ... },
    script: "shield_defend",  // 新脚本：获得护盾 + 物理防御
    valueData: [
        { base: 1, increment: 0.2 },   // 护盾层数
        { base: 8, increment: 0.8 },   // 防御值
    ],
},
```

### 雷系 buff 卡

**lightning_speed（雷光遁）**

```json5
lightning_speed: {
    id: "lightning_speed",
    genre: "spellcraft",
    category: "buff",
    kind: "lightning_control",
    rank: 1,
    description: "affix_lightning_speed",
    tags: ["lightning_element", "status_speed_quick"],
    image: "battlecard/illustration/spellcraft_lightning_buff.png",
    animation: { ... },
    script: "speed_quick_mana",  // 新脚本：获得急速 + 少量灵气
    valueData: [
        { base: 1, increment: 0.3 },   // 急速层数
        { base: 1, increment: 0.1 },   // 灵气量
    ],
},
```

### 新增卡牌汇总

| ID              | 元素  | 类型   | 核心机制            |
| --------------- | ----- | ------ | ------------------- |
| vine_whip       | 木    | attack | 伤害 + 自愈         |
| water_blast     | 水/冰 | attack | 伤害 + 对手能量减损 |
| fire_rage       | 火    | buff   | 灵气 + 下张攻击增伤 |
| earth_armor     | 土    | buff   | 护盾 + 防御         |
| lightning_speed | 雷    | buff   | 急速 + 灵气         |

这样每个元素都有一张攻击卡和一张 buff 卡（除了木系 buff 已有 wood_heal 和 wood_defense_physical），形成了对称的元素体系。

---

## 六、绝世悟道卡牌设计

每张绝世卡牌对应悟道流派核心理念的一次极致演绎。

### 五行归一（Five Elements Unity）

> "五行流转，生生不息。"

**类型**：攻击
**境界**：3（结丹）
**效果**：

- 记录本场战斗中你使用过的不同元素的种类数量（最多 5 种）
- 造成"种类数量 × 基础伤害"的伤害
- 重置所有元素记录
- 每使用过一种元素，额外获得 1 点灵气

**设计意图**：鼓励使用多种元素。游戏前期伤害低（只用了 1-2 种元素），后期随着元素池的丰富而变强。打出前的准备（积累元素种类）和打出后的回报（重置 + 灵气返还）形成完整的弧线。配合结丹期的"元素循环"天赋，可以快速重新积累元素种类。

**数据设计**：使用 `affixProgression`（境界提升预设词条），在 rank 3/4/5 分别解锁额外词条。

### 天人感应（Heaven-Human Resonance）

> "天人合一，万法随心。"

**类型**：增益
**境界**：2（筑基）
**效果**：

- 本回合内，打出的下一张元素法术：
  - 不消耗灵气
  - 自动触发共鸣加成（即使元素与上一张相同）
  - 效果结束后，将自身的 1 个负面状态转移给对手

**设计意图**：一张"设置 combo"的卡。它在回合内创造了一个"免费+必定共鸣"的窗口，让玩家可以规划一个爆发回合。配合高伤害法术（如火球），可以打出灵气消耗为 0 的共鸣增伤一击。转移 debuff 是炼魂流派的能力，但作为绝世卡牌跨界一下可以接受——体现"天人感应"净化自身的意象。

### 万法归宗（Myriad Methods Return to Source）

> "万法皆空，归于一处。"

**类型**：攻击
**境界**：4（还婴）
**效果**：

- 消耗你所有的灵气
- 每消耗 1 点灵气，造成 X 点伤害
- 若消耗的灵气超过 10 点，额外对对手施加 1 层幻觉（`injury_hallucination`）

**设计意图**：资源倾泻型终结技。悟道流的灵气积累体系（mana 生成 + 共鸣灵气奖励）让这张卡成为可能——平时的灵气管理都是为了这一刻的爆发。配合化神期的"五行归一"天赋（完成全循环后下一张法术免费），可以先用免费法术消耗灵气，再用这张卡倾泻剩余的。

---

## 七、绝世悟道装备设计

### 五行灵珠（Five Elements Orb）

> "蕴含五行之力的灵珠，能感应持有者的法术气息。"

**装备类型**：talisman（法宝）/ jewelry（饰品）
**境界**：2（筑基）
**效果**：

- 元素共鸣触发时，额外获得 1 点灵气。
- 完成三元素共鸣链时，获得 1 层护盾（`shield_elemental`）。

设计意图：同时强化共鸣的资源回报和防御能力。适合喜欢稳定运营、打长局的玩家。

### 焚天炉（Heaven-Burning Brazier）

> "以火为引，焚尽万物。"

**装备类型**：talisman / armor
**境界**：3（结丹）
**效果**：

- 火系法术的灼烧伤害翻倍。
- 使用火系法术后，下一张非火系法术的共鸣伤害加成额外 +25%。
- 代价：每次触发共鸣时，受到 2 点真实伤害。

设计意图：高风险高回报的火系专精装备。鼓励"火系→其他→火系→其他"的节奏。生命损失需要通过木系的回血或 vigor 来弥补，形成自然的元素配合需求。

### 道法自然袍（Daoist Nature Robe）

> "顺应天道，不争而胜。"

**装备类型**：armor（衣袍）
**境界**：4（还婴）
**效果**：

- 灵气到达上限时，溢出的灵气不会浪费，而是转化为临时护盾（`shield_elemental`）。
- 每有 1 层护盾，法术伤害 +5%。

设计意图：改变灵气的管理方式——灵气不再是"满了就亏"的资源，而是可以转化为防御和伤害。适合高灵气生成速度的构筑。

---

## 八、悟道专属额外词条

这些额外词条只能出现在带有 `元素` 标签的卡牌上（即原悟道流派卡牌）。在软标签系统下，非悟道角色理论上也能使用这些卡牌（如果他们有灵气来源），但额外词条的控制权仍在卡牌生成时由 `card_affixes.json5` 中的 `genre: "spellcraft"` 过滤——只是这个过滤现在决定"哪些卡牌可以随机到这些词条"，而非"谁能使用这些卡牌"。

### 共鸣强化类

**resonance_mana_plus**

- uniqueId: `resonance_mana_plus`
- genre: `spellcraft`
- 效果：共鸣获得的灵气 +1。

**resonance_damage_plus**

- uniqueId: `resonance_damage_plus`
- genre: `spellcraft`
- rank: 2
- 效果：共鸣伤害加成额外 +10%。

**resonance_draw**

- uniqueId: `resonance_draw`
- genre: `spellcraft`
- rank: 3
- 效果：完成三元素共鸣链时，额外抽 1 张牌。

### 元素专精类

**fire_mastery**

- uniqueId: `fire_mastery`
- genre: `spellcraft`
- rank: 1
- 效果：火系法术的灼烧层数 +1。

**wind_mastery**

- uniqueId: `wind_mastery`
- genre: `spellcraft`
- rank: 1
- 效果：风系法术额外施加 1 层急速（`speed_quick`）给自身。

**earth_mastery**

- uniqueId: `earth_mastery`
- genre: `spellcraft`
- rank: 1
- 效果：土系法术伤害的 20% 无视护盾。

**lightning_mastery**

- uniqueId: `lightning_mastery`
- genre: `spellcraft`
- rank: 1
- 效果：雷系法术有 25% 几率不消耗灵气。

**wood_mastery**

- uniqueId: `wood_mastery`
- genre: `spellcraft`
- rank: 1
- 效果：木系法术的回血效果 +50%。

### 灵气操控类

**mana_on_element_cycle**

- uniqueId: `mana_on_element_cycle`
- genre: `spellcraft`
- rank: 2
- 效果：每次使用不同元素的法术时（不只相邻两张），获得 1 点灵气。

**overflow_mana_to_vigor**

- uniqueId: `overflow_mana_to_vigor`
- genre: `spellcraft`
- rank: 2
- 效果：回合结束时，未使用的灵气每 3 点转化为 1 点生机（`energy_positive_life`）。

---

## 九、实现优先级

### 第〇步：软标签系统迁移（基础设施）

如果决定采用软标签系统，需先完成：
- 在 `cards.json5` 中为所有卡牌添加 `tags` 字段承载元素/流派标签
- 修改 `checkRequirements()` 移除硬流派检查（`lib/logic/logic.dart`）
- 天赋节点的 `{genre}_rank` 被动扩展为携带标签加成效果（减费、资源生成等）
- 此步骤影响所有流派，应在具体机制设计前完成

### 第一步：元素标签系统（基础设施）

1. 为现有元素法术的 `tags` 添加元素标签
2. 在 `BattleCharacter` 中增加 `lastSpellElement` 字段（记录上一张法术的元素）
3. 在卡牌脚本执行时写入元素标签

### 第二步：核心共鸣被动

4. 在 `passives.json5` 中添加 `elemental_resonance_1` ~ `elemental_resonance_5`
5. 在 `card_script.ht` 的主词条脚本执行链中，插入共鸣检查逻辑
6. 在天赋树数据中，将共鸣被动关联到对应的 rank 节点

### 第三步：修改现有卡牌

7. 为 falling_stone 添加破盾效果（新脚本或扩展现有脚本）
8. 为 fireball 添加灼烧效果
9. 为 lightning 添加"对减速目标额外伤害"

### 第四步：新增卡牌

10. 实现 vine_whip、water_blast、fire_rage、earth_armor、lightning_speed
11. 实现对应的新脚本函数

### 第五步：绝世内容

12. 设计并实现 2-3 张绝世悟道卡牌
13. 设计并实现 2-3 件绝世悟道装备
14. 实现悟道专属额外词条

### 第六步：UI/反馈

15. 元素标签的视觉表现（卡牌边框颜色、打出时的粒子效果）
16. 共鸣触发时的屏幕反馈（如"共鸣！"文字弹出）
17. 天赋树中显示共鸣被动的说明
