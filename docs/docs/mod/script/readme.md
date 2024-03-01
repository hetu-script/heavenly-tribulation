游戏中的脚本都会挂载在某个 entity 身上（游戏本身也是 component）
Dart 在适当的时候调用某些脚本，获取到的运算结果是以 Json 格式表现，这就是游戏的当前数据。
Dart 也会将 Json 数据作为参数返回给脚本使用。

## 游戏初始化 creation

生成游戏世界的初始化脚本，创建游戏时读取一次。

```javascript
function createGame() {
  final game =  {
    datetime: {
      year: 1,
      month: 1,
      day: 1
    },
    characters: [
    ],
    items: [
    ]
    cities: [
      lingzhou: {
      locations: [
        baiheguan: {
        scenes: [
        ]
        }
      ]
      }
    ],
  }
  return game.toJSON()
}
```

## 逻辑帧脚本 update

每过一段时间就固定调用一次的脚本。
逻辑帧可以挂载在任意游戏中的 Entity 上，包括世界、角色、物品等。

```
game.update = fun {
    final rain = []
    for (var i = 0; i < 50; ++i) {
        rain.add(RainDrop())
    }
    addAllEntity(rain)
}
```

## 动态脚本 invocation

在需要的时候再调用执行。

```
var flower1 = Flower()
addEntity(flower, positionX: 1, positionY: 2)
```

## 真名实姓

要想写脚本修改世界中已有的实体，一定需要知道该实体的"id"，也就是它的真名实姓。

```
var entity = getEntityById('flower1')
entity.destroy()
```
