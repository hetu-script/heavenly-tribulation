# 暴击/异常计数器重构计划

## 背景

当前暴击与元素异常采用按次独立随机判定（`lib/scene/battle/character.dart` 中 `random.nextInt(100) < critChance` / `ailmentChance`）。回合制卡牌战斗的伤害实例样本量小，随机暴击的方差无法像 ARPG 那样被大数定律抹平，且敌人随机暴击玩家属于不可管理的下行风险。

重构目标：将暴击和元素异常改造为与速度/闪避一致的**累积型状态 + 阈值属性**范式，消除结算阶段的随机性，使敌我双方的爆发节奏完全可预告、可规划。

## 设计定案（已确认）

1. **暴击计数器 `crit_charge`**：每造成一次物理伤害实例 +1（按次数，不看伤害数值；多段牌每段各 +1）。计数达到阈值后，**下一次**物理伤害实例消耗阈值点数并暴击——作用于单个伤害实例，而非整张牌。
2. **异常计数器 `ailment_charge`**：火/冰/雷/毒**共享**同一计数器，每造成一次元素伤害实例 +1。达到阈值后，下一次元素伤害实例消耗阈值并触发异常，异常类别取该次伤害的元素，层数 = 伤害 ÷ 10（与豪气的必异常规则一致）。
3. **阈值属性 `critThreshold` / `ailmentThreshold`**：基础 10，clamp 5~15，可被天赋、装备（passives）和战斗状态（ephemeralPassives）修改，低者优——与 `quickThreshold` 等现有阈值属性统一。
4. **豪气/衰气机制不变**：豪气的必暴/必异常走独立路径，不消耗计数器（但作为伤害实例照常 +1 充能）；衰气削弱暴击倍率/抵消异常的现有逻辑原样保留。
5. **删除随机判定**：`critChance`、`ailmentChance` 两个属性及其随机 roll 全部移除；`critMultiplier`、`ailmentMultiplier` 保留不变。

## 实现步骤

### 1. Dart 常量与绑定

- `lib/data/common.dart`：新增 `kBaseCritThreshold = 10`、`kBaseAilmentThreshold = 10`（百分比整数制之外的纯点数），以及 min/max clamp 常量（参考 `kMinTurnActionThreshold = 5` / `kMaxTurnActionThreshold = 15`，可复用或单设）；删除 `kBaseCritChance`（:1284）、`kBaseAilmentChance`（:1290）。
- `lib/data/constants.dart`：同步导出变更；`scripts/main/binding/constants.ht` 中 `baseCritChance` → `baseCritThreshold`，`baseAilmentChance` → `baseAilmentThreshold`。
- `scripts/main/binding/player.ht`：仿 `kQuickThreshold` 补充 `kCritThreshold` / `kAilmentThreshold` 常量（如该文件是阈值常量的统一出口）。

### 2. 伤害结算（`lib/scene/battle/character.dart`）

`takeDamage`（:774）逐伤害实例结算，DoT 走 `changeLife` 不经过此函数，天然排除充能循环，无需额外标记。

- **暴击分支**（:852-874）：
  - 删除 `random.nextInt(100) < critChance` 随机判定。
  - 改为：结算物理伤害实例前，检查攻击方 `crit_charge >= critThreshold` → 扣除阈值层数，本次伤害按暴击处理（保留衰气循环减倍率逻辑 :863-870）。
  - 豪气 `guaranteedCrit` 路径保留（:857-860），不消耗计数器。
- **异常分支**（约 :930-960）：
  - 删除 ailmentChance 随机 roll（`random.nextInt(100) < ailmentChance`）。
  - 改为：检查攻击方 `ailment_charge >= ailmentThreshold` → 扣除阈值层数，`stacks = finalDamage ~/ 10`（对齐豪气必异常）；保留衰气按层抵消逻辑。
  - 豪气 `guaranteedAilment` 路径保留。
- **充能**：每个伤害实例结算完毕后，物理伤害给攻击方 `crit_charge +1`，元素伤害给攻击方 `ailment_charge +1`（真气/精神/纯粹不充能）。
- 触发顺序定案：先检查并触发（消耗阈值），再为本实例充能——保证满计数后恰每阈值次数触发一次。

### 3. 伤害预览（`character.dart` `predictDamage` :289）

预览当前只算确定性部分，计数器触发是确定性的，应纳入：

- 物理词条：攻击方 `crit_charge >= critThreshold` 时 `isCrit = true`（同样预览衰气扣减后的倍率）。
- 元素词条：攻击方 `ailment_charge >= ailmentThreshold` 时 `ailmentStacks = damage ~/ 10`。
- 更新函数注释（"只计算确定性部分"的描述需涵盖计数器触发）。

### 4. Hetu 属性计算（`scripts/main/data/character/battle_entity.ht`）

- 删除 :362 的 `critChance` 和 :366 的 `ailmentChance` 计算行；`critMultiplier`（:363）、`ailmentMultiplier`（:367）保留。
- 仿 :394 `quickThreshold` 公式新增：

  ```
  critThreshold = (baseCritThreshold + passives.critThreshold + ephemeralPassives.critThreshold).clamp(min, max)
  ailmentThreshold = 同上
  ```

  与速度阈值不同：不挂属性（神识/念力）修正，只接受天赋/装备/战斗状态三个来源（定案）。

### 5. 状态定义（`assets/data/status_effect.json5`）

新增两个累积型计数状态，无 script 回调（纯计数标记，触发逻辑在 Dart 侧，同衰气的处理方式）：

- `crit_charge`（暴击充能）：标题/描述本地化键 `status_crit_charge` / `status_crit_charge_description`。
- `ailment_charge`（异常充能）：`status_ailment_charge` / `status_ailment_charge_description`。

图标暂复用现有状态图标占位，后续补美术（记入 KNOWN_ISSUES 或 TODO）。

### 6. 词条迁移（`assets/data/passives.json5`）

- `critChance` 条目（:394）改为 `critThreshold`；`ailmentChance` 条目（:440）改为 `ailmentThreshold`。保留 `isItem` / `isEphemeral` / `kinds` / `keywords` 结构。
- 语义反转：数值为负时降低阈值（低者优）。实现时确认词条系统对负 increment 的支持；若不支持，调整数值符号约定或在描述中写明。
- `critMultiplier`、`ailmentMultiplier` 词条不动。
- 卡牌词缀（`card_affixes.json5`）只有 `gain_resource_crit`（豪气相关），不受影响；天赋盘（`passive_skills.json5`）无 critChance/ailmentChance 节点，无需迁移。

### 7. 本地化（`assets/locale/zh/`）

- `rpg/status_effect.json`：新增 `status_crit_charge`、`status_crit_charge_description`、`status_ailment_charge`、`status_ailment_charge_description`（描述参照 `status_speed_quick_description` 的写法，说明积累与触发规则）。
- `rpg/character.json`：`critChance` / `ailmentChance` 条目替换为 `critThreshold` / `ailmentThreshold`（名称 + 描述，注明"基础为 10，低者优"）；`critMultiplier` / `ailmentMultiplier` 保留。
- 检查 `critHint`、`critPredictedHint` 文本在新机制下仍然适用。

### 8. 属性面板（`lib/widgets/character/stats.dart`）

- `kMoreStats`（:39-41）：`critChance` → `critThreshold`，`ailmentChance` → `ailmentThreshold`。
- 显示分支：删除 :150-165 的 critChance/ailmentChance 处理，新增阈值显示逻辑（整数点数、低者优的高亮方式，参照 quickThreshold 既有分支）。

### 9. 文档

- `docs/docs/how2play/rpg/battle/readme.md` :135-142 暴击/异常段落重写：物理伤害"计数器满后下一击暴击"；元素伤害"共享计数器满后下一击造成异常（每满 10 点伤害 1 层）"；伤害对照表 :168-173 同步。
- `docs/docs/how2play/rpg/battle/resource/readme.md` 中涉及暴击的描述同步。
- 本计划完成后更新 AGENTS.md（如有机制描述受影响）。

### 10. 构建与验证

1. 重新编译 Hetu 脚本（VSCode `compileAllGameScripts` 任务或 `python build.py`）。
2. `flutter analyze` 无新增告警。
3. 战斗内实测清单：
   - 物理伤害逐次充能，计数器层数在状态栏可见；
   - 计数满后下一次物理伤害暴击并扣除阈值层数（多段牌仅一段暴击）；
   - 元素共享计数器：混用两种元素伤害可共同充能，触发时异常类别取触发伤害的元素；
   - 异常层数 = 伤害 ÷ 10，受 ailmentMultiplier 放大；
   - 豪气必暴不消耗计数器；衰气正常削减暴击倍率/抵消异常；
   - 手牌预览正确显示"将暴击"/"将造成异常"（predictedCrit / predictedAilment）；
   - 敌方同样积累计数器，玩家可据其层数预判爆发回合。

## 不做的事（本次范围外）

- 衰气的扩展效果（按层扣减计数器）：留待后续平衡性评估。
- 敌人 AI 主动利用"下次必暴"信息选择大牌：AI 增强另立项。
- 精神/纯粹伤害的对应爆发机制：框架上预留，暂不实现。
- 计数器状态的美术图标：先用占位图标。
