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
async function onOpenInventory()
async function onOpenCultivation()
/// ----------属性变化----------
async function onRested()
/// ----------角色互动----------
async function onTalkTo(character, topic)
async function onInquiryQuest(character, quest)
async function onShowTo(character, item)
/// ----------物品互动----------
async function onEquipItem(item)
async function onUseItem(item)
async function onGiftItem(character, items)
/// 某些具有充能次数的物品，在装备在身上时，会随着时间流逝调用自定义函数刷新属性
async function onUpdateItem(item)
```

### 地图事件

通过 onWorldEvent() 调用

地图事件以地图为模块划分命名空间，分别绑定在不同的世界上

```javascript
/// 在第一次进入游戏，并且进入游戏时读取的是此地图时触发
async function onNewGame()
/// ----------世界地图----------
async function onEnterMap()
/// 刷新大地图世界时间，timestamp+1 后触发，非大地图的地牢没有这个事件
async function onAfterUpdate()
/// 开始移动之前触发，如果返回值不为null，则会停止移动
async function onBeforeMove(terrain)
async function onAfterMove(terrain, worldId)
/// 在大地图上从外部进入某个门派的领地之后触发
async function onEnterTerritory(terrain, organization)
/// 在地牢中点击某个地图上的可互动物体时触发
async function onInteractMapObject(object, terrain)
// /// 在场景中点击某个非预定义的子场景时触发
async function onInteractLocationObject(object, location)
/// ----------据点场景----------
async function onBeforeEnterLocation(location)
async function onAfterEnterLocation(location)
async function onBeforeExitLocation(location)
async function onAfterExitLocation(location)
```
