## Plan: 哨所 → 镇魔司 重命名 + 悬赏玩法重设计

将"哨所"(`militarypost`) 彻底重命名为"镇魔司"(`justicehall`)，NPC 从 `militaryAdvisor` 改为 `warden`。同时更新文档中的功能描述为悬赏/暗杀主题。本次只做重命名+文档设计，交互逻辑实现留到后续。

### 重命名映射

| 旧值                        | 新值                       |
| --------------------------- | -------------------------- |
| `militarypost`              | `justicehall`              |
| `kLocationKindMilitaryPost` | `kLocationKindJusticeHall` |
| `militaryAdvisor`           | `warden`                   |
| 哨所                        | 镇魔司                     |
| 军师                        | 司正                       |

---

### Phase 1: 代码与数据重命名（7 个文件，可并行）

1. **Dart 常量** — 在 [lib/data/common.dart](lib/data/common.dart) 中 7 处替换：`kSiteKindsBuildable`、`kSiteKindToNpcId`、`kSiteKindsManagable`、`kSectCategoryToSiteKind`、`kSitePriority`、`kSiteRentMoneyCostByDay` 等集合中的 `'militarypost'` → `'justicehall'`，`'militaryAdvisor'` → `'warden'`

2. **Hetu 常量** — 在 [scripts/main/data/location/location.ht](scripts/main/data/location/location.ht) Line 27-28：注释改为"权霸：镇魔司"，常量改为 `kLocationKindJusticeHall = 'justicehall'`

3. **本地化** — 在 [assets/locale/zh/tycoon/location.json](assets/locale/zh/tycoon/location.json)：`"militarypost": "哨所"` → `"justicehall": "镇魔司"`

4. **本地化** — 在 [assets/locale/zh/rpg/dungeon.json](assets/locale/zh/rpg/dungeon.json)：`"militaryAdvisor": "军师"` → `"warden": "司正"`

5. **图片重命名** — `assets/images/location/site/militarypost.png` → `justicehall.png`，`assets/images/location/card/militarypost.png` → `justicehall.png`

### Phase 2: 文档更新（2 个文件）

6. **建筑文档** — 在 [docs/docs/how2play/tycoon/site/readme.md](docs/docs/how2play/tycoon/site/readme.md)：
   - `## 权霸 - military post - 哨所` → `## 权霸 - justice hall - 镇魔司`
   - 功能描述改为：悬赏目标列表（接取→追踪→击败→领赏），升级后可发布悬赏和暗杀任务
   - 租金表中 `哨所 | militarypost` → `镇魔司 | justicehall`

7. **任务文档** — 在 [docs/docs/how2play/rpg/quest/readme.md](docs/docs/how2play/rpg/quest/readme.md) Line 119：`·哨所：获取其他势力的某个建筑的情报，守卫某个建筑` → `·镇魔司：接取悬赏任务，暗杀指定角色`

### Phase 3: 清理

8. **删除** `plan-militaryPost.prompt.md`

---

### 与现有"悬赏任务"的分工

游戏中已有会堂悬赏任务系统（运送、护送、采购等通用任务）。镇魔司的定位区别：

|              | 会堂悬赏               | 镇魔司           |
| ------------ | ---------------------- | ---------------- |
| **任务类型** | 运送、护送、采购、探索 | 猎杀、暗杀、捉拿 |
| **核心玩法** | 跑腿 + 购物            | 战斗 + 追踪      |
| **目标**     | 物品/材料/地点         | 特定NPC角色      |
| **权霸关联** | 无                     | 权霸门派特色建筑 |

### 镇魔司功能大纲（供后续实现参考）

- **接取悬赏**：每月刷新 3-5 个悬赏目标 NPC，显示名字、境界、所在城市、赏金。找到并击败后回来领赏
- **发布悬赏**：选择已遭遇角色，支付赏金，异步等待刺客执行（成功/失败概率）
- **暗杀任务**（升级后解锁）：针对敌对门派高层的高价值目标，赏金更高、目标更强

### Verification

1. 全局搜索 `militarypost`（不区分大小写）确认零匹配
2. 全局搜索 `militaryAdvisor` 确认零匹配
3. `python build.py` 编译通过
4. 运行游戏进入有镇魔司的城市，确认名称和图片正常

### Decisions

- 本次只做重命名 + 文档，不实现交互逻辑
- 图片暂用旧图改名，美术后续更新
- 与会堂悬赏系统互不冲突（会堂=通用跑腿，镇魔司=战斗猎杀）
