---
applyTo: "scripts/**/*.ht"
description: "Use when editing Hetu Script (.ht) files. Covers syntax, Dart↔Hetu interop, naming conventions, and common patterns."
---

# Hetu Script 编写规范

## 语法要点

- 模块系统: `import 'path.ht'`、`import 'path.ht' as alias`、`export 'path.ht'`、`export { symbol } from 'path.ht'`
- 变量: `const`（不可变）、`final`（不可重赋值）、`let`（可变）
- 函数: `function name(args) { }`，异步用 `async function`，返回类型可选 `-> type`
- 数据结构: `struct Name { constructor({ ... }) { } }`
- 空安全: `??`（空合并）、`?.`（可选链）

## 命名约定

```hetu
const kMaxValue = 100           // 常量: kCamelCase
const _kPrivateConst = 'x'     // 私有常量: _kCamelCase
function doSomething() { }      // 函数: camelCase
namespace Player { }            // 命名空间: PascalCase
struct BattleCard { }           // 结构体: PascalCase
```

## Dart↔Hetu 桥接

```hetu
// 外部函数声明（Dart 侧实现）
namespace Game {
  external function datetime()
  external async function promptJournal(journal, { selections })
}

// 全局预绑定对象（直接使用，不需要导入）
// game, universe, world, history, hero, dialog, random
```

## 常用模式

```hetu
// 对象深拷贝
const copy = Object.create(original)

// 概率选择
const item = random.nextIterable(collection)

// 集合过滤
let filtered = list.where((item) { return item.rank >= minRank })

// 事件回调注册（在 main.ht 的 main() 中）
addEventHandlers(moduleId: meta.id, namespace: eventHandlers)

// 异步对话流程
async function onEvent() {
  await dialog.execute()
  await Player.acquire(item)
}
```

## 注意事项

- 注释使用中文
- `dynamic` 类型常见于跨语言互操作
- 事件函数（`onAfterMove`、`onAcquire` 等）通常为 `async`
- 修改后需重新编译: `python build.py`（输出到 `assets/mods/*.mod`）
