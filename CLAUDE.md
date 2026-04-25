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
- `passives.json5` / `passive_tree.json5` — 天赋树
- `status_effect.json5` — 状态效果
- `quests.json5` / `journals.json5` — 任务和日志

### Hetu 脚本

游戏中的大部分数据以 HTStruct 的形式定义在 Hetu 脚本中。同时可以在脚本和Dart两侧进行类似的操作。

HTStruct 类似 Javascript 中的 object ，可以在运行时动态增删属性。适合游戏中经常变化的对象，如角色、物品、事件等。

在脚本中，使用 object.property 的方式访问属性，如 `hero.level`、`item.name`。
在 Dart 中，使用类似 Map 对象的方式访问属性，如 `hero['level']`、`item['name']`。

脚本入口: `scripts/main/main.ht`。编译后输出到 `assets/mods/main.mod`。

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

- `dialog::*` — 对话框操作（`pushDialog`、`pushSelection`、`pushBackground` 等）
- `Game::*` — 游戏逻辑（`updateGame`、`showBattle`、`showMerchant`、`promptJournal` 等）
- `debug::*` — 调试功能（`reloadGameData`）

**外部类绑定**：

- `lib/data/common.dart` — Dart 常量
- `lib/data/constants.dart` — 将 Dart 常量导出到 Hetu
- `scripts/main/binding/constants.ht` — Hetu 侧声明常量结构

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

### 游戏数据（JSON5）

- 所有数据文件为顶层对象，以实体 ID 为键
- ID 使用 `snake_case`
- 通用字段: `id`（必须与键名一致）、`description`（本地化键）、`rarity`
- 稀有度取值: `common` / `rare` / `epic` / `legendary` / `mythic` / `arcane`

## 开发路线参考

项目根目录下有几个开发计划文件，可作为功能背景的参考：

- `TODO.md` — 待实现功能
- `NEXT.md` — 开发路线图
- `KNOWN_ISSUES.md` — 已知BUG清单
