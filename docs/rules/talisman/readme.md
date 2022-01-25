人物身上一共可以装备 4 种装备类法宝和 4 个其他法宝。

装备类法宝必定包含防御或者遁术。其他法宝则可以附加任何功法，包括主要用来进攻的功法和辅助功法，系统参考 POE 的技能宝石

装备类法宝包括：帽子、衣服、鞋、飞行器四种，只能每种装备一个。

其他法宝装备时，则没有种类限制。

只能拥有一个本命法宝，本命法宝被摧毁时会损失精血

法宝等级：

法器
法宝
灵宝

其他法宝：
刀、剑、枪、戈、斧、锤、环、盾、碑、网、锁、铃、扇、拂尘、伞、鼓、镜、尺、琴、袋、山、岛、塔、舟、车、钟、梭、牌、鼎、铡、瓶、盘、图、印玺、玉简、幡旗、琵琶、翅膀、戒指、玉佩

```javascript
module.exports.ironSword = function () {
  this.key = 'ironsword_' + randId(4) + randId(4) + randId(4) + randId(4);
  this.name = '玄铁剑';
  this.image = '/images/icon/unkwon_item.png';
  this.description = '一把式样古朴的宝剑，用玄铁制成，隐隐含有灵气之力。';
  this.cost = 1;
  this.rarityLevel = 1;
  this.stackSize = 1;
  this.stack = 1;
  this.acquisitions = {};
  this.type = 'talisman';

  this.attributes = {
    // summonChiCost: 10 - 15
    summonChiCost: Math.floor(Math.random() * 6) + 10,
    // summonTime: 2 - 3
    summonTime: (Math.random() + 2).toFixed(1),
    // cooldown: 3 - 4
    cooldown: (Math.random() + 3).toFixed(1),
    // damage: 10 - 15
    damage: Math.floor(Math.random() * 6) + 10,
    // life: 40 - 50
    life: Math.floor(Math.random() * 11) + 40,
    defense: 0,

    sockets: [
      { type: 'jin', maxLevel: 10 },
      { type: 'mu', maxLevel: 5 },
      { type: 'shui', maxLevel: 5 },
    ],
  };
};
```
