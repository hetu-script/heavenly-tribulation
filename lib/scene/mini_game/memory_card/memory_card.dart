import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/cardgame/cardgame.dart';
// import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/components/ui/sprite_button.dart';
import 'package:samsara/effect/confetti.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:samsara/components/ui/rich_text_component.dart';

import '../../cursor_state.dart';
import '../../common.dart';
import '../../../data/common.dart';
import '../../../global.dart';
import '../../../ui.dart';
import '../../../data/game.dart';
import '../common.dart';

class MemoryCardGame extends Scene with HasCursorState {
  final List<CustomGameCard> cards = [];
  final math.Random random = math.Random();

  late MiniGameDifficulty difficulty;
  late int cardKindCount; // 卡牌种类数
  late int cardTotalCount; // 卡牌总数
  late int gridColumns; // 网格列数
  late int gridRows; // 网格行数

  late Vector2 cardSize;
  late Vector2 gridStartPosition;

  late final SpriteComponent _victoryPrompt, _defeatPrompt;

  late final SpriteButton restart, exit;

  late final SpriteComponent2 barrier;

  late final RichTextComponent _flipCountText;

  // 游戏状态
  CustomGameCard? _firstFlippedCard;
  CustomGameCard? _secondFlippedCard;
  bool _isChecking = false; // 防止在检查过程中点击其他卡牌
  bool isGameOver = false;
  bool isGameWon = false;

  int _flipCount = 0;
  late int maxFlips;

  FutureOr<void> Function()? onGameStart;
  FutureOr<dynamic> Function(bool won)? onGameEnd;

  MemoryCardGame({
    required this.difficulty,
    this.onGameStart,
    this.onGameEnd,
  }) : super(
          id: Scenes.memoryCardGame,
          bgm: engine.bgm,
          bgmFile: 'Serenity of the East.mp3',
          bgmVolume: 0.5,
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
        (availableWidth - (gridColumns - 1) * GameUI.smallIndent) / gridColumns;

    // 根据宽度计算高度
    final cardHeight = maxCardWidth * GameUI.cardSizeRatio;

    // 检查高度是否超出屏幕
    final estimateHeight =
        cardHeight * gridRows + (gridRows - 1) * GameUI.smallIndent;

    if (estimateHeight > availableHeight) {
      // 如果高度超出，以高度为准重新计算
      final maxCardHeight =
          (availableHeight - (gridRows - 1) * GameUI.smallIndent) / gridRows;
      final cardWidth = maxCardHeight / GameUI.cardSizeRatio;
      cardSize = Vector2(cardWidth, maxCardHeight);
    } else {
      cardSize = Vector2(maxCardWidth, cardHeight);
    }

    // 计算网格起始位置（居中）
    final totalWidth =
        cardSize.x * gridColumns + (gridColumns - 1) * GameUI.smallIndent;
    final totalHeight =
        cardSize.y * gridRows + (gridRows - 1) * GameUI.smallIndent;

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

    barrier = SpriteComponent2(
      size: size,
      color: GameUI.barrierColor,
      priority: 10000,
      isVisible: false,
    );
    world.add(barrier);

    _victoryPrompt = SpriteComponent(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: await Sprite.load('ui/victory.png'),
      size: Vector2(480.0, 240.0),
    );
    _defeatPrompt = SpriteComponent(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: await Sprite.load('ui/defeat.png'),
      size: Vector2(480.0, 240.0),
    );

    _flipCountText = RichTextComponent(
      text: '',
      anchor: Anchor.topCenter,
      position: Vector2(center.x, GameUI.size.y - GameUI.largeIndent),
      size: Vector2(400, 40),
      config: ScreenTextConfig(
        anchor: Anchor.topCenter,
        size: Vector2(400, 40),
        textStyle: TextStyle(
          fontFamily: GameUI.fontFamilyLishu,
          fontSize: 24.0,
          color: Colors.white,
        ),
      ),
    );
    camera.viewport.add(_flipCountText);

    final background = SpriteComponent(
      sprite: await Sprite.load('mini_game/background2.png'),
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
      _endScene(isGameWon);
    };
    camera.viewport.add(exit);

    await _initializeGame();
  }

  Future<void> _initializeGame() async {
    engine.bgm.resume();

    for (final card in cards) {
      card.removeFromParent();
    }
    cards.clear();
    _victoryPrompt.removeFromParent();
    _defeatPrompt.removeFromParent();
    restart.isVisible = false;
    exit.position = GameUI.exitButtonPosition;

    isGameOver = false;
    barrier.isVisible = false;
    restart.isVisible = false;

    _flipCount = 0;

    // 根据难度设置卡牌数量和网格布局
    switch (difficulty) {
      case MiniGameDifficulty.easy:
        cardKindCount = 6;
        maxFlips = 20;
        gridRows = 3;
        gridColumns = 4;
      case MiniGameDifficulty.normal:
        cardKindCount = 8;
        maxFlips = 30;
        gridRows = 4;
        gridColumns = 4;
      case MiniGameDifficulty.challenging:
        cardKindCount = 12;
        maxFlips = 40;
        gridRows = 4;
        gridColumns = 6;
      case MiniGameDifficulty.hard:
        cardKindCount = 16;
        maxFlips = 50;
        gridRows = 4;
        gridColumns = 8;
      case MiniGameDifficulty.tough:
        cardKindCount = 20;
        maxFlips = 60;
        gridRows = 4;
        gridColumns = 10;
      case MiniGameDifficulty.brutal:
        cardKindCount = 24;
        maxFlips = 70;
        gridRows = 4;
        gridColumns = 12;
    }
    cardTotalCount = cardKindCount * 2;

    _updateFlipCountText();
    _calculateCardSize();

    // 获取所有可用的卡牌插画ID
    final allIllustrations = kBattleCardIllustrations.toList();
    allIllustrations.shuffle(random);

    // 根据难度选取对应数量的卡牌种类
    final selectedIllustrations = allIllustrations.take(cardKindCount).toList();

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
    await onGameStart?.call();
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
      if (_isChecking || isGameOver) return;
      card.showGlow = true;
    };
    card.onUnpreviewed = () {
      card.showGlow = false;
    };
    card.onTap = (button, position) {
      if (_isChecking || isGameOver) return;
      _onTapCard(card);
    };

    return card;
  }

  /// 布局卡牌，使用动画创建发牌效果
  void _layoutCards() {
    for (int i = 0; i < cards.length; i++) {
      final card = cards[i];

      // 计算卡牌的目标位置（网格位置）
      final row = i ~/ gridColumns;
      final col = i % gridColumns;

      final targetPosition = Vector2(
        gridStartPosition.x + col * (cardSize.x + GameUI.smallIndent),
        gridStartPosition.y + row * (cardSize.y + GameUI.smallIndent),
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

    ++_flipCount;
    _updateFlipCountText();

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
        _onGameOver(true);
      }
    } else {
      // 播放翻牌音效
      engine.play(GameSound.error);

      Future.delayed(const Duration(milliseconds: 500), () {
        // 匹配失败，翻回背面
        _firstFlippedCard!.isFlipped = true;
        _secondFlippedCard!.isFlipped = true;

        reset();

        // 翻牌次数用尽，游戏失败
        if (_flipCount >= maxFlips) {
          _onGameOver(false);
        }
      });
    }
  }

  void _updateFlipCountText() {
    final remaining = maxFlips - _flipCount;
    if (remaining <= maxFlips ~/ 4) {
      _flipCountText.text =
          '${engine.locale('memoryCardGame_flipsRemaining')}: <red>$remaining</>';
    } else {
      _flipCountText.text =
          '${engine.locale('memoryCardGame_flipsRemaining')}: <yellow>$remaining</>';
    }
  }

  void _onGameOver(bool won) {
    if (isGameOver) return;

    engine.bgm.pause();

    isGameOver = true;
    isGameWon = won;
    barrier.isVisible = true;

    if (won) {
      camera.viewport.add(_victoryPrompt);
      engine.play(GameSound.victory);

      final celebration = ConfettiEffect(
        size: size,
        priority: kConfettiPriority,
      );
      camera.viewport.add(celebration);
    } else {
      camera.viewport.add(_defeatPrompt);
      engine.play(GameSound.gameOver);
    }

    restart.isVisible = engine.config.debugMode;
    restart.position = Vector2(
        center.x,
        _victoryPrompt.bottomRight.y +
            GameUI.buttonSizeMedium.y +
            GameUI.largeIndent);

    exit.position = Vector2(center.x,
        restart.bottomRight.y + GameUI.buttonSizeMedium.y / 2 + GameUI.indent);
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
