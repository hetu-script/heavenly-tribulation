import 'dart:async';
import 'dart:math' as math;

import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
// import 'package:quiver/iterables.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
// import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flame/flame.dart';
import 'package:samsara/components/ui/sprite_button.dart';
import 'package:flame/components.dart';
import 'package:samsara/effect/confetti.dart';
import 'package:samsara/components/sprite_component2.dart';

import '../../../global.dart';
import '../../../ui.dart';
import '../../cursor_state.dart';
import '../../common.dart';
import '../../../data/game.dart';
import '../common.dart';

const _kLayerPriority = [30, 20, 10];

const _kStackedTileCount = 18; // 每个堆叠位置的方块数量

// 堆叠方块配置
const _kStackOffsetY = 9.0; // 每个堆叠方块的Y轴偏移量（像素）

/// 匹配成功的碎片效果
class MatchParticle extends PositionComponent {
  static final _random = math.Random();
  final Vector2 velocity;
  final double rotationSpeed;
  final Color color;
  final Paint _paint;
  double _rotation = 0;
  double _lifetime = 0;
  static const _maxLifetime = 1.0;
  static const _gravity = 500.0;

  MatchParticle({
    required super.position,
    required this.velocity,
    required this.color,
    required super.size,
  })  : rotationSpeed = _random.nextDouble() * 10 - 5,
        _paint = Paint()
          ..color = color
          ..style = PaintingStyle.fill;

  @override
  void update(double dt) {
    super.update(dt);
    _lifetime += dt;
    velocity.y += _gravity * dt;
    position += velocity * dt;
    _rotation += rotationSpeed * dt;

    if (_lifetime > _maxLifetime * 0.5) {
      final fadeProgress =
          (_lifetime - _maxLifetime * 0.5) / (_maxLifetime * 0.5);
      _paint.color = color.withAlpha((255 * (1 - fadeProgress)).toInt());
    }

    if (_lifetime > _maxLifetime) {
      removeFromParent();
    }
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.translate(width / 2, height / 2);
    canvas.rotate(_rotation);
    canvas.drawRect(
      Rect.fromCenter(center: Offset.zero, width: width, height: height),
      _paint,
    );
    canvas.restore();
  }
}

/// 匹配成功的碎片爆炸效果
class MatchCelebration extends PositionComponent {
  static final _random = math.Random();
  static final _colors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFE66D),
    Color(0xFF95E1D3),
    Color(0xFFF38181),
    Color(0xFFAA96DA),
  ];

  MatchCelebration({
    required super.position,
    required super.size,
  });

  @override
  void onMount() {
    super.onMount();
    _createParticles();
  }

  void _createParticles() {
    // 在方块位置创建15个小碎片
    for (int i = 0; i < 15; i++) {
      final color = _colors[_random.nextInt(_colors.length)];
      final angle = _random.nextDouble() * math.pi * 2;
      final speed = 100 + _random.nextDouble() * 150;

      final particle = MatchParticle(
        position: Vector2(width / 2, height / 2),
        velocity: Vector2(
          math.cos(angle) * speed,
          math.sin(angle) * speed - 100, // 向上偏移
        ),
        color: color,
        size: Vector2.all(3 + _random.nextDouble() * 5),
      );
      add(particle);
    }
  }
}

/// 表示一个可点击的方块
class MatchingTile extends GameComponent with HandlesGesture {
  final int iconId; // 图标ID
  final int layer; // 层级 (0-2, 0是最上层)
  final int gridX; // 网格X坐标
  final int gridY; // 网格Y坐标
  final bool isStacked; // 是否是堆叠方块
  final int stackIndex; // 在堆叠中的索引（0是最底部，越大越靠上）

  bool isSelected = false; // 是否已被选中移除
  bool isInSlot = false; // 是否已在槽位中

  bool _isBlocked = false; // 是否被遮挡
  bool get isBlocked => _isBlocked;
  set isBlocked(bool value) {
    if (_isBlocked != value) {
      _isBlocked = value;
      updatePaintState();
    }
  }

  bool _isMatched = false; // 是否已配对消除
  bool get isMatched => _isMatched;
  set isMatched(bool value) {
    if (_isMatched != value) {
      _isMatched = value;
      updatePaintState();
    }
  }

  late SpriteComponent background;
  late SpriteComponent icon;

  final Paint darkenPaint = Paint()
    ..colorFilter = const ColorFilter.mode(
      Colors.black38, // 60% 黑色遮罩
      BlendMode.srcATop,
    );

  final Paint hoverTintPaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..colorFilter = PresetFilters.brightness(0.3);

  MatchingTile({
    required this.iconId,
    required this.layer,
    required this.gridX,
    required this.gridY,
    this.isStacked = false,
    this.stackIndex = 0,
    required Sprite tileSprite,
    required Sprite iconSprite,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          anchor: Anchor.topLeft,
          priority: _kLayerPriority[layer],
        ) {
    enableGesture = true;

    // 背景
    background = SpriteComponent(
      sprite: tileSprite,
      size: size,
      anchor: Anchor.topLeft,
    );
    add(background);

    // 图标
    icon = SpriteComponent(
      sprite: iconSprite,
      size: size,
      anchor: Anchor.topLeft,
    );
    add(icon);
  }

  /// 更新亮暗状态
  void updatePaintState() {
    if (isBlocked && layer > 0) {
      // 被遮挡且不是最上层，变暗
      background.paint = darkenPaint;
      icon.paint = darkenPaint;
    } else if (isMatched || (isHovering && !isBlocked && !isSelected)) {
      // 鼠标悬停，变亮
      background.paint = hoverTintPaint;
      icon.paint = hoverTintPaint;
    } else {
      // 恢复正常
      background.paint = paint;
      icon.paint = paint;
    }
  }

  /// 检查此方块是否遮挡另一个方块
  bool blocksOther(MatchingTile other) {
    // 只有上层才能遮挡下层
    if (layer >= other.layer) return false;

    // 基于网格位置判断遮挡关系
    // 第1层和第3层对齐网格，第2层有半格错位

    if (layer == 0 && other.layer == 1) {
      // 第1层遮挡第2层: 第1层(x,y)遮挡第2层(x,y)和相邻格子
      // 由于第2层有半格错位，第1层(x,y)会遮挡第2层(x,y), (x-1,y), (x,y-1), (x-1,y-1)
      return (gridX == other.gridX || gridX == other.gridX + 1) &&
          (gridY == other.gridY || gridY == other.gridY + 1);
    } else if (layer == 0 && other.layer == 2) {
      // 第1层遮挡第3层: 相同网格位置
      return gridX == other.gridX && gridY == other.gridY;
    } else if (layer == 1 && other.layer == 2) {
      // 第2层遮挡第3层: 第2层(x,y)由于半格错位，会遮挡第3层(x,y), (x+1,y), (x,y+1), (x+1,y+1)
      return (other.gridX == gridX || other.gridX == gridX + 1) &&
          (other.gridY == gridY || other.gridY == gridY + 1);
    }

    return false;
  }
}

class MatchingGame2 extends Scene with HasCursorState {
  // 层级偏移（第2层有半格错位）
  static final layer2Offset = GameUI.matchingTileSize / 2; // 半个格子

  // final fluent.FlyoutController _menuController = fluent.FlyoutController();

  late final SpriteSheet iconSpriteSheet;

  late Vector2 scaleFactor;
  late Vector2 tileSize;

  // 游戏状态
  final List<MatchingTile> boardTiles = [];
  final List<MatchingTile> slotTiles = []; // 槽位中的方块

  late MiniGameDifficulty difficulty;
  late int tileCount; // 方块总数

  late int maxSlots; // 槽位上限
  late int iconTypes; // 图标种类

  late int normalTileCount; // 普通方块数量
  late int stackPositions; // 堆叠位置数量
  late List<Map<String, int>> stackGridPositions; // 堆叠位置坐标

  late List<int> _layerCounts; // 每层的方块数量 [第1层, 第2层, 第3层]

  bool isGameOver = false;
  bool isGameWon = false;

  MatchingTile? _hoveringTile;

  late final SpriteComponent victoryPrompt, defeatPrompt;

  late final SpriteButton restart, exit;

  late final SpriteComponent2 barrier;

  FutureOr<void> Function()? onGameStart;
  FutureOr<dynamic> Function(bool won)? onGameEnd;

  MatchingGame2({
    required this.difficulty,
    this.onGameStart,
    this.onGameEnd,
  }) : super(
          id: Scenes.matchingGame2,
          bgm: engine.bgm,
          bgmFile: 'ghuzheng-fantasie-23506.mp3',
          bgmVolume: 0.5,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    barrier = SpriteComponent2(
      size: size,
      color: GameUI.barrierColor,
      priority: 10000,
      isVisible: false,
    );
    world.add(barrier);

    victoryPrompt = SpriteComponent(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: await Sprite.load('ui/victory.png'),
      size: Vector2(480.0, 240.0),
    );
    defeatPrompt = SpriteComponent(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: await Sprite.load('ui/defeat.png'),
      size: Vector2(480.0, 240.0),
    );

    restart = SpriteButton(
      spriteId: 'ui/button2.png',
      size: GameUI.buttonSizeMedium,
      anchor: Anchor.center,
      position: GameUI.restartButtonPosition,
      text: engine.locale('restart'),
    );
    restart.onTap = (_, __) {
      _initializeGame();
    };
    restart.isVisible = engine.config.developMode;
    camera.viewport.add(restart);

    exit = SpriteButton(
      spriteId: 'ui/button1.png',
      size: GameUI.buttonSizeMedium,
      anchor: Anchor.center,
      position: GameUI.exitButtonPosition,
      text: engine.locale('exit'),
    );
    exit.onTap = (_, __) {
      _endScene(isGameWon);
    };
    camera.viewport.add(exit);

    scaleFactor = Vector2(
        size.x / defaultGameSize.width, size.y / defaultGameSize.height);
    tileSize = Vector2(GameUI.matchingTileSize.x * scaleFactor.x,
        GameUI.matchingTileSize.y * scaleFactor.y);

    iconSpriteSheet = SpriteSheet(
      image: await Flame.images.load('mini_game/matching/icon.png'),
      srcSize: Vector2(81, 81),
    );

    final board = SpriteComponent(
      sprite: await Sprite.load('mini_game/matching/board2.png'),
      size: size,
    );
    world.add(board);

    // 初始化游戏
    await _initializeGame();
  }

  /// 初始化游戏 - 生成方块
  Future<void> _initializeGame() async {
    engine.bgm.resume();

    restart.position = GameUI.restartButtonPosition;
    exit.position = GameUI.exitButtonPosition;

    isGameOver = false;
    barrier.isVisible = false;

    final List<int> iconIds = [];

    victoryPrompt.removeFromParent();
    defeatPrompt.removeFromParent();

    restart.isVisible = engine.config.developMode;

    // 移除所有旧方块
    for (var tile in boardTiles) {
      tile.removeFromParent();
    }
    for (var tile in slotTiles) {
      tile.removeFromParent();
    }

    boardTiles.clear();
    slotTiles.clear();

    maxSlots = 7;
    switch (difficulty) {
      case MiniGameDifficulty.easy:
        iconTypes = 8;
        tileCount = iconTypes * 3;
        stackPositions = 0;
        stackGridPositions = [];
      case MiniGameDifficulty.normal:
        iconTypes = 12;
        tileCount = iconTypes * 3;
        stackPositions = 0;
        stackGridPositions = [];
      case MiniGameDifficulty.challenging:
        iconTypes = 12;
        tileCount = iconTypes * 6;
        stackPositions = 0;
        stackGridPositions = [];
      case MiniGameDifficulty.hard:
        iconTypes = 12;
        tileCount = iconTypes * 6;
        stackPositions = 1;
        stackGridPositions = [
          {'x': 5, 'y': 4}, // 中心堆叠
        ];
      case MiniGameDifficulty.tough:
        iconTypes = 12;
        tileCount = iconTypes * 9;
        stackPositions = 2;
        stackGridPositions = [
          {'x': 4, 'y': 4}, // 左侧堆叠
          {'x': 6, 'y': 4}, // 右侧堆叠
        ];
      case MiniGameDifficulty.brutal:
        iconTypes = 12;
        tileCount = iconTypes * 12;
        stackPositions = 2;
        stackGridPositions = [
          {'x': 4, 'y': 4}, // 左侧堆叠
          {'x': 6, 'y': 4}, // 右侧堆叠
        ];
    }
    normalTileCount = tileCount - (_kStackedTileCount * stackPositions);

    // 为每种图标分配数量（必须能被3整除以支持三消）
    final countPerIcon = tileCount ~/ iconTypes;
    assert(countPerIcon % 3 == 0,
        '方块数必须是3的整数倍，以支持三消。当前配置: tileCount=$tileCount, iconTypes=$iconTypes');

    // ===== 第一步: 生成堆叠方块 =====
    final totalStackedCount = _kStackedTileCount * stackPositions;
    final stackedIconIds = <int>[];
    for (int i = 0; i < totalStackedCount; i++) {
      stackedIconIds.add(i % iconTypes);
    }
    stackedIconIds.shuffle(random);

    // 为每个堆叠位置创建方块
    for (int stackPos = 0; stackPos < stackPositions; stackPos++) {
      final stackGridX = stackGridPositions[stackPos]['x']!;
      final stackGridY = stackGridPositions[stackPos]['y']!;

      // 创建该堆叠位置的方块（从底部到顶部）
      for (int i = 0; i < _kStackedTileCount; i++) {
        final iconId = stackPos * _kStackedTileCount + i;
        final tile = await _createTile(
          stackedIconIds[iconId],
          2, // 使用第3层（最下层）
          stackGridX,
          stackGridY,
          isStacked: true,
          stackIndex: i,
        );
        boardTiles.add(tile);
        world.add(tile);
        iconIds.add(stackedIconIds[iconId]);
      }
    }

    // ===== 第二步: 生成普通方块 =====
    // 根据剩余方块总数自动计算每层的数量
    _layerCounts = _calculateLayerDistribution(normalTileCount);

    // 计算剩余需要分配的图标（总数 - 已用于堆叠的）
    final remainingIconCounts = List.filled(iconTypes, countPerIcon);
    for (var id in stackedIconIds) {
      remainingIconCounts[id]--;
    }

    // 将所有剩余图标ID收集到一个列表中
    final allRemainingIcons = <int>[];
    for (int iconId = 0; iconId < iconTypes; iconId++) {
      for (int i = 0; i < remainingIconCounts[iconId]; i++) {
        allRemainingIcons.add(iconId);
      }
    }

    // 打乱所有图标
    allRemainingIcons.shuffle(random);

    // 按层分配: 直接按顺序分配到3层
    final layerAssignments = <List<int>>[
      allRemainingIcons.sublist(0, _layerCounts[0]),
      allRemainingIcons.sublist(
          _layerCounts[0], _layerCounts[0] + _layerCounts[1]),
      allRemainingIcons.sublist(_layerCounts[0] + _layerCounts[1]),
    ];

    // 生成位置（只生成一次）
    final positions = _generateLayerPositions(normalTileCount);

    // 验证: 确保生成的位置数量正确
    assert(positions.length == normalTileCount,
        '位置数量错误: 期望$normalTileCount个，实际${positions.length}个');

    // 验证: 确保每层的位置数量与分配的图标数量匹配
    for (int layer = 0; layer < 3; layer++) {
      final layerPositionCount =
          positions.where((p) => p['layer'] == layer).length;
      assert(layerPositionCount == layerAssignments[layer].length,
          '第${layer + 1}层位置数量($layerPositionCount)与图标分配数量(${layerAssignments[layer].length})不匹配');
    }

    // 按位置顺序创建普通方块，使用对应层的图标
    final layerIndices = [0, 0, 0]; // 每层当前使用的图标索引

    for (int i = 0; i < positions.length; i++) {
      final pos = positions[i];
      final layer = pos['layer'] as int;
      final iconId = layerAssignments[layer][layerIndices[layer]];
      iconIds.add(iconId);
      layerIndices[layer]++;

      final tile = await _createTile(
        iconId,
        layer,
        pos['x'] as int,
        pos['y'] as int,
      );
      boardTiles.add(tile);
      world.add(tile);
    }

    // 最终验证: 统计每种图标的数量
    final iconCounts = List.filled(iconTypes, 0);
    for (var id in iconIds) {
      iconCounts[id]++;
    }
    for (int i = 0; i < iconTypes; i++) {
      assert(iconCounts[i] == countPerIcon,
          '图标$i数量错误: 期望$countPerIcon个，实际${iconCounts[i]}个');
    }

    // 更新遮挡状态
    _updateBlockedStates();

    // 输出初始状态
    // debugPrint('=== 游戏初始化完成 ===');
    // for (int layer = 0; layer < 3; layer++) {
    //   final layerTiles = allTiles.where((t) => t.layer == layer);
    //   final unblockedTiles = layerTiles.where((t) => !t.isBlocked);
    //   debugPrint(
    //       '第${layer + 1}层: 总数=${layerTiles.length}, 可点击=${unblockedTiles.length}');
    // }

    await onGameStart?.call();
  }

  /// 根据方块总数自动计算每层的分配数量
  /// 分配比例: 第1层25%，第2层25%，第3层50%
  List<int> _calculateLayerDistribution(int totalCount) {
    final layer1Count = (totalCount * 0.25).round();
    final layer2Count = (totalCount * 0.25).round();
    final layer3Count = totalCount - layer1Count - layer2Count; // 确保总和正确

    return [layer1Count, layer2Count, layer3Count];
  }

  /// 检查指定位置是否在排除区域内
  /// 不同难度使用不同的排除策略:
  /// - 简单: 无排除
  /// - 中等: 曼哈顿距离 ≤ 3 的菱形排除（原始行为）
  /// - 困难: 棋盘中心 3×3 矩形排除
  bool _isPositionExcluded(int x, int y, int layer) {
    // 棋盘中心
    final centerX = GameUI.matchingBoardGridWidth ~/ 2; // 5
    final centerY = GameUI.matchingBoardGridHeight ~/ 2; // 3

    switch (difficulty) {
      case MiniGameDifficulty.easy:
      case MiniGameDifficulty.normal:
        // 无堆叠，不排除
        return false;
      case MiniGameDifficulty.challenging:
      case MiniGameDifficulty.hard:
        // 曼哈顿距离 ≤ 3 的菱形排除
        const radius = 3;
        if (layer == 1) {
          // Layer 1 有半格偏移，(x,y) 覆盖 Layer 0/2 的 (x,y),(x+1,y),(x,y+1),(x+1,y+1)
          return _manhattanExcluded(x, y, centerX, centerY, radius) ||
              _manhattanExcluded(x + 1, y, centerX, centerY, radius) ||
              _manhattanExcluded(x, y + 1, centerX, centerY, radius) ||
              _manhattanExcluded(x + 1, y + 1, centerX, centerY, radius);
        }
        return _manhattanExcluded(x, y, centerX, centerY, radius);

      case MiniGameDifficulty.tough:
      case MiniGameDifficulty.brutal:
        // 中心 3×3 矩形排除: x∈[4,6], y∈[2,4]
        const minX = 4, maxX = 6, minY = 2, maxY = 4;
        if (layer == 1) {
          // Layer 1 有半格偏移，检查所有覆盖位置
          return _rectExcluded(x, y, minX, minY, maxX, maxY) ||
              _rectExcluded(x + 1, y, minX, minY, maxX, maxY) ||
              _rectExcluded(x, y + 1, minX, minY, maxX, maxY) ||
              _rectExcluded(x + 1, y + 1, minX, minY, maxX, maxY);
        }
        return _rectExcluded(x, y, minX, minY, maxX, maxY);
    }
  }

  static bool _manhattanExcluded(int x, int y, int cx, int cy, int radius) {
    return (x - cx).abs() + (y - cy).abs() <= radius;
  }

  static bool _rectExcluded(
      int x, int y, int minX, int minY, int maxX, int maxY) {
    return x >= minX && x <= maxX && y >= minY && y <= maxY;
  }

  /// 生成方块的位置（第一层少，第二三层多）
  List<Map<String, int>> _generateLayerPositions(int totalCount) {
    final positions = <Map<String, int>>[];

    // 使用计算出的层分配数量
    // layerCounts[0] = 第1层(最上层, layer=0)
    // layerCounts[1] = 第2层(layer=1)
    // layerCounts[2] = 第3层(最下层, layer=2)
    final layer1Count = _layerCounts[0];
    final layer2Count = _layerCounts[1];
    final layer3Count = _layerCounts[2];

    // 按层顺序生成，保证 layerAssignments 和 positions 的对应关系

    // 第1层（最上层, layer=0）
    final layer1Positions = _generateRandomPositions(
      layer1Count,
      GameUI.matchingBoardGridWidth,
      GameUI.matchingBoardGridHeight,
      layer: 0,
    );
    for (var pos in layer1Positions) {
      positions.add({'layer': 0, 'x': pos['x']!, 'y': pos['y']!});
    }

    // 第2层（layer=1，有半格错位）
    final layer2Positions = _generateRandomPositions(
      layer2Count,
      GameUI.matchingBoardGridWidth - 1,
      GameUI.matchingBoardGridHeight - 1,
      layer: 1,
    );
    for (var pos in layer2Positions) {
      positions.add({'layer': 1, 'x': pos['x']!, 'y': pos['y']!});
    }

    // 第3层（最下层, layer=2）
    final layer3Positions = _generateRandomPositions(
      layer3Count,
      GameUI.matchingBoardGridWidth,
      GameUI.matchingBoardGridHeight,
      layer: 2,
    );
    for (var pos in layer3Positions) {
      positions.add({'layer': 2, 'x': pos['x']!, 'y': pos['y']!});
    }

    return positions;
  }

  /// 生成不重复的随机位置
  List<Map<String, int>> _generateRandomPositions(
    int count,
    int maxX,
    int maxY, {
    int layer = 0,
  }) {
    final positions = <Map<String, int>>[];
    final used = <String>{};

    // 添加安全计数器，防止死循环
    int attempts = 0;
    final maxAttempts = (maxX * maxY) * 10; // 最多尝试次数

    while (positions.length < count) {
      attempts++;
      if (attempts > maxAttempts) {
        engine.error('警告: 第${layer + 1}层位置生成失败，'
            '需要$count个位置，只找到${positions.length}个。'
            '网格大小: ${maxX}x$maxY');
        break;
      }

      final x = random.nextInt(maxX);
      final y = random.nextInt(maxY);
      final key = '$x,$y';

      if (used.contains(key)) {
        continue;
      }

      if (_isPositionExcluded(x, y, layer)) {
        continue;
      }

      used.add(key);
      positions.add({'x': x, 'y': y});
    }

    return positions;
  }

  /// 创建一个方块
  Future<MatchingTile> _createTile(
    int iconId,
    int layer,
    int gridX,
    int gridY, {
    bool isStacked = false,
    int stackIndex = 0,
  }) async {
    // 从spritesheet获取图标
    // 使用第4列和第5列（索引3和4），每列取前6个图标
    // iconId 0-5: 第4列（索引3）
    // iconId 6-11: 第5列（索引4）
    int spriteId;
    if (iconId < 6) {
      // 第5列（索引4）
      spriteId = iconId * 6 + 4;
    } else {
      // 第6列（索引5）
      spriteId = (iconId - 6) * 6 + 5;
    }
    final iconSprite = iconSpriteSheet.getSpriteById(spriteId);

    // 加载背景图
    final tileSprite = await Sprite.load('mini_game/matching/tile.png');

    // 计算位置
    Vector2 position = GameUI.matchingBoardOffset.clone();
    position.x += gridX * GameUI.matchingTileSize.x;
    position.y += gridY * GameUI.matchingTileSize.y;

    // 第2层有半格错位
    if (layer == 1 && !isStacked) {
      position += layer2Offset;
    }

    // 堆叠方块的特殊处理: stackIndex=0在底部(gridY=4)，越大越往上
    if (isStacked) {
      // 直接从底部位置向上偏移
      position.y -= stackIndex * _kStackOffsetY;
    }

    // 应用缩放
    position.x *= scaleFactor.x;
    position.y *= scaleFactor.y;

    // 堆叠方块使用更高的优先级（索引越大，越靠上）
    final priority = isStacked ? (100 + stackIndex) : _kLayerPriority[layer];

    final tile = MatchingTile(
      iconId: iconId,
      layer: layer,
      gridX: gridX,
      gridY: gridY,
      isStacked: isStacked,
      stackIndex: stackIndex,
      tileSprite: tileSprite,
      iconSprite: iconSprite,
      position: position,
      size: tileSize,
    )..priority = priority;

    tile.onTap = (button, position) {
      if (tile.isBlocked || tile.isSelected || tile.isInSlot) return;
      _onTileTapped(tile);
    };
    tile.onMouseEnter = () {
      // debugPrint('鼠标进入方块: Layer=$layer, Grid=($gridX,$gridY), IconId=$iconId');
      tile.updatePaintState();
      if (tile.isBlocked || tile.isSelected || tile.isInSlot) return;
      _hoveringTile = tile;
      cursorState = MouseCursorState.click;
    };
    tile.onMouseExit = () {
      tile.updatePaintState();
      if (_hoveringTile == tile) {
        _hoveringTile = null;
        cursorState = MouseCursorState.normal;
      }
    };

    return tile;
  }

  /// 获取槽位中第index个方块的位置
  Vector2 _getSlotPosition(int index) {
    // 计算位置
    final pos = Vector2(
      GameUI.matchingSlotOffset.x * scaleFactor.x,
      (GameUI.matchingSlotOffset.y + index * GameUI.matchingTileSize.y + 10) *
          scaleFactor.y,
    );

    return pos;
  }

  /// 更新所有方块的遮挡状态
  void _updateBlockedStates() {
    // 先重置所有状态
    for (var tile in boardTiles) {
      tile.isBlocked = false;
    }

    // 检查堆叠方块的遮挡关系
    final stackedTiles =
        boardTiles.where((t) => t.isStacked && !t.isSelected).toList();
    if (stackedTiles.isNotEmpty) {
      // 按堆叠位置分组
      for (int stackPos = 0; stackPos < stackPositions; stackPos++) {
        final stackGridX = stackGridPositions[stackPos]['x']!;
        final stackGridY = stackGridPositions[stackPos]['y']!;

        // 获取该堆叠位置的所有方块
        final stackTilesAtPos = stackedTiles
            .where((t) => t.gridX == stackGridX && t.gridY == stackGridY)
            .toList();

        if (stackTilesAtPos.isNotEmpty) {
          // 找到最上面的堆叠方块（stackIndex最大）
          final maxStackIndex =
              stackTilesAtPos.map((t) => t.stackIndex).reduce(math.max);

          // 除了最上面的，其他堆叠方块都被遮挡
          for (var tile in stackTilesAtPos) {
            if (tile.stackIndex < maxStackIndex) {
              tile.isBlocked = true;
            }
          }
        }
      }
    }

    // 检查普通方块的遮挡关系
    final normalTiles =
        boardTiles.where((t) => !t.isStacked && !t.isSelected).toList();
    for (var tile in normalTiles) {
      for (var otherTile in normalTiles) {
        if (tile == otherTile) continue;

        if (otherTile.blocksOther(tile)) {
          tile.isBlocked = true;
          break;
        }
      }
    }

    // 调试输出
    // final unselectedCount = boardTiles.where((t) => !t.isSelected).length;
    // final unblockedCount =
    //     allTiles.where((t) => !t.isSelected && !t.isBlocked).length;
    // debugPrint(
    //     '遮挡状态更新: 剩余方块=$unselectedCount, 被遮挡=$blockedCount, 可点击=$unblockedCount');
  }

  /// 点击方块的处理
  void _onTileTapped(MatchingTile tile) async {
    if (isGameOver) return;
    if (tile.isBlocked || tile.isSelected || tile.isInSlot) return;

    // debugPrint(
    //     '点击方块: Layer=${tile.layer}, Grid=(${tile.gridX},${tile.gridY}), IconId=${tile.iconId}');

    // 添加到槽位
    if (slotTiles.length >= maxSlots) {
      // 槽位已满，游戏失败
      _onGameOver(false);
      return;
    }

    // 标记为已选中和在槽位中
    tile.isSelected = true;
    tile.isInSlot = true;
    tile.priority = 1000; // 提高优先级，显示在最上层

    // 计算目标位置（槽位位置 + 当前槽位数量的偏移）
    final slotIndex = slotTiles.length;
    final targetPos = _getSlotPosition(slotIndex);

    // 添加到槽位列表
    boardTiles.remove(tile);
    slotTiles.add(tile);

    // 更新遮挡状态
    _updateBlockedStates();

    engine.play(GameSound.put);

    // 移动到槽位（带动画）
    await tile.moveTo(
      toPosition: targetPos,
      duration: 0.3,
      curve: Curves.easeOutCubic,
    );

    // 检查消除
    await _checkMatching();
  }

  /// 检查槽位中是否有可以消除的配对（三消）
  Future<void> _checkMatching() async {
    if (slotTiles.length < 3) return;

    // 查找三个相同的方块
    for (int i = 0; i < slotTiles.length - 2; i++) {
      for (int j = i + 1; j < slotTiles.length - 1; j++) {
        if (slotTiles[i].iconId != slotTiles[j].iconId) continue;

        for (int k = j + 1; k < slotTiles.length; k++) {
          if (slotTiles[i].iconId != slotTiles[k].iconId) continue;

          // 找到三个相同的，消除
          final tile1 = slotTiles[i];
          final tile2 = slotTiles[j];
          final tile3 = slotTiles[k];

          // 1. 立即从槽位列表中移除（避免快速点击时误判槽位已满）
          slotTiles.remove(tile1);
          slotTiles.remove(tile2);
          slotTiles.remove(tile3);

          // 2. 标记为匹配状态（变亮）
          tile1.isMatched = true;
          tile2.isMatched = true;
          tile3.isMatched = true;

          // 3. 创建碎片效果
          final celebration1 = MatchCelebration(
            position: tile1.position,
            size: tile1.size,
          );
          final celebration2 = MatchCelebration(
            position: tile2.position,
            size: tile2.size,
          );
          final celebration3 = MatchCelebration(
            position: tile3.position,
            size: tile3.size,
          );
          world.add(celebration1);
          world.add(celebration2);
          world.add(celebration3);

          engine.play(GameSound.success);

          // 4. 等待0.5秒让玩家看到效果
          await Future.delayed(Duration(milliseconds: 250));

          // 5. 淡出效果
          await Future.wait([
            tile1.fadeOut(duration: 0.2),
            tile2.fadeOut(duration: 0.2),
            tile3.fadeOut(duration: 0.2),
          ]);

          // 6. 移除方块
          world.remove(tile1);
          world.remove(tile2);
          world.remove(tile3);

          // 7. 等待重排完成（如果还没完成）
          await _rearrangeSlots();

          // 8. 清理碎片效果（1秒后自动消失，这里提前清理）
          await Future.delayed(Duration(milliseconds: 100));
          world.remove(celebration1);
          world.remove(celebration2);
          world.remove(celebration3);

          // 可能产生新的配对，继续检查
          await _checkMatching();

          // 检查胜利
          _checkWin();

          return;
        }
      }
    }

    // 检查是否槽位满但无法配对
    if (slotTiles.length >= maxSlots) {
      _onGameOver(false);
    }
  }

  /// 重新排列槽位中的方块
  Future<void> _rearrangeSlots() async {
    final futures = <Future>[];
    for (int i = 0; i < slotTiles.length; i++) {
      final tile = slotTiles[i];
      final targetPos = _getSlotPosition(i);
      futures.add(tile.moveTo(
        toPosition: targetPos,
        duration: 0.2,
        curve: Curves.easeInOut,
      ));
    }
    await Future.wait(futures);
  }

  /// 检查是否胜利
  void _checkWin() {
    if (isGameOver) return;

    // 检查是否所有方块都被选中
    if (boardTiles.isEmpty && slotTiles.isEmpty) {
      _onGameOver(true);
    }
  }

  /// 显示游戏结果
  void _onGameOver(bool won) {
    if (isGameOver) return;

    engine.bgm.pause();

    isGameOver = true;
    isGameWon = won;
    barrier.isVisible = true;

    if (won) {
      camera.viewport.add(victoryPrompt);
      engine.play(GameSound.victory);

      final celebration = ConfettiEffect(
        position: Vector2.zero(),
        size: size,
        priority: kConfettiPriority,
      );
      camera.viewport.add(celebration);
    } else {
      camera.viewport.add(defeatPrompt);
      engine.play(GameSound.gameOver);
    }

    Future.delayed(const Duration(milliseconds: 500), () {
      restart.isVisible = engine.config.developMode;
      restart.position = Vector2(
          center.x,
          victoryPrompt.bottomRight.y +
              GameUI.buttonSizeMedium.y +
              GameUI.largeIndent);

      exit.position = Vector2(
          center.x,
          restart.bottomRight.y +
              GameUI.buttonSizeMedium.y / 2 +
              GameUI.indent);
    });
  }

  Future<void> _endScene(bool won) async {
    final result = await onGameEnd?.call(won);
    if (result != true) {
      engine.popScene(clearCache: true);
    }
  }

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext)? loadingBuilder,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
    List<String>? initialActiveOverlays,
  }) {
    return Stack(
      children: [
        SceneWidget(
          scene: this,
          loadingBuilder: loadingBuilder,
          overlayBuilderMap: overlayBuilderMap,
          initialActiveOverlays: initialActiveOverlays,
        ),
        GameUIOverlay(
          enableLibrary: false,
          enableCultivation: false,
          showNpcs: false,
          showJournal: false,
          actions: [
            // 帮助按钮
            Container(
              decoration: GameUI.boxDecoration,
              width: GameUI.infoButtonSize.width,
              height: GameUI.infoButtonSize.height,
              child: IconButton(
                icon: Icon(Icons.question_mark),
                padding: const EdgeInsets.all(0),
                mouseCursor: GameUI.cursor.resolve({WidgetState.hovered}),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  // /// 显示帮助信息
  // void _showHelp(BuildContext context) {
  //   debugPrint('游戏规则: \n'
  //       '1. 点击未被遮挡的方块，方块会移动到右侧槽位\n'
  //       '2. 槽位最多容纳7个方块\n'
  //       '3. 当槽位中有3个相同的方块时会自动消除\n'
  //       '4. 消除所有方块即为胜利\n'
  //       '5. 如果槽位满了还无法配对，游戏失败\n'
  //       '6. 上层方块会遮挡下层方块，被遮挡的方块会变暗');
  // }
}
