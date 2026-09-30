/// 游戏数据一致性校验工具
///
/// 用法:
///   dart run data_validate/game_data_validate.dart [项目根目录]
///
/// 校验文件:
///   assets/data/cards.json5 / card_affixes.json5 / passives.json5 / status_effect.json5 / items.json5
///
/// 检查项（错误，影响退出码）:
///   1. id 一致性: 条目 id 字段必须等于键名
///   2. 本地化: description / title / uniquecard_* 等键必须存在于 assets/locale/zh/**.json
///   3. 脚本存在性（契约见 docs/docs/mod/battle/card/readme.md）:
///      - 无 callbacks 的词条/卡牌，基名函数必须存在于 card_script.ht；
///      - 声明了 callbacks 的词条，每个 {script}_{时机} 必须存在（基名可缺省）；
///      - 状态声明的每个 callbacks 时机，{script}_{时机} 必须存在于 status_script.ht；
///      - 时机名必须在 Dart 侧实际分发（从 character.dart / battle.dart 提取）
///   4. 悬空引用: buffId / resourceId / debuffs / battleStatus / shuffleIntoDeck /
///      affixes / uniqueIds / energyRetain.resourceId / items.affixes 指向不存在的目标
///   5. 格式: category / genre / cardType / damageType / elementType / cost 颜色 /
///      ephemeralType / rank 等枚举与取值范围；coloredCost / filter / valueData /
///      deckCostReduction（含 color: 'all' 与负值加费）/ energyRetain / turnStartExtraDraw 结构
///   6. 数值占位: 描述文本中的 {N} 下标必须小于 valueData 长度
///   7. 资源文件: image / icon 指向的文件必须存在于 assets/images/
///   8. 物品（items.json5，createItemById 语义）: type/rarity/rank/icon/category/kind、
///      isRankedName 境界名本地化键、布尔标记类型与未知 is* 标记（提示）、
///      isRankedItem 带 rarity 死字段（提示）、
///      绝世装备约定（uniqueId == 键名、isUnstackable、isIdentified: false、显式 rank、affixes 非空）
///
/// 提示项（不影响退出码）:
///   - keyword 标签缺少对应的 {tag}_description（悬浮提示会回落为原始键名）
///   - kind 不在 kBattleCardKinds 常量表中（该表维护较松，仅供参考）
///   - 卡牌缺 category / script（placeholder 等占位卡属合法）
///
/// 退出码: 存在错误为 1，全部通过（可含提示）为 0，文件缺失/解析失败为 2。
library;

import 'dart:convert';
import 'dart:io';

import 'package:json5/json5.dart';
import 'package:path/path.dart' as p;

// ---------------------------------------------------------------------------
// 常量表（与 lib/data/common.dart、数据文件头部注释保持一致；改动需同步）
// ---------------------------------------------------------------------------

const kCategories = {'attack', 'buff'};

const kGenres = {
  'neutral',
  'swordcraft',
  'spellcraft',
  'bodyforge',
  'avatar',
  'vitality',
};

const kCardTypes = {
  'unarmed',
  'weapon',
  'spell',
  'curse',
  'shenfa',
  'xinfa',
  'divinity',
};

const kDamageTypes = {
  'physical',
  'chi',
  'psychic',
  'fire',
  'ice',
  'lightning',
  'poison',
  'pure',
};

const kElementTypes = {
  'element_metal',
  'element_wood',
  'element_water',
  'element_fire',
  'element_earth',
  'element_wind',
  'element_lightning',
};

/// coloredCost 的合法颜色键（元气 life + 四流派色；太极之气是支付手段而非费用色）
const kCostColors = {'life', 'spell', 'weapon', 'unarmed', 'curse'};

const kEphemeralTypes = {'attack', 'defense', 'attribute', 'energy'};

/// 常见属性 id（for_attribute_increase_damage 的 attributeId；表外仅提示）
const kAttributeIds = {
  'strength',
  'dexterity',
  'spirituality',
  'willpower',
  'perception',
};

/// 与 kBattleCardKinds 同步（该常量表维护较松，表外仅提示）
const kCardKinds = {
  'punch',
  'kick',
  'qinna',
  'dianxue',
  'sabre',
  'spear',
  'sword',
  'staff',
  'bow',
  'dart',
  'flying_sword',
  'shenfa',
  'qinggong',
  'xinfa',
  'airbend',
  'firebend',
  'waterbend',
  'lightning_control',
  'earthbend',
  'plant_control',
  'sigil',
  'power_word',
  'scripture',
};

/// filter / not / require 条件子表允许的字段（见 docs/docs/mod/battle/card/readme.md）
const kFilterKeys = {'category', 'genre', 'cardType', 'kind', 'elementType'};

const kAnimationKeys = {'startup', 'recovery', 'actions', 'overlays', 'sound'};

/// 脚本必需的数据字段（缺失会在运行时报错或静默失效）
const kScriptRequiredFields = {
  'self_buff': ['buffId'],
  'opponent_debuff': ['buffId'],
  'attack_buff': ['buffId'],
  'attack_debuff': ['buffId'],
  'convert_vigor_all': ['buffId'],
  'heal_remove_debuffs': ['debuffs'],
  'for_attribute_increase_damage': ['attributeId'],
  'increase_damage_by_energy_count': ['resourceId'],
  'gain_resource_next_turn': ['resourceId'],
  'attack_exhaust_energy': ['resourceId'],
  'attack_with_energy_count_check': ['resourceId'],
};

/// items.json5 的合法物品类型（见文件头注释）
const kItemTypes = {
  'consumable',
  'equipment',
  'craftmaterial',
  'miscellaneous'
};

const kRarities = {'common', 'rare', 'epic', 'legendary', 'mythic', 'arcane'};

/// 与 kEquipmentCategoryKinds（lib/data/common.dart）同步，改动需同步
const kEquipmentCategoryKinds = {
  'weapon': {'sword', 'sabre', 'spear', 'staff', 'bow', 'dart'},
  'shield': {'shield'},
  'armor': {'armor'},
  'gloves': {'gloves'},
  'helmet': {'helmet'},
  'boots': {'boots'},
  'vehicle': {'ship'},
  'jewelry': {'ring', 'amulet'},
  'talisman': {'pearl'},
};

/// 已知物品布尔标记（表外 is* 字段仅提示——可能是拼写错误，如 isEquipable）
const kItemFlags = {
  'isRankedName',
  'isRankedItem',
  'isIdentified',
  'isUntradable',
  'isUnstackable',
  'isUsable',
  'isCombinable',
  'isEquippable',
  'isCursed',
  'isCorrupted',
  'isAfflicted',
  'isUnique',
};

// ---------------------------------------------------------------------------
// 报告收集
// ---------------------------------------------------------------------------

final _errors = <String, List<String>>{};
final _warnings = <String, List<String>>{};

void err(String section, String item) =>
    _errors.putIfAbsent(section, () => []).add(item);

void warn(String section, String item) =>
    _warnings.putIfAbsent(section, () => []).add(item);

// ---------------------------------------------------------------------------
// 全局上下文（main 中初始化）
// ---------------------------------------------------------------------------

late final String root;
late final Map<String, String> localeTexts; // 键 -> 文本（合并 zh 下全部 json）
late final Set<String> cardIds;
late final Set<String> affixIds;
late final Set<String> affixUniqueIds;
late final Set<String> statusIds;
late final Set<String> passiveIds;
late final Set<String> cardScriptFuncs;
late final Set<String> statusScriptFuncs;
late final Set<String> statusTimings;
late final Set<String> affixTimings;

// ---------------------------------------------------------------------------
// 加载与提取
// ---------------------------------------------------------------------------

Map<String, dynamic> loadJson5(String relPath) {
  final path = p.join(root, relPath);
  if (!FileSystemEntity.isFileSync(path)) {
    stderr.writeln('找不到数据文件: $path');
    exit(2);
  }
  final dynamic parsed;
  try {
    parsed = JSON5.parse(File(path).readAsStringSync());
  } catch (e) {
    stderr.writeln('JSON5 解析失败: $path\n$e');
    exit(2);
  }
  if (parsed is! Map) {
    stderr.writeln('数据文件顶层必须是对象: $path');
    exit(2);
  }
  return parsed.cast<String, dynamic>();
}

/// 合并 assets/locale/zh/ 下全部 .json 的顶层键（重复键后者覆盖前者，仅作存在性检查）
Map<String, String> loadLocaleTexts() {
  final dir = Directory(p.join(root, 'assets/locale/zh'));
  if (!dir.existsSync()) {
    stderr.writeln('找不到本地化目录: ${dir.path}');
    exit(2);
  }
  final result = <String, String>{};
  for (final entity in dir.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.json')) continue;
    try {
      final dynamic parsed = jsonDecode(entity.readAsStringSync());
      if (parsed is Map) {
        for (final entry in parsed.entries) {
          if (entry.value is String) {
            result[entry.key as String] = entry.value as String;
          }
        }
      }
    } catch (e) {
      warn('本地化文件解析失败（已跳过）', '${entity.path}: $e');
    }
  }
  return result;
}

/// 从 hetu 脚本中提取命名空间内定义的函数名（先去除注释避免误匹配）
Set<String> extractScriptFunctions(String relPath) {
  final path = p.join(root, relPath);
  if (!FileSystemEntity.isFileSync(path)) {
    stderr.writeln('找不到脚本文件: $path');
    exit(2);
  }
  var text = File(path).readAsStringSync();
  text = text.replaceAll(RegExp(r'/\*[\s\S]*?\*/'), '');
  text = text.replaceAll(RegExp(r'//[^\n]*'), '');
  return RegExp(r'(?:async\s+)?function\s+(\w+)\s*\(')
      .allMatches(text)
      .map((m) => m.group(1)!)
      .toSet();
}

/// 从 Dart 源码中提取某派发方法的字符串字面量时机参数（先去除行注释）
Set<String> extractCallbackTimings(List<String> relPaths, String method) {
  final pattern = RegExp("$method\\(\\s*'(\\w+)'");
  final result = <String>{};
  for (final relPath in relPaths) {
    final path = p.join(root, relPath);
    if (!FileSystemEntity.isFileSync(path)) {
      stderr.writeln('找不到 Dart 源码: $path');
      exit(2);
    }
    var text = File(path).readAsStringSync();
    text = text.replaceAll(RegExp(r'//[^\n]*'), '');
    result.addAll(pattern.allMatches(text).map((m) => m.group(1)!));
  }
  return result;
}

// ---------------------------------------------------------------------------
// 通用检查
// ---------------------------------------------------------------------------

/// id 字段必须等于键名
void checkId(Map data, String key, String ctx) {
  if (data['id'] != key) {
    err('id 与键名不一致', '$ctx: id=${data['id']}');
  }
}

/// 本地化键存在性（字段缺失时 required 控制是否报错）
void checkLocaleKey(dynamic key, String ctx, {bool required = true}) {
  if (key == null) {
    if (required) err('本地化键缺失', '$ctx: 字段不存在');
    return;
  }
  if (key is! String || !localeTexts.containsKey(key)) {
    err('本地化键缺失', '$ctx: $key');
  }
}

/// 枚举字段合法性
void checkEnum(dynamic value, Set<String> allowed, String ctx,
    {bool warnOnly = false}) {
  if (value == null) return;
  if (value is! String || !allowed.contains(value)) {
    final item = '$ctx: $value（允许: ${allowed.join('/')}）';
    warnOnly ? warn('枚举值可疑', item) : err('枚举值非法', item);
  }
}

/// 数值字段（含范围）
void checkNumber(dynamic value, String ctx, {num? min, num? max}) {
  if (value == null) return;
  if (value is! num) {
    err('字段类型非法', '$ctx: 期望数值，实际 $value');
    return;
  }
  if ((min != null && value < min) || (max != null && value > max)) {
    err('数值超出范围', '$ctx: $value（期望 $min~$max）');
  }
}

/// 状态引用（buffId / resourceId / battleStatus 等）
void checkStatusRef(dynamic id, String ctx) {
  if (id == null) return;
  if (id is! String || !statusIds.contains(id)) {
    err('悬空引用（状态不存在）', '$ctx: $id');
  }
}

/// 通用引用字段：buffId / resourceId / debuffs
void checkCommonRefs(Map data, String ctx) {
  checkStatusRef(data['buffId'], '$ctx.buffId');
  checkStatusRef(data['resourceId'], '$ctx.resourceId');
  final debuffs = data['debuffs'];
  if (debuffs is List) {
    for (final d in debuffs) {
      checkStatusRef(d, '$ctx.debuffs');
    }
  }
}

/// 资源文件存在性（image / icon，相对 assets/images/ 的路径）
void checkImageFile(dynamic relPath, String ctx) {
  if (relPath == null) return;
  if (relPath is! String) {
    err('字段类型非法', '$ctx: 期望路径字符串，实际 $relPath');
    return;
  }
  if (!FileSystemEntity.isFileSync(p.join(root, 'assets/images', relPath))) {
    err('资源文件缺失', '$ctx: assets/images/$relPath');
  }
}

/// keywords 标签：标签键必须存在；缺 {tag}_description 仅提示（悬浮回落为键名）
void checkKeywords(Map data, String ctx) {
  final keywords = data['keywords'];
  if (keywords is! List) return;
  // 本地化例外：这几个标签在 stats.dart 的属性 UI 上有专门处理，不走通用本地化
  const localeExceptions = {
    'plainMoveSpeed',
    'mountainMoveSpeed',
    'waterMoveSpeed',
    'meditateSpeed',
  };
  for (final tag in keywords) {
    if (tag is! String) {
      err('字段类型非法', '$ctx.keywords: 期望字符串，实际 $tag');
      continue;
    }
    if (localeExceptions.contains(tag)) continue;
    if (!localeTexts.containsKey(tag)) {
      err('keyword 标签本地化缺失', '$ctx: $tag');
    } else if (!localeTexts.containsKey('${tag}_description')) {
      warn('keyword 缺悬浮描述（${tag}_description）', '$ctx: $tag');
    }
  }
}

/// 描述文本中的 {N} 占位下标必须小于 valueData 长度
void checkValueDataPlaceholders(Map data, String ctx) {
  final descKey = data['description'];
  final text = descKey is String ? localeTexts[descKey] : null;
  if (text == null) return; // 键缺失已在本地化检查中报告
  final indices =
      RegExp(r'\{(\d+)\}').allMatches(text).map((m) => int.parse(m.group(1)!));
  if (indices.isEmpty) return;
  final valueCount = (data['valueData'] as List?)?.length ?? 0;
  final maxIndex = indices.reduce((a, b) => a > b ? a : b);
  if (maxIndex >= valueCount) {
    err('数值占位越界', '$ctx: 描述用到 {$maxIndex}，valueData 仅 $valueCount 项');
  }
}

/// valueData 结构：列表项必须为含数值 base 的表
void checkValueDataShape(Map data, String ctx) {
  final valueData = data['valueData'];
  if (valueData == null) return;
  if (valueData is! List) {
    err('字段类型非法', '$ctx.valueData: 期望列表');
    return;
  }
  for (var i = 0; i < valueData.length; i++) {
    final item = valueData[i];
    // base 可缺省（视为 0），但 base/increment 至少其一存在且均为数值
    if (item is! Map || (item['base'] == null && item['increment'] == null)) {
      err('valueData 结构非法', '$ctx.valueData[$i]: 期望含 base/increment 的表');
      continue;
    }
    checkNumber(item['base'], '$ctx.valueData[$i].base');
    checkNumber(item['increment'], '$ctx.valueData[$i].increment');
    checkNumber(item['maxLevel'], '$ctx.valueData[$i].maxLevel', min: 0);
  }
}

/// 脚本必需字段契约（kScriptRequiredFields）
void checkScriptContract(Map data, String ctx) {
  final script = data['script'];
  if (script is! String) return;
  final required = kScriptRequiredFields[script];
  if (required == null) return;
  for (final field in required) {
    if (data[field] == null) {
      err('脚本必需字段缺失', '$ctx: $script 需要 $field');
    }
  }
}

/// 卡牌/词条脚本检查（CardScript）
/// isMainAffix: 主词条（cards.json5 顶层条目）基名缺失时只提示（placeholder 类合法）；
/// 额外词条无 callbacks 时基名必须存在；声明 callbacks 后基名可缺省，
/// 但每个 {script}_{时机} 必须存在，时机名必须在 Dart 侧实际分发。
void checkCardScript(Map data, String ctx, {required bool isMainAffix}) {
  final script = data['script'];
  final callbacks =
      (data['callbacks'] as List?)?.whereType<String>().toList() ?? const [];
  if (script == null) {
    if (callbacks.isNotEmpty) {
      err('脚本字段缺失', '$ctx: 声明了 callbacks 但没有 script 前缀');
    } else if (isMainAffix && data['isUnpackable'] != true) {
      warn('主词条无 script', '$ctx: 打出时无效果（占位卡合法，其余请确认）');
    }
    return;
  }
  if (script is! String) {
    err('字段类型非法', '$ctx.script: 期望字符串');
    return;
  }
  final baseExists = cardScriptFuncs.contains(script);
  if (callbacks.isEmpty) {
    if (!baseExists) {
      if (isMainAffix) {
        err('主词条脚本函数不存在', '$ctx: CardScript.$script');
      } else {
        err('词条脚本函数不存在', '$ctx: CardScript.$script（纯回调词条请声明 callbacks）');
      }
    }
    return;
  }
  var anyCallable = baseExists;
  for (final timing in callbacks) {
    if (!affixTimings.contains(timing)) {
      err('词条时机未在 Dart 侧分发', '$ctx: $timing');
    }
    final funcId = '${script}_$timing';
    if (cardScriptFuncs.contains(funcId)) {
      anyCallable = true;
    } else {
      err('时机回调函数缺失', '$ctx: CardScript.$funcId');
    }
  }
  if (!anyCallable) {
    err('脚本无可派发函数', '$ctx: 基名与全部时机回调均不存在');
  }
}

/// 状态脚本检查（StatusScript）：仅当声明 callbacks 时检查 {script}_{时机} 存在；
/// script 无 callbacks 属合法（资源气等由 Dart 直接结算）
void checkStatusScript(Map data, String ctx) {
  final script = data['script'];
  final callbacks =
      (data['callbacks'] as List?)?.whereType<String>().toList() ?? const [];
  if (script == null) {
    if (callbacks.isNotEmpty) {
      err('脚本字段缺失', '$ctx: 声明了 callbacks 但没有 script 前缀');
    }
    return;
  }
  for (final timing in callbacks) {
    if (!statusTimings.contains(timing)) {
      err('状态时机未在 Dart 侧分发', '$ctx: $timing');
    }
    final funcId = '${script}_$timing';
    if (!statusScriptFuncs.contains(funcId)) {
      err('状态回调函数缺失', '$ctx: StatusScript.$funcId');
    }
  }
}

/// filter / require 条件子表结构（'self' 占位仅在 filter/not 中合法）
void checkCriteria(Map data, String ctx) {
  void checkTable(Map table, String tableCtx, {required bool allowSelf}) {
    for (final entry in table.entries) {
      final key = entry.key;
      if (key == 'not') {
        if (entry.value is! Map) {
          err('条件子表结构非法', '$tableCtx.not: 期望表');
        } else if (tableCtx.endsWith('require')) {
          err('条件子表结构非法', '$tableCtx: require 不支持 not 反选');
        } else {
          checkTable(entry.value as Map, '$tableCtx.not', allowSelf: allowSelf);
        }
        continue;
      }
      if (!kFilterKeys.contains(key)) {
        err('条件子表字段未知', '$tableCtx: $key（允许: ${kFilterKeys.join('/')}）');
      }
      final value = entry.value;
      final valid = value is bool ||
          value is String ||
          (value is List && value.every((v) => v is String));
      if (!valid) {
        err('条件子表取值非法', '$tableCtx.$key: 期望 布尔/字符串/字符串列表');
      }
    }
  }

  if (data['filter'] is Map) {
    checkTable(data['filter'] as Map, '$ctx.filter', allowSelf: true);
  }
  if (data['require'] is Map) {
    checkTable(data['require'] as Map, '$ctx.require', allowSelf: false);
  }
}

// ---------------------------------------------------------------------------
// 各数据文件校验
// ---------------------------------------------------------------------------

void validateCards(Map<String, dynamic> cards) {
  for (final entry in cards.entries) {
    final key = entry.key;
    final ctx = 'cards.$key';
    final data = entry.value;
    if (data is! Map) {
      err('条目结构非法', '$ctx: 期望对象');
      continue;
    }

    checkId(data, key, ctx);
    checkLocaleKey(data['description'], '$ctx.description');

    // 类别与类型（isUnpackable 卡不进牌组/卡池，可缺省）
    if (data['category'] == null) {
      if (data['isUnpackable'] != true) {
        warn('卡牌缺 category', '$ctx: 占位卡合法，其余请确认');
      }
    } else {
      checkEnum(data['category'], kCategories, '$ctx.category');
    }
    if (data['category'] == 'attack' && data['damageType'] == null) {
      err('攻击卡缺 damageType', ctx);
    }
    checkEnum(data['damageType'], kDamageTypes, '$ctx.damageType');
    checkEnum(data['cardType'], kCardTypes, '$ctx.cardType');
    checkEnum(data['genre'], kGenres, '$ctx.genre');
    checkEnum(data['elementType'], kElementTypes, '$ctx.elementType');
    checkEnum(data['kind'], kCardKinds, '$ctx.kind', warnOnly: true);
    checkNumber(data['rank'], '$ctx.rank', min: 0, max: 5);

    // 费用：单资源模型，颜色键合法；值为数值或 {base, rankIncrement} 公式
    final cost = data['coloredCost'];
    if (cost == null) {
      warn('卡牌缺 coloredCost', '$ctx: 代码仅有兜底推导，应显式书写');
    } else if (cost is! Map) {
      err('字段类型非法', '$ctx.coloredCost: 期望表');
    } else {
      if (cost.length > 1) {
        warn('多色/混费卡', '$ctx: 单资源模型下仅作软警告');
      }
      for (final costEntry in cost.entries) {
        checkEnum(costEntry.key, kCostColors, '$ctx.coloredCost 颜色');
        final v = costEntry.value;
        if (v is num) continue;
        if (v is Map && v['base'] is num) {
          checkNumber(v['rankIncrement'], '$ctx.coloredCost.${costEntry.key}');
        } else {
          err('费用结构非法',
              '$ctx.coloredCost.${costEntry.key}: 期望数值或 {base, rankIncrement}');
        }
      }
    }

    // 绝世卡：固定词条列表与卡名本地化
    if (data['isUnique'] == true) {
      checkLocaleKey('uniquecard_$key', '$ctx 绝世卡名');
    }
    final affixes = data['affixes'];
    if (affixes is List) {
      for (final id in affixes) {
        if (id is! String || !affixIds.contains(id)) {
          err('悬空引用（额外词条不存在）', '$ctx.affixes: $id');
        }
      }
    }
    final uniqueIds = data['uniqueIds'];
    if (uniqueIds is List) {
      for (final id in uniqueIds) {
        if (id is! String || !affixUniqueIds.contains(id)) {
          err('悬空引用（词条 uniqueId 不存在）', '$ctx.uniqueIds: $id');
        }
      }
    }

    checkCardScript(data, ctx, isMainAffix: true);
    checkScriptContract(data, ctx);
    checkCommonRefs(data, ctx);
    checkKeywords(data, ctx);
    checkValueDataShape(data, ctx);
    checkValueDataPlaceholders(data, ctx);
    checkImageFile(data['image'], '$ctx.image');

    final animation = data['animation'];
    if (animation is Map) {
      for (final k in animation.keys) {
        if (!kAnimationKeys.contains(k)) {
          err('animation 字段未知', '$ctx.animation: $k');
        }
      }
    }
  }
}

void validateCardAffixes(Map<String, dynamic> affixes) {
  for (final entry in affixes.entries) {
    final key = entry.key;
    final ctx = 'card_affixes.$key';
    final data = entry.value;
    if (data is! Map) {
      err('条目结构非法', '$ctx: 期望对象');
      continue;
    }

    checkId(data, key, ctx);
    if (data['uniqueId'] == null) {
      err('词条缺 uniqueId', '$ctx: 同类互斥与去重依赖此字段');
    }
    checkLocaleKey(data['description'], '$ctx.description');

    final categories = data['categories'];
    if (categories is! List || categories.isEmpty) {
      err('词条缺 categories', '$ctx: 期望非空列表（attack/buff）');
    } else {
      for (final c in categories) {
        checkEnum(c, kCategories, '$ctx.categories');
      }
    }
    final genres = data['genres'];
    if (genres is List) {
      for (final g in genres) {
        checkEnum(g, kGenres, '$ctx.genres');
      }
    }
    checkNumber(data['rank'], '$ctx.rank', min: 0, max: 5);
    checkNumber(data['priority'], '$ctx.priority');
    checkEnum(data['attributeId'], kAttributeIds, '$ctx.attributeId',
        warnOnly: true);

    checkCardScript(data, ctx, isMainAffix: false);
    checkScriptContract(data, ctx);
    checkCommonRefs(data, ctx);
    checkKeywords(data, ctx);
    checkValueDataShape(data, ctx);
    checkValueDataPlaceholders(data, ctx);
    checkCriteria(data, ctx);
  }
}

void validatePassives(Map<String, dynamic> passives) {
  for (final entry in passives.entries) {
    final key = entry.key;
    final ctx = 'passives.$key';
    final data = entry.value;
    if (data is! Map) {
      err('条目结构非法', '$ctx: 期望对象');
      continue;
    }

    checkId(data, key, ctx);
    checkLocaleKey(data['description'], '$ctx.description');
    checkEnum(data['ephemeralType'], kEphemeralTypes, '$ctx.ephemeralType');
    checkNumber(data['rank'], '$ctx.rank', min: 0, max: 5);
    checkNumber(data['increment'], '$ctx.increment');
    checkNumber(data['base'], '$ctx.base');
    checkNumber(data['priority'], '$ctx.priority');
    checkNumber(data['turnStartScry'], '$ctx.turnStartScry', min: 1);

    checkStatusRef(data['battleStatus'], '$ctx.battleStatus');

    final shuffleIntoDeck = data['shuffleIntoDeck'];
    if (shuffleIntoDeck is List) {
      for (final id in shuffleIntoDeck) {
        if (id is! String || !cardIds.contains(id)) {
          err('悬空引用（卡牌不存在）', '$ctx.shuffleIntoDeck: $id');
        }
      }
    }

    final costReduction = data['deckCostReduction'];
    if (costReduction != null) {
      if (costReduction is! Map) {
        err('字段类型非法', '$ctx.deckCostReduction: 期望表');
      } else {
        // color 除单色外允许 'all'（命中卡首个费用条目，聚灵旗软流派锁）
        checkEnum(costReduction['color'], {...kCostColors, 'all'},
            '$ctx.deckCostReduction.color');
        // amount 为负即加费，可正可负
        checkNumber(costReduction['amount'], '$ctx.deckCostReduction.amount');
        for (final field in ['genres', 'notGenres']) {
          final genres = costReduction[field];
          if (genres is List) {
            for (final g in genres) {
              checkEnum(g, kGenres, '$ctx.deckCostReduction.$field');
            }
          }
        }
      }
    }

    // 回合结束资源保留（蓄灵佩）：{resourceId, max, costPerPoint?, costDamageType?}
    final energyRetain = data['energyRetain'];
    if (energyRetain != null) {
      if (energyRetain is! Map) {
        err('字段类型非法', '$ctx.energyRetain: 期望表');
      } else {
        checkStatusRef(
            energyRetain['resourceId'], '$ctx.energyRetain.resourceId');
        checkNumber(energyRetain['max'], '$ctx.energyRetain.max', min: 1);
        checkNumber(
            energyRetain['costPerPoint'], '$ctx.energyRetain.costPerPoint',
            min: 0);
        checkEnum(energyRetain['costDamageType'], kDamageTypes,
            '$ctx.energyRetain.costDamageType');
      }
    }

    // 回合开始额外抽牌（天机盘）：{count, costIncrease?: {amount, notGenres?}}
    final extraDraw = data['turnStartExtraDraw'];
    if (extraDraw != null) {
      if (extraDraw is! Map) {
        err('字段类型非法', '$ctx.turnStartExtraDraw: 期望表');
      } else {
        checkNumber(extraDraw['count'], '$ctx.turnStartExtraDraw.count',
            min: 1);
        final costIncrease = extraDraw['costIncrease'];
        if (costIncrease != null) {
          if (costIncrease is! Map) {
            err('字段类型非法', '$ctx.turnStartExtraDraw.costIncrease: 期望表');
          } else {
            checkNumber(costIncrease['amount'],
                '$ctx.turnStartExtraDraw.costIncrease.amount',
                min: 1);
            final notGenres = costIncrease['notGenres'];
            if (notGenres is List) {
              for (final g in notGenres) {
                checkEnum(g, kGenres,
                    '$ctx.turnStartExtraDraw.costIncrease.notGenres');
              }
            }
          }
        }
      }
    }

    // 通用 stats 直加（绝世装备主词条等固定词条）：{statsId: 数值}
    final statsBonus = data['statsBonus'];
    if (statsBonus != null) {
      if (statsBonus is! Map) {
        err('字段类型非法', '$ctx.statsBonus: 期望表');
      } else {
        for (final entry in statsBonus.entries) {
          checkNumber(entry.value, '$ctx.statsBonus.${entry.key}');
        }
      }
    }

    checkKeywords(data, ctx);
    checkImageFile(data['icon'], '$ctx.icon');
  }
}

/// items.json5 校验（createItemById 语义，见 scripts/main/data/item/item.ht）
void validateItems(Map<String, dynamic> items) {
  for (final entry in items.entries) {
    final key = entry.key;
    final ctx = 'items.$key';
    final data = entry.value;
    if (data is! Map) {
      err('条目结构非法', '$ctx: 期望对象');
      continue;
    }

    checkId(data, key, ctx);
    checkLocaleKey(data['name'], '$ctx.name');
    // isRankedName：名字按境界取 {name}{rank} 键（createItemById，rank 1~5）
    if (data['isRankedName'] == true && data['name'] is String) {
      for (var r = 1; r <= 5; ++r) {
        checkLocaleKey('${data['name']}$r', '$ctx 境界名(rank $r)');
      }
    }
    // flavortext：缺失仅提示；存在但本地化没有则报错
    if (data['flavortext'] == null) {
      warn('物品缺 flavortext', ctx);
    } else {
      checkLocaleKey(data['flavortext'], '$ctx.flavortext');
    }

    // type：字符串或字符串列表，值域见文件头注释
    final rawType = data['type'];
    final types = <String>[];
    if (rawType is String) {
      types.add(rawType);
    } else if (rawType is List) {
      types.addAll(rawType.whereType<String>());
    }
    if (types.isEmpty) {
      err('物品缺 type 或类型非法', '$ctx.type: $rawType');
    } else {
      for (final t in types) {
        if (!kItemTypes.contains(t)) {
          err('物品类型未知', '$ctx.type: $t（允许: ${kItemTypes.join('/')}）');
        }
      }
    }

    // equipment 的 category/kind 合法性（prototype 的 kind 缺省取 id，几乎必不合法）
    if (types.contains('equipment')) {
      final category = data['category'];
      if (!kEquipmentCategoryKinds.containsKey(category)) {
        err('装备类别未知', '$ctx.category: $category');
      } else {
        final kind = data['kind'];
        if (kind == null) {
          err('装备缺 kind', '$ctx: 缺省将取 id，不是合法装备 kind');
        } else if (!kEquipmentCategoryKinds[category]!.contains(kind)) {
          err('装备 kind 与类别不匹配', '$ctx: $category/$kind');
        }
      }
    }

    checkEnum(data['rarity'], kRarities, '$ctx.rarity');
    checkNumber(data['rank'], '$ctx.rank', min: 0, max: 5);
    checkNumber(data['level'], '$ctx.level', min: 0);
    checkNumber(data['price'], '$ctx.price', min: 0);
    checkNumber(data['stackSize'], '$ctx.stackSize', min: 1);

    // isRankedItem 的境界/稀有度在生成时推导（createItemById 先行分支），rarity 是死字段
    if (data['isRankedItem'] == true && data['rarity'] != null) {
      warn('isRankedItem 带有多余 rarity', '$ctx: 生成时按境界推导，rarity 不生效');
    }

    // 布尔标记类型检查；表外 is* 字段可能是拼写错误
    for (final field in data.keys) {
      if (field is String && field.startsWith('is')) {
        if (kItemFlags.contains(field)) {
          if (data[field] is! bool) {
            err('字段类型非法', '$ctx.$field: 期望布尔');
          }
        } else {
          warn('未知 is* 标记（可能拼写错误）', '$ctx.$field');
        }
      }
    }

    // 图标
    if (data['icon'] == null) {
      err('物品缺 icon', ctx);
    } else {
      checkImageFile(data['icon'], '$ctx.icon');
    }

    // 词条引用（固定词条为 passives.json5 的 id）
    final affixes = data['affixes'];
    if (affixes is List) {
      for (final id in affixes) {
        if (id is! String || !passiveIds.contains(id)) {
          err('悬空引用（被动词条不存在）', '$ctx.affixes: $id');
        }
      }
    }

    // 绝世装备约定（见 items.json5 模板注释）
    if (data['isUnique'] == true) {
      if (data['uniqueId'] != key) {
        err('绝世装备 uniqueId 必须等于键名', '$ctx: ${data['uniqueId']}');
      }
      if (data['isUnstackable'] != true) {
        err('绝世装备必须 isUnstackable: true', ctx);
      }
      if (data['isIdentified'] != false) {
        err('绝世装备必须 isIdentified: false（默认未鉴定）', ctx);
      }
      if (!types.contains('equipment')) {
        err('绝世装备 type 必须含 equipment', ctx);
      }
      if (data['rank'] == null) {
        err('绝世装备必须显式写 rank（rarity 会覆盖 rank 推导）', ctx);
      }
      if (affixes is! List || affixes.isEmpty) {
        err('绝世装备缺 affixes（第一个词条为主词条）', ctx);
      }
    }
  }
}

void validateStatusEffects(Map<String, dynamic> effects) {
  for (final entry in effects.entries) {
    final key = entry.key;
    final ctx = 'status_effect.$key';
    final data = entry.value;
    if (data is! Map) {
      err('条目结构非法', '$ctx: 期望对象');
      continue;
    }

    checkId(data, key, ctx);
    checkLocaleKey(data['title'], '$ctx.title');
    checkLocaleKey(data['description'], '$ctx.description');

    // 文件头注释约定：所有状态都必定有图标
    if (data['icon'] == null) {
      err('状态缺 icon', ctx);
    } else {
      checkImageFile(data['icon'], '$ctx.icon');
    }

    checkEnum(data['cardType'], kCardTypes, '$ctx.cardType');
    checkStatusScript(data, ctx);
    checkCommonRefs(data, ctx);
  }
}

// ---------------------------------------------------------------------------
// main
// ---------------------------------------------------------------------------

void main(List<String> arguments) {
  // 项目根目录：参数指定，或依次尝试当前目录/上级目录（支持从 utils/ 运行）
  root = arguments.isNotEmpty
      ? arguments.first
      : (FileSystemEntity.isDirectorySync('assets/data') ? '.' : '..');
  if (!FileSystemEntity.isDirectorySync(p.join(root, 'assets/data'))) {
    stderr.writeln('找不到项目根目录（assets/data 不存在），请通过参数指定。');
    exit(2);
  }

  print('项目根目录: ${p.absolute(root)}\n');

  // ---- 加载 ----
  final cards = loadJson5('assets/data/cards.json5');
  final affixes = loadJson5('assets/data/card_affixes.json5');
  final passives = loadJson5('assets/data/passives.json5');
  final effects = loadJson5('assets/data/status_effect.json5');
  final items = loadJson5('assets/data/items.json5');
  localeTexts = loadLocaleTexts();
  cardScriptFuncs =
      extractScriptFunctions('scripts/main/cardgame/card_script.ht');
  statusScriptFuncs =
      extractScriptFunctions('scripts/main/cardgame/status_script.ht');
  statusTimings = extractCallbackTimings(
    ['lib/scene/battle/character.dart', 'lib/scene/battle/battle.dart'],
    'handleStatusEffectCallback',
  );
  affixTimings = extractCallbackTimings(
    ['lib/scene/battle/battle.dart'],
    'handleCardAffixCallback',
  );

  cardIds = cards.keys.toSet();
  affixIds = affixes.keys.toSet();
  affixUniqueIds = {
    for (final data in affixes.values)
      if (data is Map && data['uniqueId'] is String) data['uniqueId'] as String,
  };
  statusIds = effects.keys.toSet();
  passiveIds = passives.keys.toSet();

  print('cards: ${cards.length}，affixes: ${affixes.length}，'
      'passives: ${passives.length}，status: ${effects.length}，items: ${items.length}');
  print('本地化键: ${localeTexts.length}，CardScript 函数: ${cardScriptFuncs.length}，'
      'StatusScript 函数: ${statusScriptFuncs.length}');
  print('状态时机: ${statusTimings.length}（${statusTimings.join(', ')}）');
  print('词条时机: ${affixTimings.join(', ')}\n');

  // ---- 校验 ----
  validateCards(cards);
  validateCardAffixes(affixes);
  validatePassives(passives);
  validateStatusEffects(effects);
  validateItems(items);

  // ---- 汇总输出 ----
  var errorCount = 0;
  if (_errors.isNotEmpty) {
    for (final section in _errors.keys) {
      final items = _errors[section]!;
      errorCount += items.length;
      print('[错误] $section（${items.length} 个）');
      for (final item in items) {
        print('  $item');
      }
      print('');
    }
  }
  var warningCount = 0;
  if (_warnings.isNotEmpty) {
    for (final section in _warnings.keys) {
      final items = _warnings[section]!;
      warningCount += items.length;
      print('[提示] $section（${items.length} 个）');
      for (final item in items) {
        print('  $item');
      }
      print('');
    }
  }

  print('----------------------------------------');
  if (errorCount > 0) {
    print('校验未通过: $errorCount 个错误，$warningCount 个提示。');
    exit(1);
  } else {
    print('校验通过，0 个错误，$warningCount 个提示。');
  }
}
