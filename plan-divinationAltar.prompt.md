## Plan: 观星台（Divination Altar）占卜逻辑

在 `_onInteractNpc` 的 else 分支中，为 `divinationaltar` 添加"占卜"选项。占卜分为占卜自己/占卜他人，用灵石支付（baseCost × (rank+1)），结果以5档模糊文字呈现。

---

### Phase 1: 添加常量

1. [common.dart](lib/data/common.dart) — 添加占卜相关常量：
   - `kDivinationSelfBaseCost`（占卜自己基础灵石费用，1）
   - `kDivinationOtherBaseCost`（占卜他人基础灵石费用，2）
   - 5档阈值常量，用于将数值映射到模糊描述

### Phase 2: 核心逻辑

2. [character.dart](lib/logic/character.dart) — 修改 `_onInteractNpc` else 分支（~L1263）：
   - 在 `workshop` / `alchemylab` / `dungeon` 的 `else if` 链中，加入 `else if (siteKind == 'divinationaltar')` → 添加 `'divination'` 选项
   - 在 `switch (selected)` 中添加 `case 'divination': _heroDivination(location);`

3. [character.dart](lib/logic/character.dart) — 新增 `_heroDivination(dynamic location)` 函数：
   - NPC 古风台词介绍功能
   - 选择：占卜自己 / 占卜他人 / 取消
   - **占卜自己**：费用 = `kDivinationSelfBaseCost * (hero['rank'] + 1)`，检查灵石，扣除后展示 luck/wisdom/寿元 的5档描述
   - **占卜他人**：通过 `GameLogic.selectCharacter(ids: hero['bonds'].keys)` 选择目标，费用 = `kDivinationOtherBaseCost * (target['rank'] + 1)`，展示 charismaFavor（5档）、cultivationFavor（直接 locale 翻译）、sectFavor（直接 locale 翻译）
   - 灵石扣除使用 `engine.hetu.invoke('exhaust', namespace: 'Player', positionalArgs: ['shard', ..., cost])`

### Phase 3: 本地化

4. [site.json](assets/locale/zh/site.json) — 添加所有占卜相关中文字符串：
   - 选项文字、NPC古风台词、费用提示、灵石不足提示、占卜结果模板、5档描述词（极低/低/中/高/极高）、寿元专用5档（命不久矣/寿元堪忧/阳寿尚可/福寿绵长/长生有望）

---

### Relevant Files

- [lib/data/common.dart](lib/data/common.dart) — 新增常量
- [lib/logic/character.dart](lib/logic/character.dart) — 修改 `_onInteractNpc`、新增 `_heroDivination`
- [assets/locale/zh/site.json](assets/locale/zh/site.json) — 新增本地化文本

### Decisions

- **货币**：灵石（shard）
- **公式**：baseCost × (rank + 1)
- **结果**：5档模糊描述，不显示具体数值
- **选人范围**：hero 的 bonds keys（已遇到的角色）
- **寿元**：通过 `deathTimestamp - game['timestamp']` 算剩余，再映射5档
- **不包含**：占卜位置/场景坐标功能（设计文档提及但本次不做）
- **寿元5档的阈值** 基于当前 rank 的期望寿命（`getLifeSpanForRank`）按比例划分（<20%=极低, 20-40%=低, 依此类推）。
- **charismaFavor 的5档阈值** — 获得指定角色的charismaFavor之后，可以通过对方喜欢的魅力数值和自己数值的差额，来判断对方西幻自己的程度.
