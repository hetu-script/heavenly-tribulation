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

和地图无关的事件

```javascript
function onEnterCultivation()
```

```javascript
/// 在第一次进入游戏时触发
function onNewGame()
/// 刷新世界时间后触发
function onAfterUpdate()
/// 开始和结束移动时触发
function onBeforeMove(terrain)
/// 角色移动后，最后处于endTerrain
/// 如果移动目标是一个无法进入的地块，则将该地块赋予targetTerrain
function onAfterMove(terrain, targetTerrain)
/// 在大地图上从外部进入某个门派的领地时触发
function onEnterTerritory(terrain, organization)
/// 在某个场景中点击NPC列表种的一个头像和其互动时触发
function onInteractCharacter(character)
/// 在地牢中点击某个地图上的可互动物体时触发
function onInteractObject(object, terrain)
/// 当进入地图场景时或从其他界面返回地图场景时触发
function onEnterMap()
/// 进入或离开某个据点场景时触发
function onBeforeEnterLocation(location)
function onAfterEnterLocation(location)
function onBeforeExitLocation(location)
function onAfterExitLocation(location)
```
