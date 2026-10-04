# 主词条

## 修改

  悟道流派：water_mend：至多移除 x { base: 3, inrement: 0.15 } 层元素异常，每移除一层异常，获得 {base: 4, increment: 0.1} 生命 unique_ids: ["for_element_dots_heal"]

## 增加

  悟道流派：eartch_mend：至多移除 x { base: 3, inrement: 0.15 } 层元素异常，每移除一层异常，获得 {base: 6, increment: 0.15} 护甲 unique_ids: ["for_element_dots_defend"]

# 额外词条

## 修改

  悟道流派：reduce_cost_by_cards_in_hand 应该是在每次手牌变化时都会重新计算，时机应该类似现有的卡牌费用计算的那些场合。

## 增加

  悟道流派：自身每有一层任意元素异常，获得 {base: 4, increment: 0.1} 生命 使用unique_id: "for_element_dots_heal"，不会出现在water_mend上。
  悟道流派：自身每有一层任意元素异常，获得 {base: 6, increment: 0.15} 护甲 使用unique_id: "for_element_dots_defend"，不会出现在water_mend上。

## 绝世卡牌专属额外词条

（绝世卡牌专属额外词条不会出现在普通卡牌上，可以给card_affixes.json5里面的数据也增加isUnique来判断专属词条，这些词条不进入普通卡牌的词条池）

### 紫微斗数

主词条改为：抽一张法术牌。
固定额外词条列表：
获得防御
回复生命
[专属]抽到的牌费用-1
此牌费用-2
[专属]额外抽1张牌
[专属]抽到的牌费用为0


### 天机术

固定额外词条列表：
[专属]spellcraft_scry_draw_affix_1查看的牌数量+2
[专属]spellcraft_scry_draw_affix_2选中的牌获得升级
[专属]spellcraft_scry_draw_affix_3选中的牌费用-1
此牌费用-2
[专属]spellcraft_scry_draw_affix_5选中的牌获得保留
[专属]spellcraft_scry_draw_affix_6可选择的牌+1, 抽牌+1
