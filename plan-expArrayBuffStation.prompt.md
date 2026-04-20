## Plan: 聚灵阵重构为战斗Buff站

移除修炼场景（scenes/cultivation/cultivation.dart）中的 collect/exhaust 经验收集模式，新增 `exparray` 模式——花费灵石进入，通过类似问道碑（daostele）的交互（光点收集→文字选择）获得临时战斗buff。development 决定可获得的 buff 数量（0→1, 5→6），中途失败仍保留之前成功轮次的已获 buff。

---

### Phase 1: 数据与常量定义

1. **新增 exparray 常量和文字选项** — `lib/scene/cultivation/cultivation.dart`
   - `CultivationMode.exparray` 枚举值
   - `kExpArrayCategoryPhrases` — 4 类 buff 的 locale key → value map（攻击/防御/属性/能量池），结构同 `kDaoSteleCategoryPhrases`
   - 复用 `kDaoSteleLightTarget`、`kDaoSteleOrbsPerColor`，或定义 exparray 专用常量
   - 干扰项复用 `kDaoSteleNonsensePhrases` 或新建 exparray 专用列表

2. **定义 buff 类别到 passive ID 的映射** — 在 Hetu 脚本中定义
   - **攻击**: `unarmedAttack`, `weaponAttack`, `spellAttack`, `curseAttack`, `start_battle_with_energy_positive_*` (7种)
   - **防御**: `*Resist` (4种), `start_battle_with_defense_*` (4种), `start_battle_with_ward/shield_*` (5种)
   - **属性**: `dexterity`, `spirituality`, `strength`, `willpower`, `perception`
   - **能量池**: `lifeMax`, `manaMax`, `chakraMax`, `karmaMax`, `start_battle_with_speed_quick`, `start_battle_with_dodge_nimble`

3. **新增本地化字符串** — `assets/locale/zh/` JSON 文件
   - exparray 提示文字、类别名称、干扰项文字

---

### Phase 2: Dart 侧修炼场景重构

4. **修改 `CultivationMode` 枚举** — 移除 `collect`/`exhaust`，新增 `exparray`

5. **移除 collect/exhaust 相关代码** — 涉及 `collectableLight` getter/setter、`checkAvailableMode()` 级联逻辑、`tick()` 自动吸收、`updateExpLightPoints()` 颜色逻辑、`updateInformation()` 灵光显示、`setMeditateState()` 分支

6. **新增 exparray 冥想状态** — `_expArrayRound`、`_expArrayMaxRounds = development + 1`、`_expArrayGrantedBuffs` 等变量

7. **实现 exparray 冥想流程** — 复用 daostele 架构模式:
   - `_startExpArrayMeditation()` → 初始化、扣灵石、开始第一轮
   - 光点阶段: 复用 daostele 光点逻辑
   - 文字阶段: 显示 4 个 buff 类别名 + 胡言乱语干扰项
   - 成功 → 调用 Hetu 生成该类别随机 buff → `characterSetEphemeralPassive()`
   - 失败 → 保留已获 buff，退出冥想
   - 所有轮次完成 → 退出冥想

8. **修改场景入口 `onStart()`** — 通过 `location.kind` 判断模式，移除 `enableCultivate`/`enableDaoStele` 参数

9. **修改 UI 按钮** — `cultivateButton`、`setMeditateState()`、`checkAvailableMode()` 新增 exparray 分支

---

### Phase 3: Hetu 脚本侧

10. **新增 buff 生成函数** — `scripts/binding/player.ht`
    - `Player.getExpArrayBuff(category, rank)` → 根据类别过滤 buff 池，根据境界 rank 随机选择一个介于境界最小等级和最大等级之间的buff，并直接使用characterSetEphemeralPassive赋予玩家角色。

---

### Phase 4: 据点交互入口

11. **修改 `_onInteractExpArray()`** — `lib/logic/location.dart`
    - 进入前扣除 `development + 1` 灵石，不足则提示
    - 推送修炼场景

12. **清理 `collectableLight` 逻辑** — 移除 location 上的该属性管理、月初补充等

---

### Phase 5: 清理与验证

13. **清理残留代码** — 移除 collect/exhaust 全部分支、相关常量

---

### 进一步考虑

14. **`expCollectSpeed`、`collectableLight`、`expGainPerLight` 清理**: location 的 `collectableLight` 属性及月初补充逻辑需一并清理，可能涉及世界事件脚本，expCollectSpeed 和 expGainPerLight 可先不修改，而是提供修改方案用玩家选择
15. **教程文本**: 如现有修炼教程引用了 collect/exhaust 内容需更新

---

### 相关文件

- `lib/scene/cultivation/cultivation.dart` — 主修改，冥想模式重构
- `lib/logic/location.dart` — 据点交互入口 `_onInteractExpArray()`
- `lib/data/common.dart` — 常量
- `scripts/main/data/character/battle_entity.ht` — `characterSetEphemeralPassive()` 复用
- `scripts/main/event/cultivation.ht` — buff 生成逻辑
- `assets/locale/zh/` — 本地化字符串
