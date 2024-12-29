# 个人战

个人战是游戏中的小游戏之一。

战斗中的招式就是卡牌，招式在战斗中一张一张轮流打出，并且带有一些直接伤害或者影响对手的即时效果。

本质上是卡牌打造和卡牌自动战斗。

卡牌打造借鉴自游戏：《流放之路》

卡牌自动战斗借鉴自游戏：《弈仙牌》。

# 卡组

战斗前可以从事先准备好的最多 5 种卡组中选择一个，并可以临时修改

战斗前可以探测对手使用的卡牌，自身的感知属性决定了能探测卡牌的数量上限。

# 卡牌

卡牌的效果分为基础词缀，普通词缀和特殊词缀

卡牌根据卡牌类型，拥有一条基础词缀

基础词缀的数字可以随着卡牌本身的升级而提升，卡牌本身的等级最多提升到 25 级

普通词缀卡牌最多可以拥有互不相同的三条

特殊词缀卡牌只能拥有一条

角色最多可以使用超过两个境界的卡牌。例如凝气最高可以使用结丹期的卡牌。

角色的卡组上限和境界有关。

| 角色境界 | 卡组上限 | 卡组中允许的消耗或持续牌上限 |
| -------- | -------- | ---------------------------- |
| 凝气     | 3        | 1                            |
| 筑基     | 4        | 1                            |
| 结丹     | 5        | 2                            |
| 元婴     | 6        | 2                            |
| 化神     | 7        | 3                            |
| 炼虚     | 8        | 3                            |
| 合体     | 9        | 4                            |
| 大乘     | 10       | 4                            |

## 攻击

### 普通攻击

基础词缀为不消耗资源的伤害

### 特殊攻击

咒语等直接削减生命值的攻击方式

### 高阶攻击

消耗资源，造成更多伤害
通过卡牌联协，造成更多伤害

### 终结攻击

消耗资源造成最大的伤害，但卡组中只能存在一张终结攻击

## 加持

回复生命、灵气
获得防御、速度、闪避
获得一些 buff 效果等等

### 躲闪

速度和气竭

当你回合开始时有 10 点速度时，消耗这些速度，你获得 1 点再次行动

躲闪：消耗 10 点速度，无效化对手下一张牌的所有伤害

## 持续

持续数个回合或者持续整场比赛

或类似丹药等消耗后产生永久效果

对于 8 张卡组，只能存在最多 3 张消耗牌

6 张卡组，2 张消耗牌

4 张卡组，1 张消耗牌

## 资源

剑气、灵气相关

# 攻击卡牌词缀

御剑攻击卡牌基本词缀

武器攻击: 12-24
武器攻击：6-12 × 2
武器攻击：4-8 × 3
武器攻击：3-6 × 4

御剑防御卡牌基本词缀

御剑资源卡牌基本词缀

剑气+1

悟道卡牌基本词缀
雷元素攻击：
火元素攻击：
风元素攻击：
冰元素攻击：
土元素攻击

# 词条

每个流派有数张不同的固定词条的卡牌，它们会有一个固定的词条，这个固定词条本身决定了卡牌的类型（拳法，咒语，法术等等）

每张卡牌，根据其境界，还可能拥有其他词条，这些随机词条从该类型和流派的全部词条中随机选取。

# 鉴定

卡牌的主词条是可以直接看到并使用的。

但卡牌的额外词条及其效果，需要鉴定后才能使用。拥有多个额外词条的卡牌，每次鉴定只能揭示其中一个效果。

# 模型

1 点灵气=7 攻=7 命=10 防=3 闪避=3 速度

# 卡牌类型

攻击（普通攻击，法术攻击或使对方获得减益）
加持（自身获得资源或增益）
特殊（其他效果）

1，每种类型卡牌有单独的词条列表
2，每个词条都会有自己的灵气消耗（可能为负或者百分比），卡牌总消耗为所有词缀的灵气消耗之和

# 词条等级和卡牌等级，卡牌境界

词条本身可以通过卡牌升级强化。但词条等级不能超过卡牌等级。
随机生成的卡牌，其词条等级也是在 1-卡牌等级之间随机的。
词条本身的随机值只能通过精炼·混元调整。
化神或以上可能有 1/20 的几率得到太古词条，太古词条是普通词条数值最大值的 1.5 倍。只能在化神或一上境界的卡牌上才能出现。

卡牌本身可以被精炼
卡牌升级会附带卡牌主词条的升级。

提升境界后会增加词条数量的下限和上限。
提升境界后，如果词条数量不足下限，会随机增加词条。

| 卡牌境界 | 基础词条数量 | 额外词条数量 | 太古词条数量 |
| -------- | ------------ | ------------ | ------------ |
| 凝气     | 1            | 0-1          | 0            |
| 筑基     | 1            | 1-2          | 0            |
| 结丹     | 1            | 2-3          | 0            |
| 元婴     | 1            | 3-4          | 0            |
| 化神     | 1            | 4            | 0-1          |
| 炼虚     | 1            | 4            | 1-2          |
| 合体     | 1            | 4            | 2-3          |
| 大乘     | 1            | 4            | 3-4          |

词条本身的数值有上限和下限，具体数值将会处于这两者之间。游戏数据中保存的实际上是一个 0-1 之间的数，表示上下限之间的具体位置（取整）。

当卡牌升级时，这个 0-1 之间的数值不变，但上下限会提升。因此实际数值也会因此而提升。

词条本身的随机值只能通过精炼·混元调整，但满值的太古词条只能在化神或以上境界的卡牌上才能出现。并且每个境界太古词条总数量有上限。达到上限后，就不能再获得太古词条。

# 精炼

以下所有功能都可以撤回，但撤回不返还消耗的材料

## 精炼·混元

随机化一个主词条或额外词条的数值（随机数取 0-1，但不包括 1，太古词条不能再执行此项精炼）

## 精炼·灵宝

随机增加一个额外词条（不能超过境界允许的词条上限）

## 精炼·神照

随机替换一个额外词条

## 精炼·璇玑

随机提升一个额外词条等级（不能超过卡牌等级上限）

## 精炼·灵悟

提升卡牌等级，同时提升基础词条等级，等级不能超过当前境界上限

## 精炼·破境

提升卡牌境界（卡牌本身升级满后才能提升境界，每个境界需要的材料不同）

打造卡牌词缀时，只能从角色已知的词条库中随机获取
获得新卡牌并领悟后，可以将新词条加入词条库