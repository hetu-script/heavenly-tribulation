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
/// 只会在第一次进入游戏时触发一次
function onNewGame()
/// 每当进入该地图场景时会触发，注意在进入其他界面返回地图时同样会触发
function onEnterMap()
function onAfterWorldUpdate()
function onAfterHeroRest({site, terrain})
function onAfterHeroGatherSpirit({site, terrain})
function onAfterHeroCondenseSpirit({site, terrain})
function onAfterHeroExplore(terrain)
function onAfterHeroWoodcut(terrain)
function onAfterHeroExcavate(terrain)
function onAfterHeroGather(terrain)
function onAfterHeroHunt(terrain)
function onAfterHeroFish(terrain)
function onBeforeHeroMove(terrain)
function onAfterHeroMove(terrain, target)
function onBeforeHeroEnterLocation(location)
function onAfterHeroEnterLocation(location)
function onBeforeHeroExitLocation(location)
function onAfterHeroExitLocation(location)
function onBeforeHeroExitSite(site)
function onAfterHeroExitSite(site)
function onInteractCharacter(characterId)
function onInteractObject(object, terrain)
```
