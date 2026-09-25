/// 天赋树（assets/data/passive_skills.json5）连通性校验工具
///
/// 用法:
///   dart run data_validate/passive_tree_validate.dart [数据文件路径]
///
/// 检查项:
///   1. 入口节点完整性: track_0_* 应为 5 个且均为 isOpen: true；
///      非入口节点不应带 isOpen（残留会导致绕过入口锁定）
///   2. 悬空引用: connectedNodes 指向不存在的节点（连线未完成时的占位）
///   3. 孤立节点: 已定义但没有任何连线（入口节点除外）
///   4. 不可达节点: 从入口节点出发，沿无向邻接无法到达的已定义节点
///   5. 重复边: 同一条边在两端各写了一次（无向语义下冗余但无害，仅提示）
///
/// 退出码: 以上 1~4 有任何问题则为 1，完全通过为 0（第 5 项不影响退出码）。
library;

import 'dart:io';

import 'package:json5/json5.dart';

/// 默认候选路径：依次支持从 utils/ 目录或项目根目录运行
const _kCandidatePaths = [
  '../assets/data/passive_skills.json5',
  'assets/data/passive_skills.json5',
];

final _kNodeIdPattern = RegExp(r'^track_(\d+)_(\d+)$');

/// 按 (轨道, 弧位) 数值排序节点 id
int _compareNodeIds(String a, String b) {
  final ma = _kNodeIdPattern.firstMatch(a);
  final mb = _kNodeIdPattern.firstMatch(b);
  if (ma == null || mb == null) return a.compareTo(b);
  final track = int.parse(ma.group(1)!).compareTo(int.parse(mb.group(1)!));
  if (track != 0) return track;
  return int.parse(ma.group(2)!).compareTo(int.parse(mb.group(2)!));
}

bool _isEntryNode(String nodeId) {
  final m = _kNodeIdPattern.firstMatch(nodeId);
  return m != null && m.group(1) == '0';
}

void main(List<String> arguments) {
  // ---- 读取数据文件 ----
  final String? path;
  if (arguments.isNotEmpty) {
    path = arguments.first;
  } else {
    path = _kCandidatePaths.where(FileSystemEntity.isFileSync).firstOrNull;
  }
  if (path == null || !FileSystemEntity.isFileSync(path)) {
    stderr.writeln('找不到数据文件，请通过参数指定 passive_skills.json5 的路径。');
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

  final nodes = parsed.keys.cast<String>().toSet();
  print('数据文件: $path');
  print('已定义节点: ${nodes.length} 个\n');

  // ---- 构建无向邻接表（每条边双向登记），同时记录书写方向 ----
  final adjacency = <String, Set<String>>{for (final id in nodes) id: {}};
  final writtenEdges = <String, Set<String>>{};

  for (final id in nodes) {
    final nodeData = parsed[id];
    if (nodeData is! Map) {
      stderr.writeln('节点数据必须是对象: $id');
      exit(2);
    }
    final List? connected = nodeData['connectedNodes'] as List?;
    if (connected == null) continue;
    for (final other in connected.cast<String>()) {
      adjacency[id]!.add(other);
      if (nodes.contains(other)) {
        adjacency[other]!.add(id);
      }
      writtenEdges.putIfAbsent(id, () => {}).add(other);
    }
  }

  var hasProblem = false;

  void reportSection(String title, List<String> items, {String? hint}) {
    if (items.isEmpty) return;
    hasProblem = true;
    print('[$title] ${items.length} 个');
    if (hint != null) print('  提示: $hint');
    for (final item in items) {
      print('  $item');
    }
    print('');
  }

  // ---- 1. 入口节点完整性 ----
  final entries = nodes.where(_isEntryNode).toList()..sort(_compareNodeIds);
  if (entries.length != 5) {
    hasProblem = true;
    print('[入口节点数量异常] 期望 5 个 track_0_* 节点，实际 ${entries.length} 个: '
        '$entries\n');
  }
  final entriesNotOpen =
      entries.where((id) => parsed[id]['isOpen'] != true).toList();
  reportSection('入口节点缺少 isOpen: true', entriesNotOpen,
      hint: '入口节点必须显式开放，否则新角色无法开始加点');

  final strayOpen = nodes
      .where((id) => !_isEntryNode(id) && parsed[id]['isOpen'] == true)
      .toList()
    ..sort(_compareNodeIds);
  reportSection('非入口节点带有多余的 isOpen: true', strayOpen,
      hint: '会导致不选入口即可直接加点，并可能使五个入口被永久锁定');

  // ---- 2. 悬空引用 ----
  final dangling = <String>[];
  for (final id in nodes) {
    final missing = (writtenEdges[id] ?? const <String>{})
        .where((other) => !nodes.contains(other))
        .toList()
      ..sort(_compareNodeIds);
    for (final other in missing) {
      dangling.add('$id -> $other');
    }
  }
  reportSection('悬空引用（connectedNodes 指向不存在的节点）', dangling,
      hint: '多为尚未定义的在制节点，补写节点数据后消除');

  // ---- 3. 孤立节点（入口除外） ----
  final isolated = nodes
      .where((id) => !_isEntryNode(id) && adjacency[id]!.isEmpty)
      .toList()
    ..sort(_compareNodeIds);
  reportSection('孤立节点（没有任何连线）', isolated,
      hint: '既不连出也不被任何节点引用，玩家永远无法到达');

  // ---- 4. 不可达节点（从全部入口无向遍历） ----
  final visited = <String>{};
  final stack = [...entries];
  while (stack.isNotEmpty) {
    final current = stack.removeLast();
    if (!visited.add(current)) continue;
    for (final adj in adjacency[current]!) {
      if (nodes.contains(adj)) stack.add(adj);
    }
  }
  final unreachable = nodes.difference(visited).toList()..sort(_compareNodeIds);
  reportSection('不可达节点（从入口出发无法到达）', unreachable,
      hint: '需要补写连线将其接入天赋树');

  // ---- 5. 重复边（仅提示，不影响退出码） ----
  final duplicated = <String>{};
  for (final id in nodes) {
    for (final other in writtenEdges[id] ?? const <String>{}) {
      if (writtenEdges[other]?.contains(id) == true) {
        final pair = [id, other]..sort(_compareNodeIds);
        duplicated.add('${pair[0]} <-> ${pair[1]}');
      }
    }
  }
  if (duplicated.isNotEmpty) {
    print('[重复边（仅提示）] ${duplicated.length} 条');
    print('  提示: 无向语义下一条边只需在一端写一次，另一端可删掉重复项');
    for (final pair in duplicated) {
      print('  $pair');
    }
    print('');
  }

  // ---- 汇总 ----
  final edgeCount =
      adjacency.values.fold<int>(0, (sum, set) => sum + set.length) ~/ 2;
  print('----------------------------------------');
  print('无向边总数: $edgeCount，入口可达节点: ${visited.length}/${nodes.length}');
  if (hasProblem) {
    print('校验未通过。');
    exit(1);
  } else {
    print('校验通过，未发现连通性问题。');
  }
}
