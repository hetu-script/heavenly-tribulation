# 随机任务

悬赏任务可以从据点的门派或者集会所领取。

### Mission types

- Escort-based Mission: The player(s) have to escort another character to a set location protecting them from incoming enemies.

- Combat-based Mission: The player(s) must eliminate a certain number of (or all) enemies.

- Rescue-based Mission: The player(s) must rescue another character from waves of enemies and escape.

- Collect-based Mission: The player(s) must obtain a certain number of (or all) items.

- Delivery-based Mission: The player(s) must deliver a specific item from one location to another location. Sometimes, the player must collect the item - first, instead of being handed the item to deliver.

- Pursuit-based Mission: The player(s) have to pursue and assassinate or capture the enemy. Sometimes, the player(s) must escape from incoming enemies by - remaining unseen.

- Boss-based Mission: The player(s) must assassinate the main boss character.

- Defence-based Mission: The player(s) have to protect a stationary object or character from incoming enemies.

- Stealth-based Mission: The player(s) must sneak through an area infested with enemies without being spotted. Sometimes, the player(s) must follow a - non-playable character to a set location.

- Time-based Mission: The player(s) have an set amount of time to complete a mission.

- Destroy-based Mission: The player(s) must destroy a certain number of (or all) objects.

- Race-based Mission: The player must race a number of laps (circuit) or (sprints) against other players or AI racers.

- Search-based Mission: The player(s) must locate a particular object or character, usually as a prelude to another mission.

# 随机地牢

Roguelike 副本玩法

## 撤离

中途撤离会保留到目前为止的物品。

对于某些剧情类地牢，可能无法中途撤离。

## 战败惩罚

通关失败会失去所有不在关键物品栏中的物品和装备，体力降为 1 点，并重新在上一个存档地点醒来，可能是自己家，或者是距离最近的据点的旅馆中。

已经挑战成功的地牢，本月不能再重新挑战，但如果失败可以继续挑战。

## 地牢设计

地牢的房间是一个 3×5×5×3×5×5 的六边形场地。
所有的房间都会有三个门通向下一个地块。

如果是当前层的最后一个房间，则其中一个门可以离开地牢，另两个门则前往下一层（但两个门进入的新层会有属性上的差异）。

地牢层数为 1-20 层。每层对应修为等级的 5 级。例如第一层地牢遇到的敌人，强度在 0-5 之间。

## 地图生成算法

已经通过的房间数，初始为 0。

生成房间时，要提供 room 值。生成完毕 room 值 + 1。

R 值为 0 代表初始房间，初始房间是空的，没有任何遭遇。

所有的房间（包括初始房间）固定有三个出口，默认情况下：

出口 1：下一个房间是宝箱、npc 或事件
出口 2：下一个房间是普通敌人
出口 3：下一个房间是随机房间，可能是精英敌人、普通敌人，所有类型的非敌人房间。
只有在随机房间能遇到隐藏宝箱、隐藏 npc 和隐藏事件。

当 (R + 1) % 3 == 0 时，房间只有一个出口，且必然是精英敌人。
精英敌人会掉落一张他所拥有的的卡牌。

当 (R + 1) % 3 == 0 且已经击败过两次精英敌人后，下一个房间只有一个出口，且必然是 Boss。

Boss 房间仍然有三个出口，中间的出口可以离开地牢。另外两个则是进入下一层。

## 宝箱

装备
卡牌
材料

## npc

医师：花费材料，恢复体力
商人：花费材料，获得指定的装备、卡牌
赌博：花费材料，获得随机的装备、卡牌（三选一）
黑暗商人：销毁装备、卡牌，转换为其他的装备、卡牌或材料
工匠：通过材料制作装备和卡牌，以及对其进行修改和升级）
事件 NPC：获得 Buff/Debuff

## 敌人

有敌人的房间，必须消灭敌人才能进入下一层

### 普通

等级 = (当前层 + 1) × 10 - 10

### 精英

等级 = (当前层 + 1) × 10 - 5

精英会有更强的卡牌

### BOSS

等级 = (当前层 + 1) × 10

BOSS 会有更强的卡牌

#### 随机遭遇：

#### 山贼

选择
1，交出财物
2，求情
3，逃跑
4，战斗

下面的遭遇并非每次都有，每张地图只会有一个

#### 行贩/猎户/樵夫

行贩：可以购买炊饼、村酒、野果、牛肉干
猎户：可以购买烤肉、兽皮、兽骨、兽肉
樵夫：可以购买草药、根、叶、花

#### 迷路的行人

1，将其杀死（邪恶道路）
2，告之来路
3，给他粮果酒水

#### 被关押的另一个英雄角色

选择：
1，将其杀死（邪恶道路）
2，掳掠其物品，然后放走（印象--）
3，将其解救，让其自行回去（印象+）
4，将其解救，并给其金钱资助（印象++）

#### 前来讨贼的另一个英雄角色

选择：
1，将其杀死（邪恶道路）
2，掳掠其物品，然后放走（印象--）
3，和其一同做任务，赏金平分。
4，和其一同做任务，但赏金归自己（需要战斗胜利，印象-）。
5，和其一同做任务，但奖金让给他（印象+）。

#### 被埋藏的其他人的宝物

选择：
1，留下给自己
2，一并上交给官府/送给发布任务的人
3，还给物品原本的主人（需要鉴定并还原其历史）

### 副本随机地图场景：

庙宇

山洞

铺设的地板

河流

水潭

瀑布
