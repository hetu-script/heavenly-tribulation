# Important

## About Dart

Remember: In mordern Dart, non-empty case clauses jump to the end of the switch after completion. They do not require a break statement.

## About Plan

All plan files save to the plan/ directory in the project, for user's review purpose.

## About Validate

Use `python build.py` to validate the script.
Use `flutter anylyze` to validate the dart.
No need for actual build.

This project is still in progress, so no need to consider save/data/api backward compatibility.

## About Code

这是一个中国风游戏项目，但我们要尽量避免在代码和数据中使用拼音。使用对应的英文含义代替作为命名。本地化字符串是中国风味即可。唯一的例外是具体的资源的文件名可以是拼音，例如图片资源的名字。

# 项目: 天道奇劫 (Heavenly Tribulation)

**天道奇劫** 是一款仙侠题材的 RPG 游戏，融合了 Roguelike、卡牌战斗、经营建设和大地图探索玩法。设计灵感来源于《太阁立志传》《弈仙牌》《Battle Brothers》《Slay the Spire》等作品。

- **项目类型**: 桌面端 Flutter 游戏（Windows 为主，理论支持 Linux/macOS）
- **目标平台**: 桌面平台（固定窗口 1440×810，不可调整大小）

设计文档见 `docs/` 目录。

## 技术栈

| 层级     | 技术 / 包                            | 说明                                                            |
| -------- | ------------------------------------ | --------------------------------------------------------------- |
| 框架     | Flutter 3.27+ / Dart 3.6+            | UI 框架                                                         |
| 游戏渲染 | Flame 1.32+                          | 2D 游戏引擎底层                                                 |
| 自研引擎 | Samsara Engine (`../samsara-engine`) | 基于 Flame 的自定义游戏引擎，提供场景、对话框、卡牌、地图等系统 |
| 脚本语言 | Hetu Script (`../hetu-script`)       | 轻量级脚本语言，语法类似 Dart/JavaScript，驱动大部分游戏逻辑    |
| UI 组件  | Material + Fluent UI (本地 fork)     | 混合使用 Material 和 Fluent Design                              |
| 状态管理 | Provider + ChangeNotifier            | 标准 Flutter 状态管理                                           |
| 数据格式 | JSON5                                | 游戏配置和本地化文件均使用 JSON5（支持注释、无引号键）          |
| 构建脚本 | Python (`build.py`)                  | 编译 Hetu 脚本并调用 Flutter 构建                               |

**关键本地依赖**（路径依赖，非 pub.dev）：

以下依赖为本地路径依赖，如果必要，也可以查看或修改这些库中的代码

- `../hetu-script/packages/hetu_script`
- `../hetu-script/packages/hetu_script_flutter`
- `../samsara-engine`
- `../fluent_ui`
- `../data_table_2`

## 构建和运行

使用 VSCode的 tasks: compileAllGameScripts 任务会编译 Hetu 脚本并输出到 `assets/mods/` 目录，并编译Flutter工程，生成Windows可执行文件。

## 架构

```
heavenly-tribulation/
├── lib/                    # Dart 源代码
│   ├── data/               # 静态常量、数据加载、JSON5 数据解析
│   ├── logic/              # 游戏核心逻辑（Dart 侧）
│   ├── scene/              # 游戏场景（Samsara Scene 子类）
│   ├── state/              # Provider 状态管理（ChangeNotifier）
│   ├── widgets/            # 可复用 UI 组件和对话框
│   ├── app.dart            # 应用根组件：引擎初始化、场景注册、Hetu 绑定
│   ├── main.dart           # 入口：窗口管理、Provider 树、错误处理
│   ├── global.dart         # 全局单例（engine, dialog, gameState, gameConfig）
│   ├── ui.dart             # UI 常量、主题、响应式布局计算
│   ├── extensions.dart     # GameDialog 扩展方法
│   └── ...
├── scripts/                # Hetu 脚本（游戏逻辑主体）
│   ├── main/               # 核心模组（战斗、角色、世界生成、事件等）
│   ├── story/              # 剧情模组
│   └── _tests/             # Hetu 脚本测试/工具脚本
├── assets/                 # 游戏资源
│   ├── data/               # JSON5 游戏数据（卡牌、物品、地图、天赋等）
│   ├── locale/zh/          # 中文本地化 JSON 文件
│   ├── images/             # 美术资源
│   ├── audio/              # 音乐和音效
│   ├── mods/               # 编译后的模组（`.mod` 字节码）
│   └── fonts/              # 字体文件
├── docs/                   # 游戏内百科/设计文档（Markdown）
├── windows/                # Flutter Windows 平台工程
├── .github/                # Copilot 指令和数据规范文档
├── build.py                # 构建脚本
├── pubspec.yaml            # Dart 依赖配置
└── analysis_options.yaml   # Dart 静态分析配置
```

### 场景系统

场景继承 Samsara 的 `Scene`。

场景 ID 定义在 `lib/scene/common.dart`（Scenes 类）。

场景的构造函数在 `lib/app.dart` 通过 `engine.registerSceneConstructor()` 注册。

进入和离开场景通过engine的 `pushScene()` 和 `popScene()` 实现。

- `lib/scene/mainmenu/` — 主菜单
- `lib/scene/world/` — 六边形大地图
- `lib/scene/location/` — 据点/场景
- `lib/scene/battle/` — 卡牌战斗
- `lib/scene/cultivation/` — 修炼
- `lib/scene/card_library/` — 卡组构建/卡牌库
- `lib/scene/mini_game/` — 小游戏

### 逻辑分层

1. 固定逻辑
   `lib/logic/logic.dart`
   `GameLogic` 的 static 函数（时间计算、地图生成等），通过 `part` 拆分为 `character.dart`、`location.dart`、`sect.dart`
2. 动态逻辑
   `scripts/main/`
   Hetu 脚本，运行时加载，通过 `engine.hetu.invoke()` 调用 |
3. 数据获取
   通过 `engine.hetu.fetch('key')` 从脚本侧获取数据 |

### 状态管理

`lib/state/` 下的 `ChangeNotifier` 类，通过 Provider 注入:

- `GameState` — 主状态（英雄、时间戳、日志、NPC、地形）
- `WorldMapState`、`CharacterState`、`MeetingState` 等

### 本地化字符串

游戏中通过 `engine.locale('key')` 获取。

字符串定义在 `assets/locales/` 目录下的 JSON 文件中。多语言放在不同目录（如 `en`、`zh`）。但目前仅支持中文。键名通常与数据 ID 对应，如 `punch_attack`、`item_name` 等。

### 常量

游戏中的常量，定义在`lib/data/common.dart`中，在Dart侧可以直接使用。

同时，其中大部分常量，还利用 hetu script 的 HTExternalClass 功能，定义在`lib/data/constants.dart`、以及`scripts/main/binding/constants.ht`中，从而同步导出到脚本侧，供 Hetu 脚本使用。

在脚本中，使用形如 `Constants.baseLife` 的方式访问。

### 数据

- `assets/data/*.json5` — JSON5 格式的游戏数据:
- `cards.json5` / `card_affixes.json5` — 卡牌和词条
- `items.json5` — 物品
- `maps.json5` — 地图定义（六边形地块）
- `passives.json5` / `passive_skills.json5` — 天赋树
- `status_effect.json5` — 状态效果
- `quests.json5` / `journals.json5` — 任务和日志

### Hetu 脚本

游戏中的大部分数据以 HTStruct 的形式定义在 Hetu 脚本中。同时可以在脚本和Dart两侧进行类似的操作。

HTStruct 类似 Javascript 中的 object ，可以在运行时动态增删属性。适合游戏中经常变化的对象，如角色、物品、事件等。

在脚本中，使用 object.property 的方式访问属性，如 `hero.level`、`item.name`。
在 Dart 中，使用类似 Map 对象的方式访问属性，如 `hero['level']`、`item['name']`。

脚本入口: `scripts/main/main.ht`。编译后输出到 `assets/mods/main.mod`。

**重要**: 脚本中的数据对象的类型是 `HTStruct`，在Dart侧，目前的项目中大部分时间使用 dynamic 类型来处理，并且可以像Map那样用 `[]` 来访问属性。

- `scripts/main/binding/` — Dart↔Hetu 桥接
- `scripts/main/data/` — 数据定义（稀有度、常量、角色/物品/地点/门派）
- `scripts/main/cardgame/` — 卡牌战斗逻辑
- `scripts/main/event/` — 事件回调（sandbox、dungeon、cultivation 等）
- `scripts/main/world/` — 世界生成和地图算法
- `scripts/main/quest/` — 任务系统
- `scripts/main/data/character/` — 角色对象（英雄、NPC、敌人）
- `scripts/main/data/item/` — 物品对象
- `scripts/main/data/location/` — 场景、建筑对象
- `scripts/main/data/sect/` — 门派对象

### Dart ↔ Hetu 互操作

**Dart 调用脚本**：

```dart
engine.hetu.invoke('functionName', positionalArgs: [...], namedArgs: {...});
```

**脚本调用 Dart**：
在 `lib/app.dart` 中通过 `bindExternalFunction` 注册外部函数，命名空间包括：

- `debug*` — 调试功能（`reloadGameData`）
- `dialog*` — 对话框操作（`pushDialog`、`pushSelection`、`pushBackground` 等）
- `Game*` — 游戏逻辑（`updateGame`、`showBattle`、`showMerchant`、`promptJournal` 等）

**外部类绑定**：

- `lib/data/common.dart` — Dart 常量
- `lib/data/constants.dart` — 将 Dart 常量导出到 Hetu
- `scripts/main/binding/constants.ht` — Hetu 侧声明常量结构

### 战斗内容分层（卡牌 / 天赋 / 装备）

- **Dart = 机制层**：回合骨架与阶段顺序、费用模型与支付、回调分发总线、卡牌过滤引擎、交互 UI（观星/抉择）、动画、卡牌生命周期。Dart 代码中不应出现具体内容 id（卡牌/装备/天赋）；新增机制必须参数化、由数据字段驱动。
- **Hetu = 内容层**：一切"在时机 X 用数值 Y 做 Z"的行为，通过 BattleCharacter 外部类 API（`scripts/main/cardgame/battle_character.ht`）组合实现。
- **JSON5 = 绑定与参数**：内容 id → 脚本函数 + 数值/过滤条件/阈值。

天赋与装备的战斗互动统一走**状态回调总线**（`handleStatusEffectCallback`）；不要做装备版逐词条回调扫描——装备在战斗中无活实例（战前已折算进 stats/passives），永久状态就是装备级持久效果的载体：

- 行为型效果（战斗中反复触发）→ 被动携带 `battleStatus` 字段，战斗开始授予永久状态，行为在 `status_script.ht` 实现；状态数据可携带自定义参数字段（如 `damageType`、`damagePerCard`）。其他通用机制字段：`deckCostReduction`（组牌费用）、`shuffleIntoDeck`（洗入牌库）、`turnStartScry`（回合开始观星）、`energyRetain`（资源保留），契约见 `docs/docs/mod/battle/readme.md`。
- 参数型效果（观星深度、费用修正、资源保留等）与纯属性/单值修改（攻防、抗性、伤害增加等）→ 非状态，由 Dart 机制读取 stats/被动字段；纯属性走 stats 聚合管线（`kStatsToPermanentEffects` 图标仅展示净值，无回调）。
- 状态脚本必须**非阻塞、不可交互**（不调用返回 Future 的 API）；交互式效果走卡牌词条的 async 路径。
- 永久状态默认可见：图标 + tooltip 是效果解释渠道。

## 代码风格

### Dart 代码

- 使用 `package:flutter_lints/flutter.yaml` 作为基础规则
- **忽略的规则**: `constant_identifier_names`、`use_build_context_synchronously`、`avoid_print`、`avoid_renaming_method_parameters`
- 常量命名: 使用 `k` 前缀，如 `kTicksPerTime`、`kMaxHeroAge`
- 注释使用**中文**
- 跨语言互操作（与 Hetu 交互）时常用 `dynamic` 类型
- `lib/logic/logic.dart` 使用 `part` 拆分文件（`character.dart`、`location.dart`、`sect.dart`）

### Hetu 脚本

- 常量: `kCamelCase`（如 `kMaxValue`）
- 私有常量: `_kCamelCase`
- 函数: `camelCase`
- 命名空间 / 结构体: `PascalCase`
- 注释使用**中文**
- 事件回调函数通常为 `async`
- 修改脚本后必须重新运行 `python build.py` 生成 `.mod` 文件

（`python build.py` 在 Windows 下对 hetu 的调用可能有 PATH 问题，如果失败可以调用系统环境变量中dart install的绝对路径的hetu.bat。）

### 游戏数据（JSON5）

- 所有数据文件为顶层对象，以实体 ID 为键
- ID 使用 `snake_case`
- 通用字段: `id`（必须与键名一致）、`description`（本地化键）、`rarity`
- 稀有度取值: `common` / `rare` / `epic` / `legendary` / `mythic` / `arcane`

## 设计笔记（DESIGN NOTE）

### 绝世设计总原则

> 适用于全部流派的绝世卡牌与绝世装备。

1. **正反双段式**：每个绝世 = 强正面 + 限制/代价。目标是"对特定构筑是核心/毕业装，对其他构筑则会有额外限制"，避免全民通用的纯强度装备。
2. **卡牌负面可尖锐，装备走限制/权衡**：牌库中的卡抽到时才兑现，负面是偶发的，可以做重；装备常驻生效被持续感知，且栏位本身已是隐性机会成本，不宜再叠数值惩罚。
3. **负面类型优先级**：方向性限制（流派软锁、机制互斥）> 对称效果（双方受益/受害，构筑使其不对称）> 自伤/自异常（可被构筑转化为资源）> 纯数值惩罚（避免）。
4. **流派锁可以是软限制**（非本流派牌费用 +X），增加宽容度，允许多流派玩法。


## 开发路线参考

项目根目录下有几个开发计划文件，可作为功能背景的参考：

- `TODO.md` — 待实现功能
- `NEXT.md` — 开发路线图
- `KNOWN_ISSUES.md` — 已知BUG清单
- `DESIGN_NOTE.md` - 注意事项
