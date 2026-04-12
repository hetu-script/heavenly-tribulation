import 'dart:async';
import 'dart:math' as math;

import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart' hide Image;
// import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:json5/json5.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:samsara/components/sprite_component2.dart';
import 'package:samsara/effect/confetti.dart';
import 'package:samsara/effect/fade.dart';
import 'package:flame/effects.dart';
import 'package:samsara/components/ui/sprite_button.dart';

import '../../../ui.dart';
import '../../../global.dart';
import '../../cursor_state.dart';
import '../../common.dart';
import '../../../data/game.dart';
import '../common.dart';

const _kMaxDifferenceGames = 11;

const _kPicPriority = 50;
const _kDiffIndicatorPriority = 10;
const _kErrorIndicatorPriority = 20;

/// 椭圆标记组件，黄色圆圈内外都有黑色描边，带阴影
class FoundIndicator extends PositionComponent {
  static final _shadowPaint = Paint()
    ..color = Colors.black.withValues(alpha: 0.4)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 6.0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 9.0
    ..isAntiAlias = true;
  static final _strokePaint = Paint()
    ..color = Colors.black26
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3.0
    ..isAntiAlias = true;
  static final _fillerPaint = Paint()
    ..color = Colors.yellow
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4.0
    ..isAntiAlias = true;

  FoundIndicator({
    required super.position,
    required super.size,
    super.priority,
  });

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 使用 Rect 绘制椭圆，而不是圆形
    // 留出边距以容纳描边
    final totalStrokeWidth =
        _strokePaint.strokeWidth + _fillerPaint.strokeWidth;
    final margin = totalStrokeWidth / 2;

    final rect = Rect.fromLTWH(
      margin,
      margin,
      width - totalStrokeWidth,
      height - totalStrokeWidth,
    );

    // 1. 绘制阴影（最底层，稍微偏移）
    final shadowRect = rect.inflate(1);
    canvas.drawOval(shadowRect, _shadowPaint);

    // 2. 绘制最外层黑色描边
    final outerRect =
        rect.inflate(_fillerPaint.strokeWidth / 2 + _strokePaint.strokeWidth);
    canvas.drawOval(outerRect, _strokePaint);

    // 3. 绘制最内层黑色描边
    final innerRect = rect.inflate(-_strokePaint.strokeWidth / 3);
    canvas.drawOval(innerRect, _strokePaint);

    // 4. 绘制中间黄色圆圈
    canvas.drawOval(rect.inflate(_fillerPaint.strokeWidth / 2), _fillerPaint);
  }
}

class DiffData {
  final Rect rect;
  final SpriteComponent component;
  bool found = false;

  DiffData({
    required this.rect,
    required this.component,
  });
}

class DifferenceGame extends Scene with HasCursorState {
  static final random = math.Random();

  // final fluent.FlyoutController menuController = fluent.FlyoutController();

  int? gameId;

  late MiniGameDifficulty difficulty;
  late int maxErrors;
  late Vector2 errorIndicatorStartPoint;

  late List<dynamic> _diffsData;
  final List<DiffData> _diffs = [];
  final List<FoundIndicator> _foundIndicators = [];
  final Map<int, Image> _diffImages = {};

  late SpriteComponent2 picLeft, picRight;

  late Vector2 _spotIndicatorsPosition;

  double _zoom = 1.0;

  late Sprite _errorIndicatorSprite;

  bool isGameOver = false;
  bool isGameWon = false;

  late final SpriteComponent victoryPrompt, defeatPrompt;

  late final SpriteButton restart, exit;

  late final Sprite hidden, found, heart, brokenHeart;

  int _foundedCount = 0;
  int _errorCount = 0;

  late final SpriteComponent2 barrier;

  FutureOr<void> Function()? onGameStart;
  FutureOr<dynamic> Function(bool won)? onGameEnd;

  DifferenceGame({
    this.gameId,
    required this.difficulty,
    this.onGameStart,
    this.onGameEnd,
  }) : super(
          id: Scenes.differenceGame,
          bgm: engine.bgm,
          bgmFile: 'Echoes of the East.mp3',
          bgmVolume: 0.5,
        );

  void setOffset(Vector2 newClipOffset) {
    // 边界检查：确保图片不会超出组件边界
    // clipOffset的有效范围：[0, size * (zoom - 1)]
    final maxOffset = GameUI.differenceGamePictureSize * (_zoom - 1.0);
    newClipOffset.x = newClipOffset.x.clamp(0.0, maxOffset.x);
    newClipOffset.y = newClipOffset.y.clamp(0.0, maxOffset.y);

    picLeft.clipOffset = newClipOffset;
    picRight.clipOffset = newClipOffset;
  }

  void setZoom(double newZoom, Vector2 mousePos) {
    final oldZoom = _zoom;
    _zoom = newZoom.clamp(1.0, 2.0);

    if (_zoom == oldZoom) return;

    // 应用到两个组件
    picLeft.zoom = _zoom;
    picRight.zoom = _zoom;

    // 计算鼠标位置在图片上对应的点（相对于原图的坐标）
    // 缩放前：imagePoint = (mousePos + clipOffset) / oldZoom
    // 缩放后保持该点在鼠标位置：(mousePos + newClipOffset) / newZoom = imagePoint
    // 因此：newClipOffset = imagePoint * newZoom - mousePos
    final imagePoint = (mousePos + picLeft.clipOffset) / oldZoom;
    final newClipOffset = imagePoint * _zoom - mousePos;

    setOffset(newClipOffset);
  }

  void checkDifferenceAt(
      SpriteComponent2 component, int button, Vector2 position) {
    if (button != kPrimaryButton) return;
    if (isGameOver) return;

    // 鼠标光标的手指实际位置和光标图片的左上角有10个像素的偏差(仅x方向)
    // 需要调整位置以对应手指的实际点击位置
    final fingerPosition = position + Vector2(10.0, 0.0);
    // 将局部坐标转换到原图坐标系（考虑 zoom 和 clipOffset）
    final imagePosition = (fingerPosition + component.clipOffset) / _zoom;
    final offset = Offset(imagePosition.x, imagePosition.y);

    bool found = false;
    for (final diff in _diffs) {
      if (diff.found) continue;
      if (diff.rect.contains(offset)) {
        // 找到差异，执行相应操作
        // debugPrint('Found difference at (${diff.rect.left}, ${diff.rect.top})');
        diff.found = found = true;
        ++_foundedCount;
        engine.play(GameSound.success);

        // 需要创建两个独立的组件实例，因为一个组件只能有一个父组件
        final indicatorLeft = FoundIndicator(
          position: diff.rect.topLeft.toVector2(),
          size: diff.rect.size.toVector2(),
          priority: _kDiffIndicatorPriority,
        );
        picLeft.add(indicatorLeft);
        _foundIndicators.add(indicatorLeft);
        final indicatorRight = FoundIndicator(
          position: diff.rect.topLeft.toVector2(),
          size: diff.rect.size.toVector2(),
          priority: _kDiffIndicatorPriority,
        );
        picRight.add(indicatorRight);
        _foundIndicators.add(indicatorRight);

        // 检查是否所有差异都已找到
        if (_diffs.every((d) => d.found)) {
          _onGameOver(true);
        }

        break;
      }
    }

    if (!found) {
      ++_errorCount;
      if (_errorCount >= maxErrors) {
        _onGameOver(false);
      }

      // 播放失败音效
      engine.play(GameSound.error);

      final error = _triggerError(position);
      component.add(error);
    }
  }

  GameComponent _triggerError(Vector2 localPosition) {
    // 在组件坐标系中添加错误指示器
    // localPosition 是用户点击的局部坐标（光标左上角位置）
    // 需要加上10像素偏差(仅x方向)得到手指实际位置
    // 再加上 clipOffset 得到在原图上的位置,然后除以 zoom 补偿缩放效果
    final fingerPosition = localPosition + Vector2(10.0, 0.0);
    final indicator = SpriteComponent2(
      sprite: _errorIndicatorSprite,
      position:
          (fingerPosition + picLeft.clipOffset - Vector2(16.0, 16.0)) / _zoom,
      size: Vector2(32.0, 32.0) / _zoom,
      priority: _kErrorIndicatorPriority,
    );
    indicator.add(
      FadeEffect(
        controller: EffectController(duration: 1.0),
        target: indicator,
      ),
    );
    return indicator;
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
  void onLoad() async {
    super.onLoad();

    _errorIndicatorSprite = await Sprite.load(
      'mini_game/difference/error.png',
    );

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

    final background = SpriteComponent(
      sprite: await Sprite.load('mini_game/difference/background.png'),
      size: size,
    );
    world.add(background);

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

    hidden = await Sprite.load('mini_game/difference/question_mark.png');
    found = await Sprite.load('mini_game/difference/check_mark.png');
    heart = await Sprite.load('mini_game/heart.png');
    brokenHeart = await Sprite.load('mini_game/broken_heart.png');

    picLeft = SpriteComponent2(
      position: Vector2(
          GameUI.differenceGameLeftBarWidth, GameUI.miniGameTopBarHeight),
      size: GameUI.differenceGamePictureSize,
      priority: _kPicPriority,
      enableGesture: true,
      clipMode: true,
    );
    picLeft.onMouseEnter = () {
      cursorState = MouseCursorState.click;
    };
    picLeft.onMouseExit = () {
      if (!picLeft.isHovering && !picRight.isHovering) {
        cursorState = MouseCursorState.normal;
      }
    };
    picLeft.onMouseScrollUp = (position) {
      setZoom(_zoom + 0.25, position);
    };
    picLeft.onMouseScrollDown = (position) {
      setZoom(_zoom - 0.25, position);
    };
    picLeft.onDragStart = (button, position) {
      if (button != kSecondaryButton) return null;
      cursorState = MouseCursorState.drag;
      return picLeft;
    };
    picLeft.onDragEnd = (position) {
      if (picLeft.containsPoint(position) || picRight.containsPoint(position)) {
        cursorState = MouseCursorState.click;
      } else {
        cursorState = MouseCursorState.normal;
      }
    };
    picLeft.onDragUpdate = (button, position, delta) {
      if (button != kSecondaryButton) return;
      final newOffset = picLeft.clipOffset - delta;
      setOffset(newOffset);
    };
    picLeft.onTapDown = (button, position) {
      checkDifferenceAt(picLeft, button, position);
    };
    world.add(picLeft);

    picRight = SpriteComponent2(
      position: Vector2(
          GameUI.differenceGameLeftBarWidth +
              GameUI.differenceGamePictureSize.x,
          GameUI.miniGameTopBarHeight),
      size: GameUI.differenceGamePictureSize,
      priority: _kPicPriority,
      enableGesture: true,
      clipMode: true,
    );
    picRight.onMouseEnter = () {
      cursorState = MouseCursorState.click;
    };
    picRight.onMouseExit = () {
      if (!picLeft.isHovering && !picRight.isHovering) {
        cursorState = MouseCursorState.normal;
      }
    };
    picRight.onMouseScrollUp = (position) {
      setZoom(_zoom + 0.25, position);
    };
    picRight.onMouseScrollDown = (position) {
      setZoom(_zoom - 0.25, position);
    };
    picRight.onDragStart = (button, position) {
      if (button != kSecondaryButton) return null;
      cursorState = MouseCursorState.drag;
      return picRight;
    };
    picRight.onDragEnd = (position) {
      if (picLeft.containsPoint(position) || picRight.containsPoint(position)) {
        cursorState = MouseCursorState.click;
      } else {
        cursorState = MouseCursorState.normal;
      }
    };
    picRight.onDragUpdate = (button, position, delta) {
      if (button != kSecondaryButton) return;
      final newOffset = picRight.clipOffset - delta;
      setOffset(newOffset);
    };
    picRight.onTapDown = (button, position) {
      checkDifferenceAt(picRight, button, position);
    };
    world.add(picRight);

    await _initializeGame(newGameId: gameId);
  }

  Future<void> _initializeGame({int? newGameId}) async {
    restart.position = GameUI.restartButtonPosition;
    exit.position = GameUI.exitButtonPosition;

    for (final diff in _diffs) {
      diff.component.removeFromParent();
    }
    _diffs.clear();

    for (final indicator in _foundIndicators) {
      indicator.removeFromParent();
    }
    _foundIndicators.clear();

    _foundedCount = 0;
    _errorCount = 0;
    isGameOver = false;
    barrier.isVisible = false;

    victoryPrompt.removeFromParent();
    defeatPrompt.removeFromParent();

    restart.isVisible = engine.config.developMode;

    engine.bgm.resume();

    await onGameStart?.call();

    newGameId ??= random.nextInt(_kMaxDifferenceGames) + 1;
    gameId = newGameId.clamp(1, _kMaxDifferenceGames);

    final gameDataString = await rootBundle.loadString(
        'assets/images/mini_game/difference/library/$gameId/config.json5');
    _diffsData = json5Decode(gameDataString);

    final mainSprite = await Sprite.load(
      'mini_game/difference/library/$gameId/main.png',
    );
    await picLeft.tryLoadSprite(sprite: mainSprite);
    await picRight.tryLoadSprite(sprite: mainSprite);

    int diffCount;
    List<dynamic> selectedDiffs = _diffsData.toList();
    if (difficulty != MiniGameDifficulty.easy) {
      // 难度大于简单时随机打乱差异顺序
      selectedDiffs.shuffle();
    }
    switch (difficulty) {
      case MiniGameDifficulty.easy:
        maxErrors = 7;
        diffCount = 5;
        // 简单模式：挑选尺寸（面积）最大的不同之处
        // 按面积降序排序
        selectedDiffs.sort((a, b) =>
            ((b['width'] as num) * (b['height'] as num))
                .compareTo((a['width'] as num) * (a['height'] as num)));
      case MiniGameDifficulty.normal:
        maxErrors = 7;
        diffCount = 8;
      case MiniGameDifficulty.challenging:
        maxErrors = 5;
        diffCount = 11;
      case MiniGameDifficulty.hard:
        maxErrors = 5;
        diffCount = 14;
      case MiniGameDifficulty.tough:
        maxErrors = 3;
        diffCount = 17;
      case MiniGameDifficulty.brutal:
        maxErrors = 3;
        diffCount = 20;
    }
    errorIndicatorStartPoint = Vector2(
        size.x / 2 - (maxErrors / 2) * GameUI.miniGameIndicatorIconSize,
        size.y - GameUI.miniGameIndicatorIconSize - GameUI.indent);

    selectedDiffs = selectedDiffs.take(diffCount).toList();
    _spotIndicatorsPosition = Vector2(
        size.x / 2 - (diffCount / 2) * GameUI.miniGameIndicatorIconSize,
        GameUI.miniGameTopBarHeight -
            GameUI.miniGameIndicatorIconSize -
            GameUI.smallIndent);

    // 加载完整的差异图片（只在首次加载，之后使用缓存）
    final diffImage = _diffImages[gameId!] ??=
        await images.load('mini_game/difference/library/$gameId/diff.png');

    // 获取原始图片尺寸
    final originalSize = picRight.sprite!.srcSize;
    // 计算缩放比例：显示尺寸 / 原始尺寸
    final scaleX = GameUI.differenceGamePictureSize.x / originalSize.x;
    final scaleY = GameUI.differenceGamePictureSize.y / originalSize.y;

    for (final data in selectedDiffs) {
      final srcPosition = Vector2(
        (data['left'] as num).toDouble(),
        (data['top'] as num).toDouble(),
      );
      final srcSize = Vector2(
        (data['width'] as num).toDouble(),
        (data['height'] as num).toDouble(),
      );
      // 从完整的差异图片中截取特定区域生成Sprite
      final sprite = Sprite(
        diffImage,
        srcPosition: srcPosition,
        srcSize: srcSize,
      );

      final ratio =
          GameUI.differenceGamePictureSize.x / picLeft.sprite!.srcSize.x;
      final scaledRect = Rect.fromLTWH(data['left'] * ratio,
          data['top'] * ratio, data['width'] * ratio, data['height'] * ratio);

      // 将贴片作为子组件添加到右侧图片上
      // 坐标从原始图片坐标映射到显示坐标
      final diffComponent = SpriteComponent(
        sprite: sprite,
        position: Vector2(srcPosition.x * scaleX, srcPosition.y * scaleY),
        size: Vector2(srcSize.x * scaleX, srcSize.y * scaleY),
      );
      final roll = random.nextBool();
      if (roll) {
        picLeft.add(diffComponent);
      } else {
        picRight.add(diffComponent);
      }

      final diffData = DiffData(
        rect: scaledRect,
        component: diffComponent,
      );
      _diffs.add(diffData);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final startPoint = _spotIndicatorsPosition.clone();
    for (var i = 0; i < _diffs.length; ++i) {
      if (i < _foundedCount) {
        found.render(
          canvas,
          position: startPoint,
          size: Vector2.all(GameUI.miniGameIndicatorIconSize),
        );
      } else {
        hidden.render(
          canvas,
          position: startPoint,
          size: Vector2.all(GameUI.miniGameIndicatorIconSize),
        );
      }
      startPoint.x += GameUI.miniGameIndicatorIconSize;
    }

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
