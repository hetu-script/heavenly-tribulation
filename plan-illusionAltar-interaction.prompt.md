## Plan: 幻术堂交互逻辑设计与实现

幻术堂（illusionaltar）是炼魂流派的特色建筑，定位为身份伪装与潜入系统。核心功能是让玩家获得虚假的门派身份和境界，从而绕过敌对门派的入城盘问，进入原本无法进入的据点。

### 前置依赖

- 门派外交系统（diplomacy）已有数据结构（`Diplomacy` struct, score/type 已存储），但 **入城限制尚未实施**
- 入城盘问系统已有设计文档（`docs/docs/how2play/tycoon/site/readme.md` 中 6 种选项），但 **尚未实现**
- `_tryEnterLocation()` 中有 `onBeforeEnterLocation` 的 hook 点，但 **脚本侧未实现**
- 幻术堂的建筑基础设施已就绪（NPC: illusionist, 常量、费用、本地化全部已有）

### 功能设计

#### 1. 获取伪装（核心功能）

进入幻术堂后，与幻术师（illusionist）NPC 互动，菜单中出现「易容伪装」选项。

玩家选择要伪装成的身份：

- **伪装门派**：选择一个已知门派（曾遭遇过的），伪装成该门派弟子
- **伪装境界**：选择等于或低于自身真实境界的等级
- **伪装为凡人**：最基础的伪装，不需要指定门派

伪装以状态效果（status effect）的形式附加在角色身上：

- 持续时间：30 天（一个月），到期自动消失
- 费用：灵石，根据伪装境界和幻术堂规模计算
- 同一时间只能持有一个伪装

#### 2. 解除伪装

玩家可以随时在任意幻术堂解除当前伪装（免费），或者等待到期自动消失。
在非幻术堂场景中也可以通过角色面板手动解除。

#### 3. 识别伪装（development >= 2 解锁）

升级后的幻术堂可以提供「识破伪装」服务：

- 选择一个当前城市中的 NPC，花费灵石检测其是否使用了伪装
- 这对应了门派任务中已设计的「幻术堂：识别乔装的奸细」任务

#### 4. 改变外貌（development >= 4 解锁，远期功能）

文档中提到的「改变角色或城市样貌」属于远期功能，本次不实现。

### 伪装与入城盘问的交互

当前入城盘问尚未实现（`onBeforeEnterLocation` 未编写）。幻术堂的伪装功能需要与入城盘问协同设计：

#### 入城检查流程（需同步实现）

1. 玩家进入敌对门派城市时触发 `onBeforeEnterLocation`
2. 检查玩家与该城市门派的外交关系（diplomacy score < kDiplomacyScoreEnemyThreshold = -50）
3. 如果是敌对关系，触发盘问事件：
   - 如果玩家有伪装状态且伪装门派与该城市门派不敌对 → 自动通过（有小概率被识破）
   - 如果玩家无伪装 → 弹出 6 选项对话（表明身份/隐瞒/突破/说服/行贿/潜入）
4. 识破概率受以下因素影响：
   - 幻术堂规模（制作伪装时的）- 降低识破率
   - 目标城市守卫等级 - 提高识破率
   - 玩家境界与伪装境界的差距 - 差距越大越容易被识破

### 伪装数据结构

作为 status effect 存储在英雄身上：

```
disguise: {
  disguiseSectId: 'xxx',     // 伪装的门派 ID（凡人伪装为 null）
  disguiseRank: 2,           // 伪装的境界
  duration: 2880,            // 持续时间（ticks，30天 = 2880）
  sourceQuality: 3,          // 制作时幻术堂的 development，影响识破率
}
```

---

### 实现步骤

#### Phase 1: 伪装状态效果

1. 在 `assets/data/status_effect.json5` 中新增 `disguise` 状态效果定义
2. 在 `assets/locale/zh/` 中添加伪装相关的本地化字符串（状态名称、描述、菜单文本）

#### Phase 2: NPC 交互 — 获取与解除伪装

3. 在 `lib/logic/character.dart` 的 `_onInteractNpc` 中，为 `siteKind == 'illusionaltar'` 添加「易容伪装」和「解除伪装」菜单项
4. 实现伪装选择 UI：门派选择列表 + 境界选择（需要新的对话或选择面板）
5. 在 `scripts/main/` 中实现伪装效果的添加和移除逻辑，将 disguise 信息存入英雄的状态效果列表

#### Phase 3: 入城盘问系统（与伪装联动）

6. 在 `scripts/main/event/game.ht` 中实现 `onBeforeEnterLocation` 事件处理：
   - 检查玩家与城市门派的 diplomacy 关系
   - 敌对时检查伪装状态，计算识破概率
   - 无伪装或被识破时弹出盘问选项对话
7. 实现 6 种盘问选项的结果逻辑（表明身份 → 战斗，隐瞒 → 检定，突破 → 战斗，等等）

#### Phase 4: 识别伪装（门派任务关联）

8. 为幻术堂 NPC 添加「识破伪装」菜单项（development >= 2），选择城市内 NPC 进行检测
9. 在门派任务中实现「识别乔装的奸细」任务类型

### 涉及文件

- `assets/data/status_effect.json5` — 新增 disguise 状态效果
- `scripts/main/event/game.ht` — 实现 `onBeforeEnterLocation` 入城检查
- `lib/logic/character.dart` — `_onInteractNpc` 中添加幻术堂交互分支
- `lib/logic/location.dart` — `_tryEnterLocation` 中确认 hook 点正确触发
- `scripts/main/data/` — 伪装创建/移除/检测的脚本逻辑
- `assets/locale/zh/` — 本地化字符串
- `docs/docs/how2play/tycoon/site/readme.md` — 更新幻术堂建筑说明

### Verification

1. 进入有幻术堂的城市，与幻术师互动，确认「易容伪装」菜单出现
2. 选择门派和境界后，角色获得伪装状态效果
3. 携带伪装进入敌对门派城市时，自动通过盘问（或按概率被识破）
4. 无伪装进入敌对城市时，弹出盘问选项对话
5. 伪装到期自动消失，手动解除也正常工作
6. `python build.py` 编译通过

### Decisions

- 伪装以 status effect 形式实现，与现有状态效果系统保持一致
- 入城盘问系统是幻术堂功能的前置依赖，需一并实现（Phase 3）
- 初版盘问只实现「表明身份→战斗」「有伪装→通过/识破」两条路径，其余（说服/行贿/潜入）留到后续
- 「改变外貌」功能属于远期目标，本次不实现
- 伪装持续时间固定 30 天，不做动态调整

### Further Considerations

1. **伪装与 NPC 互动的影响**：伪装状态下，敌对门派 NPC 是否会以伪装身份对待玩家？（推荐：是，保持一致性。被识破后切换为敌对行为）
2. **存档兼容性**：disguise 状态效果需要在存档加载时正确恢复。建议使用现有 status effect 的序列化机制，无需额外处理
3. **NPC 是否也能使用伪装**：这会增加丰富度（对应「识别奸细」任务），但会增加复杂度。推荐初版仅限玩家，NPC 伪装在后续版本实现
