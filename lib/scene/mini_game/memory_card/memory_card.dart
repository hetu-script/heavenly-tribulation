import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/cardgame/cardgame.dart';
// import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/components/ui/sprite_button.dart';
import 'package:samsara/effect/confetti.dart';

import '../../cursor_state.dart';
import '../../common.dart';
import '../../../data/common.dart';
import '../../../global.dart';
import '../../../ui.dart';
import '../../../data/game.dart';

const _kConfettiPriority = 1000;

const _kCardKindCount = 12;
const _kGridColumns = 8; // 每行8张
const _kGridRows = 3; // 每列3张
const _kCardSpacing = 10.0; // 卡牌间距

class MemoryCardGame extends Scene with HasCursorState {
  final List<CustomGameCard> cards = [];
  final math.Random random = math.Random();

  late Vector2 cardSize;
  late Vector2 gridStartPosition;

  late final SpriteComponent _victoryPrompt;

  late final SpriteButton restart, exit;

  // 游戏状态
  CustomGameCard? _firstFlippedCard;
  CustomGameCard? _secondFlippedCard;
  bool _isChecking = false; // 防止在检查过程中点击其他卡牌

  MemoryCardGame()
      : super(
          id: Scenes.memoryCardGame,
        );

  /// 计算卡牌大小以适应屏幕
  void _calculateCardSize() {
    // 计算可用宽度和高度
    final availableWidth = size.x;
    final availableHeight = size.y -
        kUIOverlayHeight -
        GameUI.buttonSizeMedium.y -
        GameUI.indent * 2;

    // 计算单张卡牌的最大宽度（根据列数）
    final maxCardWidth =
        (availableWidth - (_kGridColumns - 1) * _kCardSpacing) / _kGridColumns;

    // 根据宽度计算高度
    final cardHeight = maxCardWidth * GameUI.cardSizeRatio;

    // 检查高度是否超出屏幕
    final estimateHeight =
        cardHeight * _kGridRows + (_kGridRows - 1) * _kCardSpacing;

    if (estimateHeight > availableHeight) {
      // 如果高度超出，以高度为准重新计算
      final maxCardHeight =
          (availableHeight - (_kGridRows - 1) * _kCardSpacing) / _kGridRows;
      final cardWidth = maxCardHeight / GameUI.cardSizeRatio;
      cardSize = Vector2(cardWidth, maxCardHeight);
    } else {
      cardSize = Vector2(maxCardWidth, cardHeight);
    }

    // 计算网格起始位置（居中）
    final totalWidth =
        cardSize.x * _kGridColumns + (_kGridColumns - 1) * _kCardSpacing;
    final totalHeight =
        cardSize.y * _kGridRows + (_kGridRows - 1) * _kCardSpacing;

    gridStartPosition = Vector2(
        (size.x - totalWidth) / 2,
        (size.y -
                    kUIOverlayHeight -
                    GameUI.buttonSizeMedium.y -
                    GameUI.indent * 2 -
                    totalHeight) /
                2 +
            kUIOverlayHeight);
  }

  @override
  void onLoad() async {
    super.onLoad();

    _victoryPrompt = SpriteComponent(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: await Sprite.load('ui/victory.png'),
      size: Vector2(480.0, 240.0),
    );

    final background = SpriteComponent(
      sprite: await Sprite.load('mini_game/memory/background.png'),
      size: size,
    );
    world.add(background);

    restart = SpriteButton(
      spriteId: 'ui/button2.png',
      size: GameUI.buttonSizeMedium,
      anchor: Anchor.center,
      position: GameUI.restartButtonPosition,
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
      engine.popScene(clearCache: true);
    };
    camera.viewport.add(exit);

    _calculateCardSize();
    await _initializeGame();
  }

  Future<void> _initializeGame() async {
    for (final card in cards) {
      card.removeFromParent();
    }
    cards.clear();
    _victoryPrompt.removeFromParent();
    restart.isVisible = false;
    exit.position = GameUI.exitButtonPosition;

    // 获取所有可用的卡牌插画ID
    final allIllustrations = kBattleCardIllustrations.toList();
    allIllustrations.shuffle(random);

    // 选取前12种
    final selectedIllustrations =
        allIllustrations.take(_kCardKindCount).toList();

    // 为每种卡牌创建2张（配对游戏需要）
    for (int i = 0; i < selectedIllustrations.length; i++) {
      final illustrationId = selectedIllustrations[i];

      // 创建第一张卡牌
      final card1 = await _createCard(illustrationId, i * 2);
      cards.add(card1);

      // 创建第二张卡牌（配对的）
      final card2 = await _createCard(illustrationId, i * 2 + 1);
      cards.add(card2);
    }

    // 打乱所有卡牌
    cards.shuffle(random);

    // 将卡牌添加到场景并开始发牌动画
    for (int i = 0; i < cards.length; i++) {
      world.add(cards[i]);
    }

    _layoutCards();
  }

  /// 创建单张卡牌
  Future<CustomGameCard> _createCard(String illustrationId, int index) async {
    // 设置卡牌初始位置在屏幕中央
    final initialPosition =
        Vector2(size.x / 2 - cardSize.x / 2, size.y / 2 - cardSize.y / 2);

    final card = CustomGameCard(
      id: 'memory_card_${index}_$illustrationId',
      deckId: illustrationId,
      position: initialPosition,
      size: cardSize,
      preferredSize: GameUI.battleCardSize,
      spriteId: 'battlecard/border4.png',
      illustrationSpriteId: 'battlecard/illustration/$illustrationId.png',
      illustrationRelativePaddings:
          const EdgeInsets.fromLTRB(0.074, 0.135, 0.074, 0.235),
      backSpriteId: 'battlecard/cardback.png',
      isFlipped: true,
      showTitle: false,
      showDescription: true,
      description: engine.locale('illustration_$illustrationId'),
      descriptionRelativePaddings:
          const EdgeInsets.fromLTRB(0.108, 0.735, 0.108, 0.08),
      descriptionConfig: const ScreenTextConfig(
        anchor: Anchor.center,
        textStyle: TextStyle(
          fontFamily: GameUI.fontFamilyBlack,
          fontSize: 12.0,
          color: Colors.black,
        ),
        overflow: ScreenTextOverflow.wordwrap,
      ),
      glowSpriteId: 'battlecard/glow2.png',
    );
    card.onPreviewed = () {
      if (_isChecking) return;
      card.showGlow = true;
    };
    card.onUnpreviewed = () {
      card.showGlow = false;
    };
    card.onTap = (button, position) {
      _onTapCard(card);
    };

    return card;
  }

  /// 布局卡牌，使用动画创建发牌效果
  void _layoutCards() {
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];

      // 计算卡牌的目标位置（网格位置）
      final row = i ~/ _kGridColumns;
      final col = i % _kGridColumns;

      final targetPosition = Vector2(
        gridStartPosition.x + col * (cardSize.x + _kCardSpacing),
        gridStartPosition.y + row * (cardSize.y + _kCardSpacing),
      );

      engine.play(GameSound.dealDeck);
      // 使用延迟和动画创建逐张发牌的效果
      // 这里不用schedule，因为等上一张到位再发下一张的话太慢了
      Future.delayed(Duration(milliseconds: i * 30), () {
        card.moveTo(
          toPosition: targetPosition,
          duration: 0.3,
          curve: Curves.easeOutCubic,
          onComplete: () {
            card.enablePreview = true;
          },
        );
      });
    }
  }

  void _onTapCard(CustomGameCard card) {
    // 如果正在检查中，或者卡牌已经配对成功，或者卡牌已经翻开，则忽略点击
    if (_isChecking || !card.isFlipped) {
      return;
    }

    // 翻开卡牌
    card.isFlipped = false;
    engine.play(GameSound.flip);

    // 如果是第一张卡牌
    if (_firstFlippedCard == null) {
      _firstFlippedCard = card;
    }
    // 如果是第二张卡牌
    else if (_secondFlippedCard == null && card != _firstFlippedCard) {
      _secondFlippedCard = card;
      _isChecking = true;

      // 延迟检查，让玩家看清第二张卡牌
      _checkMatch();
    }
  }

  /// 检查两张卡牌是否匹配
  void _checkMatch() {
    void reset() {
      // 重置状态
      _firstFlippedCard = null;
      _secondFlippedCard = null;
      _isChecking = false;
    }

    if (_firstFlippedCard == null || _secondFlippedCard == null) {
      reset();
      return;
    }

    // 检查两张卡牌的插图是否相同（通过deckId判断）
    if (_firstFlippedCard!.deckId == _secondFlippedCard!.deckId) {
      // 播放成功音效
      engine.play(GameSound.success);

      // 禁用已配对卡牌的预览功能
      _firstFlippedCard!.showGlow = false;
      _firstFlippedCard!.enablePreview = false;
      _secondFlippedCard!.showGlow = false;
      _secondFlippedCard!.enablePreview = false;

      reset();

      // 检查是否所有卡牌都已配对
      bool allMatched = true;
      for (final card in cards) {
        if (card.isFlipped) {
          allMatched = false;
          break;
        }
      }
      if (allMatched) {
        _onGameSuccess();
      }
    } else {
      // 播放翻牌音效
      engine.play(GameSound.error);

      Future.delayed(const Duration(milliseconds: 500), () {
        // 匹配失败，翻回背面
        _firstFlippedCard!.isFlipped = true;
        _secondFlippedCard!.isFlipped = true;

        reset();
      });
    }
  }

  /// 游戏完成
  void _onGameSuccess() {
    engine.play(GameSound.victory);

    restart.isVisible = true;
    camera.viewport.add(_victoryPrompt);

    final celebration = ConfettiEffect(
      size: size,
      priority: _kConfettiPriority,
    );
    camera.viewport.add(celebration);

    restart.position = Vector2(
        center.x,
        _victoryPrompt.bottomRight.y +
            GameUI.buttonSizeMedium.y +
            GameUI.largeIndent);

    exit.position = Vector2(center.x,
        restart.bottomRight.y + GameUI.buttonSizeMedium.y / 2 + GameUI.indent);
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
