# 补充计划 · 清气与浊气：完善阴阳气资源体系

> 此计划是对暴击系统重构（`REFACTOR_3_CRIT.md`）的补充。
> 可在阶段 3 完成后任意时机执行，独立于阶段 4/5。

## 背景与动机

当前阴阳气资源体系已基本完善，但尚有一对空缺：

**阳气已有**：元气、正气、豪气、**清气（预留）**、浩然之气、灵气、剑气、怒气、煞气、无极之气  
**阴气已有**：死气、戾气、衰气、**浊气（预留）**、萧索之气、逆灵之气、止戈之气、非战之气、无心之气、虚空之气

目前"清气"和"浊气"仅在本地化的阴阳气清单中占位，无实际状态效果。

同时，当前的**辟邪（ward）**状态效果独立于阴阳气体系之外，功能为"获得负面效果时消耗 1 层辟邪并取消该效果"。这是一个防御型状态，但设计上与阴阳气的资源哲学（消耗触发效果）并不完全契合。

**改造思路**：

1. 将**辟邪（ward）改为清气（energy_positive_ward）**，纳入阳气体系，定位为"防御型阳气资源"
2. 新增**浊气（energy_negative_ward）**作为对位阴气，定位为"负面状态转换器"
3. 保持原辟邪的核心机制（抵消负面效果），但改为阳气资源的形式
4. 浊气机制：回合开始时消耗并转化为随机负面效果（使用 `kDebuffs` 池）

这样做的好处：

- 补全阴阳气资源体系的最后一对（清气/浊气）
- 增强阴阳气体系的设计一致性（所有阴阳气都遵循"消耗触发效果"的模式）
- 为剑气溢出等机制提供更多负面状态来源（浊气可作为"负面状态源"）
- 提供更丰富的战术深度（清气防御 vs 浊气转化）

## 设计定案

| 项         | 当前（ward）                                    | 改造后（清气/浊气）                                                               |
| ---------- | ----------------------------------------------- | --------------------------------------------------------------------------------- |
| 清气 ID    | —                                               | `energy_positive_ward`                                                            |
| 清气机制   | —                                               | 获得负面效果时，消耗 1 层清气并取消该效果（继承原辟邪机制）                       |
| 清气优先级 | —                                               | 高优先级（在阴气转化之前触发）                                                    |
| 浊气 ID    | —                                               | `energy_negative_ward`                                                            |
| 浊气机制   | —                                               | 回合开始时，消耗 1 层浊气并获得 1 层随机负面效果（从 `kDebuffs` 池中抽取）        |
| 辟邪       | `ward`，独立状态，非阴阳气                      | **删除**（功能迁移至清气）                                                        |
| isResource | ward 不是资源                                   | 清气和浊气都是资源（`isResource: true`）                                          |
| 对位关系   | 无                                              | 清气与浊气互为对位（记录在 `kOppositeStatus` 映射中）                             |
| 回调时机   | `self_gained_debuff`                            | 清气：`self_gained_debuff`；浊气：`self_turn_start`                               |
| 池子       | —                                               | 浊气使用 `kDebuffs` 池（与剑气溢出共享）                                          |
| 本地化     | "辟邪"、"当你获得负面效果时，取消…"             | 清气："每层抵消一次负面效果"；浊气："回合开始时消耗并获得随机负面效果"            |
| 天赋词条   | `start_battle_with_ward`                        | 改名为 `start_battle_with_energy_positive_ward`，其他战斗开始阳气词条同步补充清气 |
| 图标       | `icon/status/energy_positive/negative_ward.png` |                                                                                   |

## 改动清单

### 1. 状态效果数据改造

**`assets/data/status_effect.json5`**：

- **删除** `ward` 状态条目
- **新增** `energy_positive_ward`（清气）：
  ```json5
  energy_positive_ward: {
    id: "energy_positive_ward",
    title: "status_energy_positive_ward",
    description: "status_energy_positive_ward_description",
    icon: "icon/status/energy_positive_ward.png",  // 复用原 ward 图标或新建
    script: "energy_positive_ward",
    isResource: true,
    priority: 1401,  // 高优先级（与原 ward 相同）
    callbacks: ["self_gained_debuff"],
  }
  ```
- **新增** `energy_negative_ward`（浊气）：
  ```json5
  energy_negative_ward: {
    id: "energy_negative_ward",
    title: "status_energy_negative_ward",
    description: "status_energy_negative_ward_description",
    icon: "icon/status/energy_negative_ward.png",  // 需要新图标
    script: "energy_negative_ward",
    isResource: true,
    callbacks: ["self_turn_start"],
  }
  ```

### 2. 状态效果脚本

**`scripts/main/cardgame/status_script.ht`**：

- **删除** `ward_self_gained_debuff` 函数
- **新增** 清气脚本：
  ```hetu
  /// 清气：获得负面效果时，消耗 1 层清气并取消该效果
  function energy_positive_ward_self_gained_debuff(self, opponent, effect, details) {
    if (!details.cancelDebuff) {
      details.cancelDebuff = true
      self.removeStatusEffect(effect.id, amount: 1)
    }
  }
  ```
- **新增** 浊气脚本：

  ```hetu
  /// 浊气：回合开始时，消耗 1 层浊气并获得 1 层随机负面效果（从 kDebuffs 池抽取）
  function energy_negative_ward_self_turn_start(self, opponent, effect, details) {
    if (self.hasStatusEffect('energy_negative_ward') > 0) {
      self.removeStatusEffect(effect.id, amount: 1)

      // 从 kDebuffs 池中随机选择一个负面效果
      final debuffId = random.nextIterable(kDebuffs)
      self.addStatusEffect(debuffId, amount: 1)
    }
  }
  ```

### 3. 对位关系映射

**`scripts/main/cardgame/common.ht`**：

- 在 `kOppositeStatus` 映射中添加清气/浊气对：
  ```hetu
  const kOppositeStatus = {
    // ... 现有映射 ...
    'energy_positive_ward': 'energy_negative_ward',
    'energy_negative_ward': 'energy_positive_ward',
  }
  ```

**`lib/scene/battle/character.dart`**：

- 在 `kResourceHasNegatives` 集合中添加清气：
  ```dart
  const kResourceHasNegatives = {
    'energy_positive_life',
    'energy_positive_penetrate',
    'energy_positive_crit',
    'energy_positive_ward',       // 新增
    'energy_positive_unarmed',
    'energy_positive_weapon',
    'energy_positive_spell',
    'energy_positive_curse',
    'energy_positive_shield',
  };
  ```

### 4. 天赋与装备词条

**`assets/data/passives.json5`**：

- **删除或改名** `start_battle_with_ward` → `start_battle_with_energy_positive_ward`：
  ```json5
  start_battle_with_energy_positive_ward: {
    id: "start_battle_with_energy_positive_ward",
    description: "passive_start_battle_with_energy_positive_ward_description",
    priority: 2989,
    increment: 0.5,
    keywords: ["status_energy_positive"],
  }
  ```

**`assets/data/passive_skills.json5`**：

- 查找所有引用 `start_battle_with_ward` 的天赋节点
- 替换为 `start_battle_with_energy_positive_ward`
- 注意保持节点坐标和 `connectedNodes` 不变（原位替换）

### 6. 本地化字符串

**`assets/locale/zh/rpg/status_effect.json`**：

- **删除** `status_ward` 和 `status_ward_description`
- **新增** 清气条目：
  ```json
  "status_energy_positive_ward": "清气",
  "status_energy_positive_ward_description": "获得负面效果时，消耗 1 层清气并取消该效果。",
  ```
- **新增** 浊气条目：
  ```json
  "status_energy_negative_ward": "浊气",
  "status_energy_negative_ward_description": "回合开始时，消耗 1 层浊气并获得 1 层随机负面效果。",
  ```

**`assets/locale/zh/rpg/passive.json`**：

- **删除或改名** `passive_start_battle_with_ward_description`：
  ```json
  "passive_start_battle_with_energy_positive_ward_description": "战斗开始时 {0} 层清气",
  ```

### 7. 战斗系统集成检查

**`lib/scene/battle/battle.dart`**：

- 检查 `kSelfStatusOnCircumstance` 和 `kOpponentStatusOnCircumstance` 映射
- 确认清气/浊气的战斗开始生成逻辑与其他阴阳气一致
- `_prepareStatus` 函数应自动支持新阴阳气（基于 passive ID 模式匹配）

**`lib/scene/battle/character.dart`**：

- `getResourceColor` 函数添加清气/浊气颜色映射：
  ```dart
  Color getResourceColor(String resourceType) {
    return switch (resourceType) {
      'energy_positive_ward' || 'energy_negative_ward' => Colors.white,  // 建议：清气白色、浊气灰色或黑色
      // ... 其他映射 ...
    };
  }
  ```

### 9. 游戏内容适配

**卡牌与词条检查**：

- 搜索所有生成辟邪的卡牌词条（`assets/data/card_affixes.json5`）
- 替换 `ward` 为 `energy_positive_ward`
- 确认没有遗漏的引用

**事件与对话检查**：

- 搜索 `scripts/main/event/` 中所有提到辟邪（ward）的事件脚本
- 替换为清气（energy_positive_ward）
- 同步更新对话文本（如有）

## 实施步骤建议

1. **美术资源准备**（可并行）
   - 复用/移动辟邪图标为清气图标
   - 设计并导入浊气图标

2. **数据改造**（核心）
   - 修改 `status_effect.json5`
   - 修改 `passives.json5` 和 `passive_skills.json5`
   - 更新本地化字符串

3. **脚本逻辑**
   - 实现清气和浊气的状态脚本
   - 更新 `kOppositeStatus` 和 `kResourceHasNegatives`
   - 检查并修正 `kDebuffs` 池

4. **代码适配**
   - 更新 `getResourceColor` 等 UI 辅助函数
   - 检查战斗场景集成

5. **内容迁移**
   - 搜索并替换所有 `ward` 引用
   - 确认卡牌、事件、对话中的辟邪都改为清气

6. **编译与验证**
   - 运行 `python build.py` 编译脚本
   - `flutter analyze` 检查错误
   - 实机测试：清气抵消负面效果、浊气转化为 debuff

## 验证清单

- [ ] 编译通过，`flutter analyze` 无新增错误
- [ ] 实机：战斗中获得清气后，下次获得负面效果时清气消耗并取消该效果
- [ ] 实机：战斗中获得浊气，回合开始时浊气消耗并获得随机负面效果（来自 kDebuffs 池）
- [ ] 实机：清气和浊气作为阴阳气资源正确显示在状态栏中（与其他阴阳气排列一致）
- [ ] 实机：清气和浊气互为对位状态（获得清气时浊气抵消，反之亦然）
- [ ] 天赋树和装备中不再出现"辟邪"词条，改为"清气"
- [ ] 所有原辟邪相关的卡牌、事件正常工作（改为清气后）

## 涉及文件清单

### 数据文件

- `assets/data/status_effect.json5`
- `assets/data/passives.json5`
- `assets/data/passive_skills.json5`
- `assets/data/card_affixes.json5`（如有生成辟邪的词条）

### 脚本文件

- `scripts/main/cardgame/status_script.ht`
- `scripts/main/cardgame/common.ht`
- `scripts/main/event/`（搜索 ward 引用）

### Dart 代码

- `lib/scene/battle/character.dart`
- `lib/scene/battle/battle.dart`（检查，可能无需改动）

### 本地化

- `assets/locale/zh/rpg/status_effect.json`
- `assets/locale/zh/rpg/passive.json`

### 美术资源

- `assets/images/icon/status/ward.png`（改名或复用）
- `assets/images/icon/status/energy_positive_ward.png`（新建或移动）
- `assets/images/icon/status/energy_negative_ward.png`（新建）

### 文档

- `docs/docs/how2play/rpg/battle/resource/readme.md`（补充清气/浊气说明）

## 设计注意事项

1. **清气优先级**：清气的 `self_gained_debuff` 回调优先级应高于其他状态（如辟邪在原设计中 priority 为 1401），确保在其他状态效果之前触发。

2. **浊气与剑气溢出**：浊气和剑气溢出共享 `kDebuffs` 池，这是设计意图——它们都是"负面状态生成器"，使用同一个池保持一致性。

3. **阴阳气对称性**：清气/浊气的设计应与其他阴阳气对保持一致：
   - 清气作为防御型阳气，与浩然之气（护盾）形成"主动防御 vs 被动防御"的区别
   - 浊气作为负面状态源，与萧索之气（伤害翻倍）形成"持续干扰 vs 瞬间爆发"的区别

4. **向后兼容**：
   - 旧存档中的 `ward` 状态在加载时需要处理（自动转换为 `energy_positive_ward` 或直接忽略）
   - 建议在 `scripts/main/data/character/battle_entity.ht` 的属性计算逻辑中添加兼容处理

## 与其他重构阶段的关系

- **独立于阶段 4/5**：清气/浊气改造不涉及元素拆分或精神对抗，可以独立执行
- **建议顺序**：在阶段 3（暴击系统）完成后执行，因为此时阴阳气体系已基本定型
- **文档更新**：完成后需要更新 `docs/docs/how2play/rpg/battle/resource/readme.md`，补充清气/浊气的说明

## 后续优化方向（可选）

1. **清气进阶机制**：
   - 每抵消一次负面效果，清气层数 -1，但同时获得 1 层"净化"buff（增加伤害或恢复）
   - 清气溢出时转化为护甲或其他防御资源

2. **浊气进阶机制**：
   - 浊气层数越多，转化的负面效果层数越多（如 3 层浊气 → 3 层随机 debuff）
   - 浊气可以"感染"对手（对手获得浊气时，自己也获得一定比例）

3. **清气/浊气的卡牌设计**：
   - 生成清气的防御牌（类似原辟邪牌，但融入阴阳气资源玩法）
   - 利用浊气的控场牌（主动堆叠浊气给对手，形成"污染"战术）

---

**总结**：此改造将辟邪纳入阴阳气体系，补全清气/浊气这对最后的资源，增强设计一致性。清气继承辟邪的防御功能，浊气作为负面状态转换器提供新的战术维度。改造范围适中，主要涉及数据和脚本，代码层面影响较小。
