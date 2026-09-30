---
name: passive-status
description: |
  在《天道奇劫》中把关键天赋（境界节点/分支节点）或装备词条的战斗效果实现为「永久状态」时使用。
  涵盖五层同步流程：状态数据（assets/data/status_effect.json5）、状态脚本（scripts/main/cardgame/status_script.ht）、
  本地化（assets/locale/zh/rpg/status_effect.json）、状态图标生成（image-gen skill，Gemini 后端 + 缩放 150×150）、
  被动绑定（passives.json5 的 battleStatus 字段）。当任务涉及天赋节点状态化、战斗永久状态/状态图标创建、
  装备战斗效果落地时加载本技能。
---

# 被动战斗状态创建技能（关键天赋 / 装备词条）

架构准则（见 `AGENTS.md`「战斗内容分层」）：天赋与装备的战斗行为统一走状态回调总线——
被动携带 `battleStatus` → 战斗开始授予永久状态 → `status_script.ht` 状态脚本实现行为。
一次落地 = **状态数据 + 状态脚本 + 本地化 + 图标 + 被动绑定**，五层同步，缺一不可。

现成样板（先读再改）：
- 太上忘情 `buff_handcards_to_mana`（`self_turn_end` + 自定义字段 `damagePerCard`/`resourceId`）
- 三清法相 `buff_element_amplify_*`（`self_doing_damage` + 自定义字段 `damageType`，独立乘区2）

## 0. 先判断：该做状态吗？

**只有战斗中反复触发的行为效果才制作永久状态。** 三类效果的分流：

| 效果类型                                                         | 做法                                                                                          |
| ---------------------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| 行为型（时机 X 反复触发做 Y：扣血/上状态/转资源/抽牌）           | 永久状态 + 状态脚本（本技能流程）                                                             |
| 参数型（观星深度、费用修正、资源保留上限、异常层数修正等）       | **不做状态**；Dart 机制读 stats/被动字段（stats 管线见第 6 节，机制清单见 `plan/battle_script_migration.md` 阶段 1） |
| 纯属性/单值修改（攻防、抗性、流派伤害增加等装备词条式被动）      | **不做状态**；stats 聚合管线自动处理（`battle_entity.ht` → `kStatsToPermanentEffects` 转图标，图标仅展示净值，无回调；新增 stat 见第 6 节） |

一件天赋/装备可以同时有参数半 + 状态半（如窥天镜 = 观星深度参数 + 观星后自施异常状态）。

## 1. 状态数据（status_effect.json5）

- 顶层对象，键 = 状态 id（snake_case，英文含义），`id` 字段必须等于键名。
- 与被动一对一绑定时状态 id 可直接复用被动 id，便于追溯。
- 放在对应分区的注释区块下（无合适分区则新建，如「悟道境界节点状态」）。

```json5
spellcraft_rank_3: {
  id: "spellcraft_rank_3",
  title: "status_spellcraft_rank_3",                 // 本地化键
  description: "status_spellcraft_rank_3_description",
  icon: "icon/status/permanent/spellcraft_rank_3.png",
  isPermanent: true,                                  // 永久状态：大图标绘于卡组上方，免回合末清理
  script: "yin_yang_five_elements",                   // StatusScript 函数前缀
  callbacks: ["self_turn_end"],                       // 时机列表，见下方约束
  // 自定义参数字段（脚本经 effect.xxx 读取；数值写在这里，不写死在脚本里）
  damagePerStack: 5,
},
```

- `icon` 路径相对 `assets/images/`；永久状态图标固定放 `icon/status/permanent/` 子目录。
- 常用标记：`isPermanent`（永久）/ `isOngoing`（限回合）/ `isUnique`（唯一）/ `isResource`（资源气）。

## 2. 状态脚本（status_script.ht）

- 函数名 = `{script}_{时机}`，统一签名 `function xxx(self, opponent, effect, details)`。
  - `self`/`opponent`：状态持有方/对方的 BattleCharacter（API 见 `battle_character.ht`）。
  - `effect`：状态实例，读 `effect.amount`（层数）与数据自定义字段（如 `effect.damagePerStack`）。
  - `details`：时机事件参数（如 `self_doing_damage` 的伤害明细表，可直接改 `details.percentageChange1`）。
- **硬约束：非阻塞、不可交互**。不能 `async`；不能调用返回 Future 的 API
  （`takeDamage`/`upgradeHandCards`/`drawCards`/`scry`/`discover`）。
  伤害用 `changeLife` 同步结算；资源用 `addStatusEffect`；查询用 `hasStatusEffect`/`getHandCards`/`getLastUsedCard`。
- 时机以 Dart 实际分发点为准（`character.dart` 中 `handleStatusEffectCallback('...')` 调用处），
  文件头注释列表如有出入以代码为准。
- **敌我对称**：状态总线对双方角色都跑，脚本里想清楚效果施加在谁身上。

## 3. 本地化（assets/locale/zh/rpg/status_effect.json）

- `"status_{id}": "名称"`、`"status_{id}_description": "悬浮描述"`。
- 仅中文，中国风味措辞；描述写清数值与时机（tooltip 是永久状态的解释渠道）。

## 4. 状态图标（image-gen skill，**Gemini 后端**）

图标是小尺寸徽章，与卡牌插画（水彩卡面）风格不同，固定用 `--gemini --no-style`：

```bash
# 1. 生成（Gemini 输出 1:1 约 1K）
python utils/image_gen/image_gen.py --gemini --no-style "<图标prompt>" <图标名> assets/images/icon/status/permanent

# 2. 缩放到 150×150（需 Pillow，缺则 pip install pillow）
python -c "from PIL import Image; Image.open('assets/images/icon/status/permanent/<图标名>.png').resize((150,150), Image.LANCZOS).save('assets/images/icon/status/permanent/<图标名>.png')"
```

- `--no-style` 必须：`utils/image_gen/prompt.md` 的水彩卡面风格语句不适用于图标。
- 图标 prompt 建议要素（参考现有永久图标 `persistent.png` / `increase_damage_firebend.png`）：
  居中徽记构图、圆角方形徽章、深色描边、单一象征物（如阴阳鱼、五行环、星盘）、
  扁平手绘游戏图标风、**无文字**。
- 图标名与状态 id 对应；生成后用 ReadMediaFile 检查 **150×150 下是否一眼可辨**（细节过多就重新生成更简洁的构图）。
- 状态图标**不要**注册进 `kBattleCardIllustrations`（那是卡牌插画池，记忆翻牌小游戏使用）。
- 注意区分：天赋树节点图标（`cultivation/skill/*_selected.png`）是另一套资源，与战斗状态图标无关。

## 5. 被动绑定（passives.json5）

- 被动词条加 `battleStatus: "<状态id>"` 字段；战斗开始由 Dart 统一授予对应永久状态
  （机制见 `plan/battle_script_migration.md` 阶段 1.1；未落地前按当时约定处理）。
- 天赋树节点（`passive_skills.json5` 的 track 节点）引用被动 id 的部分不变。
- 被动的 `description` 本地化键（`passive.json`）与状态描述分开维护：前者面向天赋树 UI，后者面向战斗 tooltip。

## 6. 参数/属性型效果：stats 管线完整链路

参数型/纯属性效果需要新增 stat 时，同步以下五处（样板：`battleEnergyBonus` 每回合元气）：

1. **词条定义** `assets/data/passives.json5`：词条 id 即 stat id（同名约定，如 `battleEnergyBonus`），`description` 键供装备/天赋界面显示词条效果。
2. **词条本地化** `assets/locale/zh/rpg/passive.json`：`passive_{id}_description`，数值占位 `{0}`。
3. **stats 聚合** `scripts/main/data/character/battle_entity.ht` 的 `characterCalculateStats()`：加一行聚合。纯加成：
   `character.stats.{id} = character.passives.{id}?.value + character.ephemeralPassives.{id}?.value`；
   有基底/上限的用定制公式（参照 `critThreshold` 的 clamp、`elementalResist` 折算进单抗）。
   仅限装备的词条注意 ephemeral 临时增益池的注释约定（battle_entity.ht:351）。
4. **属性面板** `lib/widgets/character/stats.dart`：id 注册进 `kStats` / `kMoreStats` 列表。
   格式化由 **id 后缀约定**驱动（`Attack`→%、`Resist`→%+上限、`Threshold`→低值高亮、
   `Cost`/`Reduce`→低值为优、默认→高值为优黄色高亮）——命名时选好后缀可零改格式化代码；
   有特殊显示需求才在 `_buildStatsLabel` 加特判分支。
5. **属性本地化** `assets/locale/zh/rpg/character.json`：`{id}` 名称 + `{id}_description` 悬浮描述。

战斗内消费点（Dart 机制）读 `character.data['stats']['{id}']`（如观星深度、资源保留等参数）。

## 7. 验证（必做）

- 脚本改动：`python build.py` 重新编译 `.mod`（hetu PATH 问题时用 dart install 绝对路径的 hetu.bat）。
- Dart 改动：`flutter analyze`。

## 8. 自查清单

- [ ] 先过第 0 节分流：只有反复触发的行为型效果才建状态。
- [ ] 状态型五层同步：状态数据 / 状态脚本 / 本地化 / 图标 / 被动绑定。
- [ ] 参数/属性型五处同步（第 6 节）：passives.json5 / passive.json / characterCalculateStats / stats.dart / character.json。
- [ ] 状态脚本无 `async`、未调用返回 Future 的 API；伤害走 `changeLife`。
- [ ] 数值写在状态数据自定义字段，脚本只读不写死。
- [ ] 敌我对称场景已考虑（NPC 持有同样生效）。
- [ ] 图标在 `icon/status/permanent/`、150×150、小尺寸可辨、无文字、未注册 kBattleCardIllustrations。
- [ ] `python build.py` 编译通过；改动 Dart 则 `flutter analyze` 通过。
