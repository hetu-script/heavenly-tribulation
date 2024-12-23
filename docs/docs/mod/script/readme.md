## 游戏创建

只会在生成新游戏世界时运行一次的初始化脚本，通常在这里将一些游戏对象添加到数据中。

```javascript
function init()
```

## 游戏初始化

每次开始游戏都会运行一次，通常在这里绑定回调函数

```javascript
function main()
```

## 自定义事件的回调函数

```javascript
function onNewGame()
function onUpdateGame()
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
function onBeforeHeroEnterSite(site)
function onAfterHeroEnterSite(site)
function onBeforeHeroExitSite(site)
function onAfterHeroExitSite(site)
function onInteractCharacter(characterId)
function onInteractObject(object, terrain)
```
