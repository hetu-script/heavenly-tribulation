# 项目：天道奇劫 (Heavenly Tribulation)

仙侠题材 RPG，融合 Roguelike + 卡牌战斗 + 经营建设 + 大地图探索。
设计文档见 `docs/` 目录。

## 技术栈

- Flutter 3.27+ / Dart 3.6+ / Flame 1.32+
- 自研引擎 Samsara Engine（本地路径 `../samsara-engine`，基于 Flame）
- 脚本系统 Hetu Script（本地路径 `../hetu-script`）
- UI：Material + Fluent UI（本地 fork）
- 状态管理：Provider + ChangeNotifier（见 `lib/state/`）

## 构建和运行

```shell
# 编译 Hetu 脚本（scripts/ → assets/mods/*.mod
python build.py

# 运行
flutter run -d windows
```

无自动化测试。无 CI/CD。

## 架构

### 全局单例（lib/global.dart）

```dart
final engine = SamsaraEngine();     // 核心引擎
final dialog = GameDialog();        // 对话系统
final gameState = GameState();      // 全局状态（ChangeNotifier）
```

### 场景系统

场景继承 Samsara 的 `Scene`，通过 `engine.registerSceneConstructor()` 注册，在 `lib/app.dart` 初始化。场景 ID 定义在 `lib/scene/common.dart`（Scenes 类）。

- `lib/scene/battle/` — 卡牌战斗
- `lib/scene/world/` — 六边形大地图
- `lib/scene/cultivation/` — 修炼
- `lib/scene/location/` — 据点/地点
- `lib/scene/sect/` — 门派
- `lib/scene/mainmenu/` — 主菜单
- `lib/scene/mini_game/` — 小游戏（消除、2048 等）

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

`lib/state/` 下的 `ChangeNotifier` 类，通过 Provider 注入：

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

- `assets/data/*.json5` — JSON5 格式的游戏数据：
- `cards.json5` / `card_affixes.json5` — 卡牌和词条
- `items.json5` — 物品
- `maps.json5` — 地图定义（六边形地块）
- `passives.json5` / `passive_tree.json5` — 天赋树
- `status_effect.json5` — 状态效果
- `quests.json5` / `journals.json5` — 任务和日志

### Hetu 脚本

入口：`scripts/main/main.ht`。编译后输出到 `assets/mods/main.mod`。

- `scripts/main/binding/` — Dart↔Hetu 桥接
- `scripts/main/data/` — 数据定义（稀有度、常量、角色/物品/地点/门派）
- `scripts/main/cardgame/` — 卡牌战斗逻辑
- `scripts/main/event/` — 事件回调（sandbox、dungeon、cultivation 等）
- `scripts/main/world/` — 世界生成和地图算法

## 代码风格

- `analysis_options.yaml` 继承 `flutter_lints/flutter.yaml`
- 允许 `constant_identifier_names`（常量使用 `kMaxHeroAge` 风格）
- 允许 `avoid_print`（调试用）
- 使用 `final class` 防止继承
- 本地化字符串：`engine.locale('key')`
- Hetu 互操作时常用 `dynamic` 类型
- 注释使用中文
