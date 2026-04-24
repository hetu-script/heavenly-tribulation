# 天道奇劫 (Heavenly Tribulation) — Agent 项目指南

> 本文档面向 AI 编程助手。阅读本文档前，请假设你对本项目一无所知。

---

## 1. 项目概述

**天道奇劫** 是一款仙侠题材的 RPG 游戏，融合了 Roguelike、卡牌战斗、经营建设和大地图探索玩法。设计灵感来源于《太阁立志传》《弈仙牌》《Battle Brothers》《Slay the Spire》等作品。

- **项目类型**: 桌面端 Flutter 游戏（Windows 为主，理论支持 Linux/macOS）
- **目标平台**: 桌面平台（固定窗口 1440×810，不可调整大小）
- **当前版本**: `0.1.0-demo`
- **开源协议**: 源代码基于 MIT License；美术、音频等非代码资产版权归 Hetu Studio 所有，**不可**自由使用

---

## 2. 技术栈

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

- `hetu_script` / `hetu_script_flutter`
- `samsara`
- `fluent_ui`
- `data_table_2`

---

## 3. 项目结构

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

---

## 4. 构建和运行命令

### 开发运行

```bash
flutter run -d windows
```

### 编译 Hetu 脚本并构建 Windows release

```bash
python build.py
```

`build.py` 的行为：

1. 遍历 `scripts/` 下的目录（排除 `_tests`）
2. 使用 `hetu compile` CLI 将每个目录的 `main.ht` 编译为 `assets/mods/{dir_name}.mod`
3. 调用 `flutter build windows`

### VS Code 任务

项目配置了 `.vscode/tasks.json`，任务名 `compileAllGameScripts` 等同于运行 `python build.py`。

### 调试配置

`.vscode/launch.json` 中配置了名为 `"game"` 的 Dart 启动项，目标为 `lib/main.dart`，平台 Windows。

---

## 5. 代码风格规范

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

---

## 6. 架构概述

### 6.1 全局单例

定义在 `lib/global.dart`：

- `engine: SamsaraEngine` — 核心引擎（渲染、脚本、场景栈、资源管理）
- `dialog: GameDialog` — 对话框系统（任务队列、图片层、背景层、选择支）
- `gameState: GameState` — 全局 UI 状态（英雄、时间、日志、NPC、位置等）
- `gameConfig: GameConfigState` — 游戏配置（音量、开发者模式、LLM 设置、模组开关）

### 6.2 场景系统

- 场景继承自 Samsara 的 `Scene` 类，**不是** Flutter 的 Navigator 路由
- 场景 ID 定义在 `lib/scene/common.dart`（`Scenes` 类）
- 场景构造函数在 `lib/app.dart` 中通过 `engine.registerSceneConstructor()` 注册
- 切换场景通过 `engine.pushScene()` / `engine.popScene()` / `engine.switchScene()` 实现
- `GameApp.build()` 监听 `SamsaraEngine.scene` 变化，将当前场景渲染到 `Stack` 中

主要场景：

- `mainmenu` — 主菜单
- `worldmap` — 六边形大地图
- `battle` — 回合制卡牌战斗
- `location` — 地点/据点交互
- `cultivation` — 修炼/突破
- `library` — 卡组构建/卡牌库
- `matchingGame` / `differenceGame` / `mouseMazeGame` / `memoryCardGame` / `nanogramGame` — 小游戏

### 6.3 逻辑分层

| 层级        | 位置                   | 说明                                                                              |
| ----------- | ---------------------- | --------------------------------------------------------------------------------- |
| 渲染 + 桥接 | `lib/`                 | Dart 负责 Flutter UI、Flame 渲染、存档读写、场景管理、性能敏感算法（如 A\* 寻路） |
| 静态逻辑    | `lib/logic/logic.dart` | `GameLogic` 静态方法：时间计算、地图生成、价格估算、角色属性公式等                |
| 动态逻辑    | `scripts/main/`        | Hetu 脚本，运行时加载。包含角色系统、物品系统、战斗逻辑、世界生成、事件回调等     |
| 数据定义    | `assets/data/*.json5`  | 卡牌、物品、天赋、地图、任务等纯数据                                              |

### 6.4 Dart ↔ Hetu 互操作

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

- `Constants`（`lib/data/constants.dart`）— 将 Dart 常量暴露给 Hetu
- `BattleCharacterClassBinding` — 战斗角色方法绑定

### 6.5 状态管理（Provider）

`lib/main.dart` 中通过 `MultiProvider` 全局注入：

- `GameState` — 主状态（英雄、时间戳、活跃日志、事件、NPC、当前位置）
- `WorldMapState` — 大地图编辑/选择状态
- `ViewPanelState` / `ViewPanelPositionState` — 悬浮面板（角色面板、工坊、炼丹炉等）
- `ItemSelectState`、`EnemyState`、`MerchantState`、`MeetingState` — 对话框/模态状态
- `HoverContentState` — 鼠标悬浮提示内容

### 6.6 数据驱动

- 启动时 `GameData.init()` 加载所有 `assets/data/*.json5` 到静态内存映射
- 卡牌、物品、天赋、状态效果、任务、地图等均通过 JSON5 定义
- 脚本侧数据以 `HTStruct`（类似 JavaScript Object 的动态结构）存储，Dart 侧以 `Map` 访问

---

## 7. 数据与资产

### 7.1 游戏数据文件（`assets/data/`）

| 文件                                     | 内容                           |
| ---------------------------------------- | ------------------------------ |
| `cards.json5`                            | 战斗卡牌原型（~2000 行）       |
| `card_affixes.json5`                     | 卡牌词条/修饰符                |
| `items.json5`                            | 物品原型（消耗品、装备、材料） |
| `craftables.json5`                       | 制造配方                       |
| `passives.json5` / `passive_tree.json5`  | 天赋数据和天赋树布局           |
| `status_effect.json5`                    | 状态效果定义                   |
| `maps.json5` / `map_components.json5`    | 地图定义和地图组件             |
| `tiles.json5`                            | 地块类型定义                   |
| `quests.json5` / `journals.json5`        | 任务和日志定义                 |
| `animation.json5` / `sprite_sheet.json5` | 动画和精灵图表                 |
| `techs.json5`                            | 科技/研究数据                  |

### 7.2 本地化（`assets/locale/zh/`）

- 当前仅支持中文（`zh`）
- 按功能域分组：`general.json`、`rpg/*.json`、`tycoon/*.json`、`ui/*.json`、`minigame/*.json`
- 游戏内通过 `engine.locale('key')` 获取字符串
- 剧情模组另有独立的本地化文件在 `scripts/story/l10n/zh/`

### 7.3 美术与音频资产授权

**非常重要**：

- 源代码：MIT License，可自由使用、修改、分发
- 美术、音频、字体等非代码资产：**不属于 MIT 授权范围**
- 部分资产来自免费公共库，部分为自购，部分由 AI 创作
- **禁止**在任何其他项目中直接复制、修改或分发这些资产文件
- 如需 fork 本项目进行二次开发，**必须替换所有非代码资产**

---

## 8. 脚本系统（Hetu Script）

### 8.1 核心模组（`scripts/main/`）

- `main.ht` — 模组入口，定义 `meta`、`init()`、`main()`
- `binding/` — Dart↔Hetu 桥接声明（`dialog.ht`、`game.ht`、`player.ht`、`world.ht`、`constants.ht`）
- `data/` — 运行时数据结构（角色、物品、地点、门派、任务、日志等）
- `cardgame/` — 卡牌战斗系统逻辑
- `event/` — 世界事件回调（沙盒世界、副本、修炼试炼等）
- `logic/` — 游戏更新循环和通用逻辑
- `world/` — 世界生成、地图算法、副本生成
- `name/` — 程序化名称生成（角色、地点、技能、物品等）

### 8.2 剧情模组（`scripts/story/`）

- 独立的第二个模组，有自己的 `main.ht` 和本地化
- 包含剧情事件、额外数据（`items.json5`、`journals.json5`、`passives.json5`）
- 通过 `engine.config.mods` 启用/禁用

### 8.3 模组加载机制

- **Debug 模式**: 直接从 `assets/mods/` 加载 `.ht` 源文件（支持热重载调试）
- **Release 模式**: 加载编译后的 `.mod` 字节码文件
- 主模组固定为 `main`，其他模组在 `gameConfig` 中配置开关

---

## 9. 测试

本项目**没有**传统的 Dart 单元测试目录（`test/` 不存在）。

现有的测试相关文件：

- `scripts/_tests/attributes.hts` — 属性生成逻辑测试
- `scripts/_tests/exp.hts` — 升级经验公式验证
- `scripts/_tests/gradual.hts` — 渐变插值函数测试

这些文件是 Hetu 脚本形式的独立测试，可直接在 Hetu 解释器中运行。

**目前测试策略以手动游戏测试为主**，尚未建立自动化测试体系。

---

## 10. 安全与注意事项

1. **资产授权**：严禁将本项目中的美术、音频、字体资产用于其他项目。修改代码时也要注意不要意外将这些资产打包到公共发布中。
2. **窗口管理**：游戏在桌面端运行，`lib/main.dart` 中通过 `window_manager` 固定窗口尺寸并禁用最大化/调整大小。修改窗口逻辑时需测试多平台兼容性。
3. **错误处理**：`main.dart` 中注册了 `PlatformDispatcher.onError` 和 `FlutterError.onError`，将未捕获异常路由到引擎日志 + 弹窗。修改错误处理逻辑时需确保调试信息不会泄露敏感路径。
4. **LLM 集成**：引擎支持 LLM 聊天功能（`engine.config.enableLlm`），涉及 `lib/data/prompt.dart` 中的系统提示词模板。修改相关配置时注意提示词注入风险。
5. **脚本注入**：Hetu 脚本在运行时加载，调试模式下直接从资产读取。发布版本应确保只加载预编译的 `.mod` 文件，避免执行未经验证的脚本源。

---

## 11. 开发路线参考

项目根目录下有几个开发计划文件，可作为功能背景的参考：

- `TODO.md` — 0.2.0 版本详细计划（大地图策略、门派管理、竞技场等）
- `NEXT.md` — 高阶开发路线图（分 4 个阶段：建筑场景 → 经营策略 → 门派关系 → 剧情内容）
- `KNOWN_ISSUES.md` — 已知问题清单
- `CHANGELOG.md` — 版本变更记录

---

## 12. 关键外部依赖路径

由于以下依赖为本地路径依赖，**确保这些仓库在同级目录中可用**：

- `../hetu-script/packages/hetu_script`
- `../hetu-script/packages/hetu_script_flutter`
- `../samsara-engine`
- `../fluent_ui`
- `../data_table_2`

若路径缺失，项目无法编译。
