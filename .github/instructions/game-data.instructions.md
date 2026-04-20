---
applyTo: "assets/data/**/*.json5"
description: "Use when editing JSON5 game data files. Covers schemas for cards, items, maps, passives, status effects, quests, and other game data."
---

# 游戏数据（JSON5）编写规范

所有数据文件为顶层对象，以实体 ID 为键。ID 使用 `snake_case`。

## 通用字段

- `id: string` — 必须与键名一致
- `description: string` — 本地化键（`engine.locale()` 使用）
- `rarity: string` — common / rare / epic / legendary / mythic / arcane

## 卡牌（cards.json5）

```json5
{
  punch_attack: {
    id: "punch_attack",
    category: "attack",          // "attack" | "buff"
    kind: "punch",
    attackType: "unarmed",       // unarmed | weapon | spell | curse | chaos
    damageType: "physical",      // physical | chi | element | spirit | pure
    description: "affix_attack_unarmed",
    image: "battlecard/illustration/punch_attack.png",
    script: "attack",            // 对应 scripts/ 中的函数
    animation: { startup: [...], recovery: [...] },
    // 可选: genre, rank, isUnique, isHidden, isEphemeral, equipment
    valueData: [{ base: 10, increment: 2 }],  // 数值 = base + level * increment
  }
}
```

## 词条（card_affixes.json5）

与卡牌结构类似，额外字段: `uniqueId`（防止堆叠）、`tags`（标签数组）、`priority`。
`category` 可以是字符串或字符串数组（如 `["buff", "attack"]`）。

## 物品（items.json5）

```json5
{
  item_name: {
    id: "item_name",
    name: "item_name", // 本地化键
    type: "consumable", // "consumable" | "material" | ["consumable", "material"]
    category: "exp_pack",
    rarity: "rare",
    icon: "item/exp_pack.png",
    // 布尔标记: isIdentified, isUntradable, isUsable, isEquipable,
    //          isCursed, isCorrupted, isRankedItem, isUnstackable
  },
}
```

## 地图（maps.json5）

必须字段: `id`, `width`, `height`, `tileShape: "hexagonalVertical"`, `gridWidth: 32.0`, `gridHeight: 28.0`, `terrains` 数组。
地形 kind 值: void / plain / forest / mountain / shore / lake / sea / river / road / city。

## 天赋（passives.json5）

字段: `id`, `description`, `uniqueId`（相关天赋共享）, `priority`, `increment`。
可选: `isItem`, `isItemMain`, `isPotion`, `isEphemeral`, `kind`（装备类型限制）, `rank`。

## 状态效果（status_effect.json5）

字段: `id`, `title`, `description`, `icon`, `script`。
可选: `isPermanent`, `isOngoing`, `isUnique`, `attackType`, `callbacks`。
图标路径: `icon/status/{permanent|temporary}/{id}.png`。

## 跨文件引用

- cards/card_affixes → `script` 字段引用 Hetu 脚本函数
- cards ↔ status_effect → 通过 `attackType` 关联
- passives ↔ card_affixes → 通过 `uniqueId` 关联
- craftables → items → 通过装备 `kind` 关联
