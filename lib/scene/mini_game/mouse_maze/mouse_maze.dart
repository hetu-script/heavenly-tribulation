import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/ui/sprite_button.dart';
import 'package:samsara/effect/confetti.dart';
import 'package:samsara/components/sprite_component2.dart';

import '../../particles/light_point.dart';
import '../../../global.dart';
import '../../../ui.dart';
import '../../cursor_state.dart';
import '../../common.dart';
import '../../../data/game.dart';
import '../common.dart';

const _kMazePartPriority = 10;
const _kMazePartPriority2 = 20;
const _kDragZonePriority = 500;

const _kLightPointRadius = 15.0;

const double _kCellSize = 50.0;

const _kCollisionThreshold = _kLightPointRadius * 2 / 3;

final _portalColors = [
  Colors.purple,
  Colors.cyan,
  Colors.orange,
  Colors.pink,
  Colors.lime,
  Colors.amber,
  Colors.teal,
  Colors.indigo,
];

/// 检查点到线段的距离是否小于阈值（碰撞检测）
bool _checkLineSegmentCollision(
  Vector2 point,
  Vector2 lineStart,
  Vector2 lineEnd,
  double threshold,
) {
  final dx = lineEnd.x - lineStart.x;
  final dy = lineEnd.y - lineStart.y;
  final lengthSquared = dx * dx + dy * dy;

  if (lengthSquared == 0) {
    return point.distanceTo(lineStart) < threshold;
  }

  final t = ((point.x - lineStart.x) * dx + (point.y - lineStart.y) * dy) /
      lengthSquared;

  // 如果垂直投影点不在线段范围内，不碰撞
  if (t < 0.0 || t > 1.0) {
    return false;
  }

  final closestPoint = Vector2(lineStart.x + t * dx, lineStart.y + t * dy);
  return point.distanceTo(closestPoint) < threshold;
}

/// 传送门
class _Portal extends CircleComponent {
  final String id;
  _Portal? linkedPortal;
  final Color portalColor;
  final Paint _inactivePaint, _glowPaint;
  double _glowTimer = 0.0;
  bool isActive = true; // 传送门是否激活（可用）

  final SpriteAnimationWithTicker _animation;

  _Portal({
    required this.id,
    required super.position,
    this.portalColor = Colors.purple,
  })  : _glowPaint = Paint()
          ..color = portalColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10.0),
        _inactivePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = Colors.grey.withValues(alpha: 0.6),
        _animation = SpriteAnimationWithTicker(
          animationId: 'mini_game/mouse_maze/portal.png',
          srcSize: Vector2(48, 48),
          stepTime: 0.5,
        ),
        super(
          radius: _kLightPointRadius,
          anchor: Anchor.center,
          paint: Paint()..color = portalColor.withValues(alpha: 0.8),
          priority: _kMazePartPriority2,
        );

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _animation.load();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _glowTimer += dt;

    _animation.update(dt);
  }

  @override
  void render(Canvas canvas) {
    final offset = (size / 2).toOffset();

    if (isActive) {
      // 绘制传送门本体
      // canvas.drawCircle(offset, radius, paint);
      if (_animation.isLoaded) {
        _animation.currentSprite.render(canvas, size: size);
      }
      // 绘制发光效果
      final glowRadius = radius + 5 + math.sin(_glowTimer * 3) * 3;
      canvas.drawCircle(offset, glowRadius, _glowPaint);
    } else {
      // 未激活状态：绘制灰色圆圈，无光晕
      canvas.drawCircle(offset, radius, _inactivePaint);
    }
  }

  bool containsPosition(Vector2 pos) {
    return position.distanceTo(pos) <= radius;
  }
}

/// 开关门
class _SwitchDoor extends BorderComponent {
  final bool isHorizontal;
  final double openDuration;
  final double stayOpenDuration;
  final double closeDuration;
  final double initialTimeOffset;
  final Paint _doorPaint;
  final Paint _glowPaint;

  bool isOpen = false;
  double _timeElapsed = 0.0;
  double _phase = 0.0; // 0.0 = 完全关闭, 1.0 = 完全打开

  _SwitchDoor({
    required super.position,
    required this.isHorizontal,
    this.openDuration = 1.0,
    this.stayOpenDuration = 2.0,
    this.closeDuration = 1.0,
    this.initialTimeOffset = 0.0,
  })  : _timeElapsed = initialTimeOffset,
        _doorPaint = Paint()
          ..color = Colors.orange
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6.0
          ..strokeCap = StrokeCap.round,
        _glowPaint = Paint()
          ..color = Colors.orange.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 12.0
          ..strokeCap = StrokeCap.round,
        super(
          size: isHorizontal ? Vector2(50.0, 6.0) : Vector2(6.0, 50.0),
          anchor: Anchor.center,
          priority: _kMazePartPriority2,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _timeElapsed += dt;

    final cycleDuration = openDuration + stayOpenDuration + closeDuration;
    final cycleTime = _timeElapsed % cycleDuration;

    if (cycleTime < openDuration) {
      // 打开阶段
      _phase = (cycleTime / openDuration).clamp(0.0, 1.0);
      isOpen = false;
    } else if (cycleTime < openDuration + stayOpenDuration) {
      // 保持打开阶段
      _phase = 1.0;
      isOpen = true;
    } else {
      // 关闭阶段
      final closeProgress =
          (cycleTime - openDuration - stayOpenDuration) / closeDuration;
      _phase = (1.0 - closeProgress).clamp(0.0, 1.0);
      isOpen = false;
    }
  }

  @override
  void render(Canvas canvas) {
    if (_phase < 0.1) return; // 完全打开时不渲染

    final opacity = (1.0 - _phase).clamp(0.0, 1.0);
    _doorPaint.color = Colors.orange.withValues(alpha: opacity);
    _glowPaint.color = Colors.orange.withValues(alpha: opacity);

    if (isHorizontal) {
      final y = size.y / 2;
      canvas.drawLine(Offset(0, y), Offset(size.x, y), _glowPaint);
      canvas.drawLine(Offset(0, y), Offset(size.x, y), _doorPaint);
    } else {
      final x = size.x / 2;
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), _glowPaint);
      canvas.drawLine(Offset(x, 0), Offset(x, size.y), _doorPaint);
    }
  }

  bool blocksPosition(Vector2 pos) {
    if (_phase > 0.9) return false; // 几乎完全打开

    // 使用通用的线段碰撞检测逻辑
    final Vector2 start, end;
    if (isHorizontal) {
      // 水平门：从左到右
      start = position - Vector2(size.x / 2, 0);
      end = position + Vector2(size.x / 2, 0);
    } else {
      // 垂直门：从上到下
      start = position - Vector2(0, size.y / 2);
      end = position + Vector2(0, size.y / 2);
    }

    return _checkLineSegmentCollision(pos, start, end, _kCollisionThreshold);
  }
}

/// 迷宫单元格
class _Cell {
  bool topWall = true;
  bool rightWall = true;
  bool bottomWall = true;
  bool leftWall = true;
  bool visited = false;
}

/// 迷宫墙壁线段，用于碰撞检测
class _Wall {
  final Vector2 start;
  final Vector2 end;

  _Wall(this.start, this.end);

  /// 检查点到线段的距离
  /// 只有当点的垂直投影在线段范围内时才计算距离，否则返回无穷大
  double distanceToPoint(Vector2 point) {
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final lengthSquared = dx * dx + dy * dy;

    if (lengthSquared == 0) {
      return point.distanceTo(start);
    }

    // 计算投影参数 t
    final t =
        ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared;

    // 如果垂直投影点不在线段范围内，返回无穷大（表示不碰撞）
    if (t < 0.0 || t > 1.0) {
      return double.infinity;
    }

    // 计算垂直投影点在线段上的位置
    final closestPoint = Vector2(start.x + t * dx, start.y + t * dy);
    return point.distanceTo(closestPoint);
  }
}

/// 迷宫渲染组件
class _Maze extends PositionComponent {
  static final Paint _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.6)
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 8.0
    ..isAntiAlias = true;
  static final Paint _outerStrokePaint = Paint()
    ..color = Colors.black87
    ..style = PaintingStyle.stroke
    ..strokeWidth = 6.0
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;
  static final Paint _innerStrokePaint = Paint()
    ..color = Colors.white70
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..strokeCap = StrokeCap.round
    ..isAntiAlias = true;

  List<List<_Cell>>? _data;

  final double kCellSize;

  final List<_Wall> wallSegments = [];

  _Maze({required this.kCellSize});

  void setMazeData(List<List<_Cell>> data) {
    assert(data.isNotEmpty);
    _data = data;

    wallSegments.clear();

    final rows = _data!.length;
    final cols = _data![0].length;

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final cell = _data![row][col];
        final x = col * kCellSize;
        final y = row * kCellSize;

        if (cell.topWall) {
          wallSegments.add(_Wall(
            Vector2(x, y),
            Vector2(x + kCellSize, y),
          ));
        }
        if (cell.rightWall) {
          wallSegments.add(_Wall(
            Vector2(x + kCellSize, y),
            Vector2(x + kCellSize, y + kCellSize),
          ));
        }
        if (cell.bottomWall) {
          wallSegments.add(_Wall(
            Vector2(x, y + kCellSize),
            Vector2(x + kCellSize, y + kCellSize),
          ));
        }
        if (cell.leftWall) {
          wallSegments.add(_Wall(
            Vector2(x, y),
            Vector2(x, y + kCellSize),
          ));
        }
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (_data == null) return;

    final rows = _data!.length;
    final cols = _data![0].length;

    // 绘制所有墙壁
    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final cell = _data![row][col];
        final x = col * kCellSize;
        final y = row * kCellSize;

        // 绘制顶部墙壁
        if (cell.topWall) {
          _drawWall(canvas, Offset(x, y), Offset(x + kCellSize, y));
        }
        // 绘制右侧墙壁
        if (cell.rightWall) {
          _drawWall(canvas, Offset(x + kCellSize, y),
              Offset(x + kCellSize, y + kCellSize));
        }
        // 绘制底部墙壁
        if (cell.bottomWall) {
          _drawWall(canvas, Offset(x, y + kCellSize),
              Offset(x + kCellSize, y + kCellSize));
        }
        // 绘制左侧墙壁
        if (cell.leftWall) {
          _drawWall(canvas, Offset(x, y), Offset(x, y + kCellSize));
        }
      }
    }
  }

  void _drawWall(Canvas canvas, Offset start, Offset end) {
    // 1. 绘制阴影
    canvas.drawLine(start, end, _shadowPaint);
    // 2. 绘制外层黑色描边
    canvas.drawLine(start, end, _outerStrokePaint);
    // 3. 绘制内层白色线条
    canvas.drawLine(start, end, _innerStrokePaint);
  }
}

/// 拖拽区域组件
class _DragArea extends GameComponent with HandlesGesture {
  _DragArea({
    required super.size,
    required MouseMazeGame game,
  }) : super(priority: _kDragZonePriority);
}

class MouseMazeGame extends Scene with HasCursorState {
  static final random = math.Random();

  late List<List<_Cell>> _mazeData;
  late final _Maze _maze;
  late final LightPoint lightPoint;
  late final CircleComponent startMarker, endMarker;

  Vector2? startPosition;
  Vector2? endPosition;

  bool _isDragging = false;
  int _errorCount = 0;
  bool isGameOver = false;
  bool isGameWon = false;

  late final SpriteButton restart, exit;

  late final Sprite heart, brokenHeart;

  // 游戏元素
  final List<_Portal> _portals = [];
  final List<_SwitchDoor> _switchDoors = [];

  // 难度配置
  late MiniGameDifficulty difficulty;
  late int mazeRows;
  late int mazeColumns;
  late int portalPairCount;
  late int switchDoorCount;
  late int maxErrors;
  late Vector2 errorIndicatorStartPoint;

  late final SpriteComponent victoryPrompt, defeatPrompt;

  late final SpriteComponent2 barrier;

  FutureOr<void> Function()? onGameStart;
  FutureOr<dynamic> Function(bool won)? onGameEnd;

  MouseMazeGame({
    required this.difficulty,
    this.onGameStart,
    this.onGameEnd,
  }) : super(
          id: Scenes.mouseMazeGame,
          bgm: engine.bgm,
          bgmFile: 'Shadows Within.mp3',
          bgmVolume: 0.5,
          enableLighting: true,
          backgroundLightingColor: Colors.black,
        );

  @override
  void onLoad() async {
    super.onLoad();

    final background = SpriteComponent(
      sprite: await Sprite.load('mini_game/background2.png'),
      size: size,
    );
    world.add(background);

    heart = await Sprite.load('mini_game/heart.png');
    brokenHeart = await Sprite.load('mini_game/broken_heart.png');

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
      position: Vector2(
          center.x,
          victoryPrompt.bottomRight.y +
              GameUI.buttonSizeMedium.y +
              GameUI.largeIndent),
      text: engine.locale('restart'),
      isVisible: false,
    );
    restart.onTap = (_, __) {
      _initializeGame();
    };
    camera.viewport.add(restart);

    exit = SpriteButton(
      spriteId: 'ui/button.png',
      size: GameUI.buttonSizeMedium,
      anchor: Anchor.center,
      position: GameUI.exitButtonPosition,
      text: engine.locale('exit'),
    );
    exit.onTap = (_, __) {
      _endScene(isGameWon);
    };
    camera.viewport.add(exit);

    // 创建迷宫
    _maze = _Maze(kCellSize: _kCellSize);
    world.add(_maze);

    // 创建起点标记（绿色圆圈）
    startMarker = CircleComponent(
      radius: _kLightPointRadius,
      anchor: Anchor.center,
      paint: Paint()..color = Colors.green.withValues(alpha: 0.8),
      priority: _kMazePartPriority,
    );
    world.add(startMarker);

    // 创建终点标记（红色圆圈）
    endMarker = CircleComponent(
      radius: _kLightPointRadius,
      anchor: Anchor.center,
      paint: Paint()..color = Colors.red.withValues(alpha: 0.8),
      priority: _kMazePartPriority,
    );
    world.add(endMarker);

    // 创建光点
    lightPoint = LightPoint(
      assetId: 'light_point.png',
      preferredRadius: 150.0, // 增大光照半径以获得更好的视野
      flickerRate: 5,
      priority: _kMazePartPriority2,
      preferredSize: Vector2(30.0, 30.0),
    );
    world.add(lightPoint);

    // 添加一个透明的拖拽区域覆盖整个屏幕
    final dragArea = _DragArea(size: size, game: this);
    dragArea.onMouseHover = checkMouseHover;
    dragArea.onDragStart = (int button, Vector2 position) {
      // debugPrint('DragArea onDragStart: button=$button, position=$position');
      if (button == kPrimaryButton) {
        onLightPointDragStart(position);
      }
      return dragArea;
    };
    dragArea.onDragUpdate = (int button, Vector2 position, Vector2 delta) {
      // debugPrint(
      //     'DragArea onDragUpdate: button=$button, position=$position, delta=$delta');
      if (button == kPrimaryButton) {
        onLightPointDragUpdate(position);
      }
    };
    dragArea.onDragEnd = (Vector2 position) {
      // debugPrint('DragArea onDragEnd: position=$position');
      onLightPointDragEnd(position);
    };
    world.add(dragArea);

    // 初始化游戏（生成迷宫数据和游戏元素）
    _initializeGame();

    await onGameStart?.call();
  }

  void _initializeGame() {
    engine.bgm.resume();

    _errorCount = 0;
    isGameOver = false;
    _isDragging = false;
    barrier.isVisible = false;

    victoryPrompt.removeFromParent();
    defeatPrompt.removeFromParent();

    restart.isVisible = false;

    exit.position = GameUI.exitButtonPosition;

    switch (difficulty) {
      case MiniGameDifficulty.easy:
        maxErrors = 6;
        mazeRows = 5;
        mazeColumns = 9;
        portalPairCount = 1;
        switchDoorCount = 1;
      case MiniGameDifficulty.normal:
        maxErrors = 5;
        mazeRows = 6;
        mazeColumns = 12;
        portalPairCount = 1;
        switchDoorCount = 1;
      case MiniGameDifficulty.challenging:
        maxErrors = 4;
        mazeRows = 7;
        mazeColumns = 15;
        portalPairCount = 2;
        switchDoorCount = 2;
      case MiniGameDifficulty.hard:
        maxErrors = 3;
        mazeRows = 8;
        mazeColumns = 18;
        portalPairCount = 2;
        switchDoorCount = 2;
      case MiniGameDifficulty.tough:
        maxErrors = 2;
        mazeRows = 9;
        mazeColumns = 21;
        portalPairCount = 3;
        switchDoorCount = 3;
      case MiniGameDifficulty.brutal:
        maxErrors = 1;
        mazeRows = 10;
        mazeColumns = 24;
        portalPairCount = 3;
        switchDoorCount = 3;
    }
    errorIndicatorStartPoint = Vector2(
        size.x / 2 - (maxErrors / 2) * GameUI.miniGameIndicatorIconSize,
        size.y - GameUI.miniGameIndicatorIconSize - GameUI.indent);

    // 计算迷宫的实际尺寸和位置（居中显示）
    final mazeWidth = mazeColumns * _kCellSize;
    final mazeHeight = mazeRows * _kCellSize;
    final mazePosition = Vector2(
      (size.x - mazeWidth) / 2,
      (size.y - kUIOverlayHeight - mazeHeight) / 2 + kUIOverlayHeight,
    );
    _maze.position = mazePosition;
    _maze.size = Vector2(mazeWidth, mazeHeight);

    // 设置起点和终点
    startPosition = mazePosition + Vector2(_kCellSize / 2, _kCellSize / 2);
    startMarker.position = startPosition!;
    endPosition = mazePosition +
        Vector2(
            (mazeColumns - 0.5) * _kCellSize, (mazeRows - 0.5) * _kCellSize);
    endMarker.position = endPosition!;

    // 重置光点位置
    lightPoint.position = startPosition!;

    // 生成迷宫
    _mazeData = _generateMaze(mazeRows, mazeColumns);
    _maze.setMazeData(_mazeData);

    for (final portal in _portals) {
      portal.removeFromParent();
    }
    _portals.clear();

    for (final door in _switchDoors) {
      door.removeFromParent();
    }
    _switchDoors.clear();

    // 添加游戏元素
    _addGameElements();
  }

  /// 添加传送门、开关门、钥匙和锁等游戏元素
  void _addGameElements() {
    final mazePosition = _maze.position;

    // 1. 添加传送门 - 随机放置在迷宫中
    if (portalPairCount > 0) {
      for (int i = 0; i < portalPairCount; i++) {
        final portalColor = _portalColors[i % _portalColors.length];

        // 随机选择两个不同的位置，且不能在入口 (0, 0)
        var pos1Row = random.nextInt(mazeRows);
        var pos1Col = random.nextInt(mazeColumns);
        // 确保第一个传送门不在入口
        while (pos1Row == 0 && pos1Col == 0) {
          pos1Row = random.nextInt(mazeRows);
          pos1Col = random.nextInt(mazeColumns);
        }

        var pos2Row = random.nextInt(mazeRows);
        var pos2Col = random.nextInt(mazeColumns);
        // 确保第二个传送门不在入口，且不与第一个传送门重叠
        while ((pos2Row == 0 && pos2Col == 0) ||
            (pos2Row == pos1Row && pos2Col == pos1Col)) {
          pos2Row = random.nextInt(mazeRows);
          pos2Col = random.nextInt(mazeColumns);
        }

        final portal1 = _Portal(
          id: 'portal_${i}_1',
          position: mazePosition +
              Vector2(
                  (pos1Col + 0.5) * _kCellSize, (pos1Row + 0.5) * _kCellSize),
          portalColor: portalColor,
        );

        final portal2 = _Portal(
          id: 'portal_${i}_2',
          position: mazePosition +
              Vector2(
                  (pos2Col + 0.5) * _kCellSize, (pos2Row + 0.5) * _kCellSize),
          portalColor: portalColor,
        );

        // 双向链接
        portal1.linkedPortal = portal2;
        portal2.linkedPortal = portal1;

        _portals.addAll([portal1, portal2]);
        world.add(portal1);
        world.add(portal2);
      }
    }

    // 2. 添加开关门 - 根据配置数量添加，智能放置在必经之路上
    if (switchDoorCount > 0) {
      final doorPositions = _findDoorPositionsOnPath();
      for (int i = 0; i < switchDoorCount && i < doorPositions.length; i++) {
        final doorInfo = doorPositions[i];
        // 为每个门生成随机的初始时间偏移，使它们的节奏不同步
        final cycleDuration =
            1.0 + 2.0 + 1.0; // openDuration + stayOpenDuration + closeDuration
        final randomOffset = random.nextDouble() * cycleDuration;
        final switchDoor = _SwitchDoor(
          position: mazePosition + doorInfo['position'],
          isHorizontal: doorInfo['isHorizontal'],
          openDuration: 1.0,
          stayOpenDuration: 2.0,
          closeDuration: 1.0,
          initialTimeOffset: randomOffset,
        );
        _switchDoors.add(switchDoor);
        world.add(switchDoor);
      }
    }
  }

  /// 使用BFS找到从起点到终点的路径，并返回适合放置门的位置
  List<Map<String, dynamic>> _findDoorPositionsOnPath() {
    // BFS 找到从 (0,0) 到 (rows-1, cols-1) 的路径
    final rows = mazeRows;
    final cols = mazeColumns;
    final visited = List.generate(rows, (_) => List.filled(cols, false));
    final parent = <(int, int), (int, int)>{};
    final queue = <(int, int)>[];

    queue.add((0, 0));
    visited[0][0] = true;

    while (queue.isNotEmpty) {
      final (row, col) = queue.removeAt(0);

      if (row == rows - 1 && col == cols - 1) {
        break; // 找到终点
      }

      // 检查四个方向
      final directions = [
        (-1, 0, 'top'), // 上
        (0, 1, 'right'), // 右
        (1, 0, 'bottom'), // 下
        (0, -1, 'left'), // 左
      ];

      for (final (dr, dc, direction) in directions) {
        final newRow = row + dr;
        final newCol = col + dc;

        if (newRow < 0 ||
            newRow >= rows ||
            newCol < 0 ||
            newCol >= cols ||
            visited[newRow][newCol]) {
          continue;
        }

        // 检查是否有墙壁阻挡
        bool canPass = false;
        if (direction == 'top' && !_mazeData[row][col].topWall) {
          canPass = true;
        } else if (direction == 'right' && !_mazeData[row][col].rightWall) {
          canPass = true;
        } else if (direction == 'bottom' && !_mazeData[row][col].bottomWall) {
          canPass = true;
        } else if (direction == 'left' && !_mazeData[row][col].leftWall) {
          canPass = true;
        }

        if (canPass) {
          visited[newRow][newCol] = true;
          parent[(newRow, newCol)] = (row, col);
          queue.add((newRow, newCol));
        }
      }
    }

    // 回溯路径
    final path = <(int, int)>[];
    var current = (rows - 1, cols - 1);
    while (parent.containsKey(current)) {
      path.insert(0, current);
      current = parent[current]!;
    }
    path.insert(0, (0, 0));

    // 找出路径上所有的通道（被移除的墙壁）
    final passages = <Map<String, dynamic>>[];
    for (int i = 0; i < path.length - 1; i++) {
      final (row1, col1) = path[i];
      final (row2, col2) = path[i + 1];

      Vector2 position;
      bool isHorizontal;

      if (row1 == row2) {
        // 水平移动
        final minCol = math.min(col1, col2);
        position =
            Vector2((minCol + 1) * _kCellSize, (row1 + 0.5) * _kCellSize);
        isHorizontal = false; // 垂直门横跨水平通道
      } else {
        // 垂直移动
        final minRow = math.min(row1, row2);
        position =
            Vector2((col1 + 0.5) * _kCellSize, (minRow + 1) * _kCellSize);
        isHorizontal = true; // 水平门横跨垂直通道
      }

      passages.add({
        'position': position,
        'isHorizontal': isHorizontal,
        'index': i,
      });
    }

    // 选择靠近路径中间的位置
    if (passages.isEmpty) return [];

    final middleIndex = passages.length ~/ 2;
    // 可以返回多个位置，这里选择中间附近的几个
    final selectedPassages = <Map<String, dynamic>>[];
    final range = (passages.length / 2).ceil(); // 选择中间1/2范围内的通道

    for (int i = math.max(0, middleIndex - range);
        i < math.min(passages.length, middleIndex + range);
        i++) {
      selectedPassages.add(passages[i]);
    }

    // 如果需要多个门，从选中的通道中随机选择
    selectedPassages.shuffle(random);
    return selectedPassages;
  }

  /// 使用深度优先搜索生成迷宫
  List<List<_Cell>> _generateMaze(int rows, int cols) {
    final maze = List.generate(
      rows,
      (row) => List.generate(cols, (col) => _Cell()),
    );

    void dfs(int row, int col) {
      maze[row][col].visited = true;

      final directions = [
        [-1, 0], // 上
        [0, 1], // 右
        [1, 0], // 下
        [0, -1], // 左
      ]..shuffle(random);

      for (final dir in directions) {
        final newRow = row + dir[0];
        final newCol = col + dir[1];

        if (newRow >= 0 &&
            newRow < rows &&
            newCol >= 0 &&
            newCol < cols &&
            !maze[newRow][newCol].visited) {
          // 移除墙壁
          if (dir[0] == -1) {
            maze[row][col].topWall = false;
            maze[newRow][newCol].bottomWall = false;
          } else if (dir[0] == 1) {
            maze[row][col].bottomWall = false;
            maze[newRow][newCol].topWall = false;
          } else if (dir[1] == 1) {
            maze[row][col].rightWall = false;
            maze[newRow][newCol].leftWall = false;
          } else if (dir[1] == -1) {
            maze[row][col].leftWall = false;
            maze[newRow][newCol].rightWall = false;
          }

          dfs(newRow, newCol);
        }
      }
    }

    dfs(0, 0);
    return maze;
  }

  void checkMouseHover(Vector2 position) {
    if (isGameOver) return;
    if (_isDragging) return;

    // 可以在这里添加鼠标悬停时的逻辑
    if (lightPoint.containsPoint(position)) {
      cursorState = MouseCursorState.click;
    } else {
      cursorState = MouseCursorState.normal;
    }
  }

  void onLightPointDragStart(Vector2 position) {
    // 检查是否点击在光点附近
    if (lightPoint.containsPoint(position)) {
      _isDragging = true;

      cursorState = MouseCursorState.drag;
    }
  }

  void onLightPointDragUpdate(Vector2 position) {
    if (!_isDragging || isGameOver) return;

    // 检查传送门
    for (final portal in _portals) {
      // 跳过未激活的传送门
      if (!portal.isActive) continue;

      if (portal.containsPosition(position) && portal.linkedPortal != null) {
        final targetPortal = portal.linkedPortal!;

        // 传送到目标传送门位置
        lightPoint.position = targetPortal.position;

        // 将入口传送门和出口传送门都设为未激活状态
        portal.isActive = false;
        targetPortal.isActive = false;

        // 4秒后同时恢复两个传送门的激活状态
        Future.delayed(const Duration(seconds: 4), () {
          portal.isActive = true;
          targetPortal.isActive = true;
        });

        engine.play(GameSound.success);
        // 传送后终止拖动，玩家需要重新点击光点才能继续
        _isDragging = false;
        cursorState = MouseCursorState.normal;
        return; // 传送后立即返回，不继续处理
      }
    }
    // 更新光点位置
    lightPoint.position = position;

    // 检查开关门
    for (final door in _switchDoors) {
      if (door.blocksPosition(position)) {
        _onError();
        return;
      }
    }

    // 检查墙壁碰撞
    if (_checkCollision(lightPoint.center)) {
      _onError();
      return;
    }

    // 检查是否到达终点
    if (endPosition != null && position.distanceTo(endPosition!) <= 20.0) {
      _onGameOver(true);
    }
  }

  void onLightPointDragEnd(Vector2 position) {
    _isDragging = false;

    if (lightPoint.containsPoint(position)) {
      cursorState = MouseCursorState.click;
    } else {
      cursorState = MouseCursorState.normal;
    }
  }

  bool _checkCollision(Vector2 position) {
    // 将世界坐标转换为迷宫的局部坐标
    final localPosition = position - _maze.position;

    for (final wall in _maze.wallSegments) {
      final distance = wall.distanceToPoint(localPosition);
      if (distance < _kCollisionThreshold) {
        return true;
      }
    }

    return false;
  }

  void _onError() {
    ++_errorCount;
    if (_errorCount >= maxErrors) {
      _onGameOver(false);
    }

    // 播放失败音效
    engine.play(GameSound.error);

    addHintText(
      engine.locale('mouseMazeGame_fail'),
      textStyle: const TextStyle(
        color: Colors.red,
        fontSize: 48.0,
        fontWeight: FontWeight.bold,
        fontFamily: GameUI.fontFamilyLishu,
      ),
      horizontalVariation: 0.0,
      verticalVariation: 0.0,
      onViewport: true,
      duration: 1.5,
    );

    // 重置游戏
    _isDragging = false;
    if (startPosition != null) {
      lightPoint.position = startPosition!;
    }
    for (final portal in _portals) {
      portal.isActive = true;
    }
  }

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
  void render(Canvas canvas) {
    super.render(canvas);

    Vector2 startPoint2 = errorIndicatorStartPoint.clone();
    for (var i = 0; i < maxErrors; ++i) {
      if (i < maxErrors - _errorCount) {
        heart.render(
          canvas,
          position: startPoint2,
          size: Vector2.all(GameUI.miniGameIndicatorIconSize),
        );
      } else {
        brokenHeart.render(
          canvas,
          position: startPoint2,
          size: Vector2.all(GameUI.miniGameIndicatorIconSize),
        );
      }
      startPoint2.x += GameUI.miniGameIndicatorIconSize;
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
            Container(
              decoration: GameUI.boxDecoration,
              width: GameUI.infoButtonSize.width,
              height: GameUI.infoButtonSize.height,
              child: IconButton(
                icon: Icon(Icons.question_mark),
                padding: const EdgeInsets.all(0),
                mouseCursor: GameUI.cursor.resolve({WidgetState.hovered}),
                onPressed: () {
                  // GameDialogContent.show(
                  //   context,
                  //   engine.locale('hint_cultivation'),
                  //   style: TextStyle(color: Colors.yellow),
                  // );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
