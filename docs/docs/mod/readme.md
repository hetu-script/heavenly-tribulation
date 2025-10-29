# 数据

所有的数据和逻辑分开保存。

数据包括：

游戏核心存档（包含所有的角色，组织等）
游戏时间线存档
游戏宇宙存档（包含所有的地图地块信息和据点信息）
本地化文本
动画
战斗卡牌主词条
战斗卡牌额外词条
预定义物品
地图装饰物品贴图
被动技能树
被动技能
战斗角色异常状态
科技树
科技
六边形地块
人物（含死者和婴儿）
组织
任务

某些数据是在游戏中通过脚本动态创建的。
某些数据以 json 格式预先保存。

每次创建游戏时，数据存档从 json 中读取。
每次启动游戏时，逻辑（脚本函数）通过各个 mod 加载。

# 命名空间

核心模组的数据和函数全部暴露在 global 空箭中可以直接访问和使用

其他的模组的脚本函数都保存在单独的命名空间中，不能直接访问

在调用模组的事件函数时，会临时将该函数通过 apply 的方式在 game.module.moduleName 对象上执行。

此时事件函数可以直接访问所有 global 上的对象

在导入模组时，会在 global 命名空间上赋值一个和 mod 名称相同的变量赋值
通过此变量才可以访问定义在模组内部的函数

# 接口

## 游戏创建

只会在第一次创建游戏世界时运行的初始化脚本，通常在这里将一些游戏数据和游戏对象添加到游戏的存档中。之后再次读取存档时这些数据会保留。

```javascript
function init()
```

## 游戏初始化

每次开始游戏都会运行一次，通常在这里绑定回调函数

```javascript
function main()
```

## 模组事件回调函数列表

### 通用事件

通过 onGameEvent() 调用

通用事件和地图无关，在任何地图或者场景都会触发

```javascript
/// ----------窗口操作----------
async function onEnterCardLibrary()
async function onEnterCultivation()
/// ----------属性变化----------
async function onRested()
/// 如果返回 true，会跳过游戏内置的交互逻辑
async function onDying() -> bool
/// ----------角色互动----------
async function onInteractNpc(location)
/// 如果返回 true，会跳过游戏内置的交互逻辑
async function onBeforeInteractCharacter(character) -> bool
/// 如果返回 true，会跳过游戏内置的交互逻辑
async function onInquireJournal(character, journal) -> bool
async function onShowTo(character, item)
/// ----------物品互动----------
/// 获得材料
async function onCollect(materialId, amount)
/// 获得物品
async function onAcquire(item)
/// 装备物品
async function onEquip(item)
/// 展示物品
async function onShow(character, item)
/// 赠送物品
async function onGift(character, item)
/// 某些身上的装备，会随着时间流逝调用自定义函数刷新属性
async function onUpdateItem(item)
/// ----------据点场景----------
async function onBeforeEnterLocation(location)
/// 进入据点场景
/// 如果返回 true，会跳过游戏内置的交互逻辑
/// 因为这个事件的逻辑较复杂，所以并不会一次就触发所有的事件
/// 每次触发后，就会返回 true，停止后续其他逻辑的判断
async function onAfterEnterLocation(location)
async function onBeforeExitLocation(location)
/// 在场景中点击某个非预定义的子场景时触发
async function onInteractLocationObject(object, location)
```

### 地图事件

通过 onWorldEvent() 调用

地图事件以地图为模块划分命名空间，分别绑定在不同的世界上

```javascript
/// 在第一次进入游戏，并且进入游戏时读取的是此地图时触发
async function onNewGame()
async function onEnterMap()
/// ----------世界地图----------
/// 刷新大地图世界时间，timestamp+1 后触发，非大地图的地牢没有这个事件
// async function onAfterUpdate()
/// 开始移动之前触发，如果返回值为 true，则会停止移动
async function onBeforeMove(terrain) -> bool
/// 开始移动之后触发，如果返回值为 true，则会停止移动
async function onAfterMove(terrain) -> bool
/// 在大地图上从外部进入某个门派的领地之后触发
async function onEnterTerritory(terrain, sect)
/// 在地牢中点击某个地图上的可互动物体时触发
async function onInteractMapObject(object, terrain)
```
