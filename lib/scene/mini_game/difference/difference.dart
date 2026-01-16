import 'dart:async';
import 'dart:math' as math;

import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:json5/json5.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:samsara/components/sprite_component2.dart';
import 'package:samsara/effect/confetti.dart';
import 'package:samsara/effect/fade.dart';
import 'package:flame/effects.dart';
import 'package:samsara/components/ui/sprite_button.dart';

import '../../../ui.dart';
import '../../../global.dart';
import '../../../widgets/ui_overlay.dart';

const _kPicPriority = 50;
const _kDiffIndicatorPriority = 10;
const _kErrorIndicatorPriority = 20;
const _kConfettiPriority = 100;

/// 椭圆标记组件，黄色圆圈内外都有黑色描边，带阴影
class FoundIndicator extends PositionComponent {
  final Paint _shadowPaint;
  final Paint _strokePaint;
  final Paint _fillerPaint;

  FoundIndicator({
    required super.position,
    required super.size,
    Color strokeColor = Colors.black26,
    Color fillerColor = Colors.yellow,
    double blackStrokeWidth = 3.0,
    double yellowStrokeWidth = 4.0,
    Color shadowColor = Colors.black,
    double shadowBlur = 6.0,
    super.priority,
  })  : _shadowPaint = Paint()
          ..color = shadowColor.withValues(alpha: 100)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur)
          ..style = PaintingStyle.stroke
          ..strokeWidth =
              blackStrokeWidth + yellowStrokeWidth + blackStrokeWidth
          ..isAntiAlias = true,
        _strokePaint = Paint()
          ..color = strokeColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = blackStrokeWidth
          ..isAntiAlias = true,
        _fillerPaint = Paint()
          ..color = fillerColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = yellowStrokeWidth
          ..isAntiAlias = true;

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
  final Sprite sprite;
  bool found = false;

  DiffData({
    required this.rect,
    required this.sprite,
  });
}

class DifferenceGame extends Scene {
  static final random = math.Random();

  final fluent.FlyoutController menuController = fluent.FlyoutController();

  final String gameId;

  final List<DiffData> diffs = [];

  late SpriteComponent2 picLeft, picRight;

  double _zoom = 1.0;

  late Sprite _errorIndicatorSprite;

  bool successed = false;

  late final SpriteComponent _victoryPrompt;

  late final SpriteButton next, exit;

  late final Sprite hidden, found;

  int _foundedCount = 0;

  DifferenceGame({
    required super.id,
    required this.gameId,
  });

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
      GameComponent component, int button, Vector2 position) {
    if (button != kPrimaryButton) return;
    if (successed) return;

    bool found = false;
    for (final diff in diffs) {
      if (diff.found) continue;
      if (diff.rect.contains(Offset(position.x, position.y))) {
        // 找到差异，执行相应操作
        // debugPrint('Found difference at (${diff.rect.left}, ${diff.rect.top})');
        diff.found = found = true;
        ++_foundedCount;
        engine.play('new-notification-026-380249.mp3');

        // 需要创建两个独立的组件实例，因为一个组件只能有一个父组件
        final indicatorLeft = FoundIndicator(
          position: diff.rect.topLeft.toVector2(),
          size: diff.rect.size.toVector2(),
          priority: _kDiffIndicatorPriority,
        );
        picLeft.add(indicatorLeft);
        final indicatorRight = FoundIndicator(
          position: diff.rect.topLeft.toVector2(),
          size: diff.rect.size.toVector2(),
          priority: _kDiffIndicatorPriority,
        );
        picRight.add(indicatorRight);

        // 检查是否所有差异都已找到
        if (diffs.every((d) => d.found)) {
          successed = true;

          _gameSuccess();
        }

        break;
      }
    }

    if (!found) {
      final error = _triggerError(position);
      component.add(error);

      engine.play('notification-error-427345.mp3');
    }
  }

  GameComponent _triggerError(Vector2 worldPosition) {
    // 在世界坐标系中添加错误指示器
    final indicator = SpriteComponent2(
      sprite: _errorIndicatorSprite,
      position: worldPosition - Vector2(16.0, 16.0),
      size: Vector2(32.0, 32.0),
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

  void _gameSuccess() {
    Future.delayed(Duration(milliseconds: 500)).then((_) {
      engine.play('transition/chinese-ident-transition-1-283708.mp3');
    });

    camera.viewport.add(_victoryPrompt);

    final celebration = Celebration(
      position: Vector2.zero(),
      size: size.clone(),
      priority: _kConfettiPriority,
    );
    camera.viewport.add(celebration);

    next.isVisible = true;

    exit.position = Vector2(center.x,
        next.bottomRight.y + GameUI.buttonSizeMedium.y / 2 + GameUI.indent);
  }

  @override
  void onLoad() async {
    super.onLoad();

    _errorIndicatorSprite = await Sprite.load(
      'mini_game/difference/error.png',
    );

    _victoryPrompt = SpriteComponent(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: await Sprite.load('ui/victory.png'),
      size: Vector2(480.0, 240.0),
    );

    final background = SpriteComponent(
      sprite: await Sprite.load('mini_game/difference/background.png'),
    );
    world.add(background);

    hidden = await Sprite.load(
      'mini_game/difference/question_mark.png',
    );
    found = await Sprite.load(
      'mini_game/difference/check_mark.png',
    );

    next = SpriteButton(
      spriteId: 'ui/button2.png',
      size: GameUI.buttonSizeMedium,
      anchor: Anchor.center,
      position: Vector2(
          center.x,
          _victoryPrompt.bottomRight.y +
              GameUI.buttonSizeMedium.y +
              GameUI.largeIndent),
      text: engine.locale('continue'),
      isVisible: false,
    );
    next.onTap = (_, __) {};
    camera.viewport.add(next);

    exit = SpriteButton(
      spriteId: 'ui/button.png',
      size: GameUI.buttonSizeMedium,
      anchor: Anchor.center,
      position: Vector2(size.x - GameUI.buttonSizeMedium.x / 2 - GameUI.indent,
          size.y - GameUI.buttonSizeMedium.y / 2 - GameUI.indent),
      text: engine.locale('exit'),
    );
    exit.onTap = (_, __) {
      engine.popScene(clearCache: true);
    };
    camera.viewport.add(exit);

    picLeft = SpriteComponent2(
      sprite:
          await Sprite.load('mini_game/difference/library/$gameId/main.png'),
      position: Vector2(
          GameUI.differenceGameLeftBarWidth, GameUI.differenceGameTopBarHeight),
      size: GameUI.differenceGamePictureSize,
      priority: _kPicPriority,
      enableGesture: true,
      clipMode: true,
    );
    picLeft.onMouseScrollUp = (position) {
      setZoom(_zoom + 0.25, position);
    };
    picLeft.onMouseScrollDown = (position) {
      setZoom(_zoom - 0.25, position);
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
      sprite:
          await Sprite.load('mini_game/difference/library/$gameId/main.png'),
      position: Vector2(
          GameUI.differenceGameLeftBarWidth +
              GameUI.differenceGamePictureSize.x,
          GameUI.differenceGameTopBarHeight),
      size: GameUI.differenceGamePictureSize,
      priority: _kPicPriority,
      enableGesture: true,
      clipMode: true,
    );
    picRight.onMouseScrollUp = (position) {
      setZoom(_zoom + 0.25, position);
    };
    picRight.onMouseScrollDown = (position) {
      setZoom(_zoom - 0.25, position);
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

    final gameDataString = await rootBundle.loadString(
        'assets/images/mini_game/difference/library/$gameId/config.json5');
    final diffData = json5Decode(gameDataString);
    final indices = List.generate(20, (i) => i)..shuffle();
    final selectedDiffs = {for (var i in indices.take(10)) i: diffData[i]};

    // 获取原始图片尺寸
    final originalSize = picRight.sprite!.srcSize;
    // 计算缩放比例：显示尺寸 / 原始尺寸
    final scaleX = GameUI.differenceGamePictureSize.x / originalSize.x;
    final scaleY = GameUI.differenceGamePictureSize.y / originalSize.y;

    for (final index in selectedDiffs.keys) {
      final data = selectedDiffs[index];
      final sprite = await Sprite.load(
          'mini_game/difference/library/$gameId/p${index + 1}.png');

      final ratio =
          GameUI.differenceGamePictureSize.x / picLeft.sprite!.srcSize.x;
      final scaledRect = Rect.fromLTWH(data['left'] * ratio,
          data['top'] * ratio, data['width'] * ratio, data['height'] * ratio);
      final diffData = DiffData(
        rect: scaledRect,
        sprite: sprite,
      );
      diffs.add(diffData);

      // 将贴片作为子组件添加到右侧图片上
      // 坐标从原始图片坐标映射到显示坐标
      final diffComponent = SpriteComponent(
        sprite: sprite,
        position: Vector2(
          (data['left'] as num).toDouble() * scaleX,
          (data['top'] as num).toDouble() * scaleY,
        ),
        size: Vector2(
          (data['width'] as num).toDouble() * scaleX,
          (data['height'] as num).toDouble() * scaleY,
        ),
      );
      final roll = random.nextBool();
      if (roll) {
        picLeft.add(diffComponent);
      } else {
        picRight.add(diffComponent);
      }
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final startPoint = GameUI.spotIndicatorsPosition.clone();

    for (var i = 0; i < 10; ++i) {
      if (i < _foundedCount) {
        found.render(
          canvas,
          position: startPoint,
          size: Vector2.all(GameUI.spotIndicatorSize),
        );
      } else {
        hidden.render(
          canvas,
          position: startPoint,
          size: Vector2.all(GameUI.spotIndicatorSize),
        );
      }
      startPoint.x += GameUI.spotIndicatorSize;
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
