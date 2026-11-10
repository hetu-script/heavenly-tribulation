import 'dart:io';

import 'package:json5/json5.dart';
import 'package:path/path.dart' as p;

List<String> validateDungeonData(String root, Map<String, String> localeTexts) {
  final errors = <String>[];
  final scenes = _loadObject(root, 'assets/data/dungeon_scenes.json5');
  final routes = _loadObject(root, 'assets/data/dungeon_routes.json5');
  const battleKinds = {'battle', 'elite', 'boss'};
  const merchantKinds = {'smith', 'enchanter', 'pharmacist', 'bookDealer'};

  for (final entry in scenes.entries) {
    final id = entry.key;
    final data = entry.value;
    if (data is! Map) {
      errors.add('dungeon_scenes.$id: 条目必须是对象');
      continue;
    }
    if (data['id'] != id) {
      errors.add('dungeon_scenes.$id: id 与键名不一致');
    }
    for (final field in ['title', 'description']) {
      final key = data[field];
      if (key is! String || !localeTexts.containsKey(key)) {
        errors.add('dungeon_scenes.$id.$field: 本地化键不存在');
      }
    }
    final background = data['background'];
    if (background is! String ||
        !File(p.join(root, 'assets/images', background)).existsSync()) {
      errors.add('dungeon_scenes.$id.background: 图片不存在');
    }
    final kind = data['kind'];
    if (!{'battle', 'elite', 'boss', 'merchant', 'rest'}.contains(kind)) {
      errors.add('dungeon_scenes.$id.kind: 未知类型 $kind');
      continue;
    }
    if (battleKinds.contains(kind)) {
      final enemy = data['enemy'];
      if (enemy is! Map || enemy['levelBonus'] is! num) {
        errors.add('dungeon_scenes.$id.enemy: 战斗房间需要 levelBonus');
      }
      if (data['reward'] is! Map) {
        errors.add('dungeon_scenes.$id.reward: 战斗房间需要奖励配置');
      }
    }
    if (kind == 'merchant') {
      final merchant = data['merchant'];
      final kinds = merchant is Map ? merchant['kinds'] : null;
      if (kinds is! List || kinds.isEmpty) {
        errors.add('dungeon_scenes.$id.merchant.kinds: 商人池不能为空');
      } else {
        for (final merchantKind in kinds) {
          if (!merchantKinds.contains(merchantKind)) {
            errors
                .add('dungeon_scenes.$id.merchant.kinds: 未知商人类型 $merchantKind');
          }
        }
      }
    }
    if (kind == 'rest') {
      final actions = data['actions'];
      if (actions is! List ||
          !actions
              .any((action) => action is Map && action['kind'] == 'restore')) {
        errors.add('dungeon_scenes.$id.actions: 休息房间需要 restore 动作');
      }
    }
  }

  for (final entry in routes.entries) {
    final id = entry.key;
    final data = entry.value;
    if (data is! Map || data['id'] != id) {
      errors.add('dungeon_routes.$id: id 与键名不一致或结构非法');
      continue;
    }
    final sceneIds = data['sceneIds'];
    if (sceneIds is! List || sceneIds.isEmpty) {
      errors.add('dungeon_routes.$id.sceneIds: 路线不能为空');
      continue;
    }
    for (final sceneId in sceneIds) {
      if (!scenes.containsKey(sceneId)) {
        errors.add('dungeon_routes.$id.sceneIds: 不存在的场景 $sceneId');
      }
    }
  }
  return errors;
}

Map<String, dynamic> _loadObject(String root, String relativePath) {
  final path = p.join(root, relativePath);
  if (!File(path).existsSync()) {
    throw StateError('找不到秘境数据文件: $path');
  }
  final data = JSON5.parse(File(path).readAsStringSync());
  if (data is! Map) {
    throw StateError('秘境数据顶层必须是对象: $path');
  }
  return data.cast<String, dynamic>();
}
