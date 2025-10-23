import 'dart:async';
import 'dart:math' as math;

import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:hetu_script/utils/math.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flame/flame.dart';
import 'package:samsara/components/ui/sprite_button.dart';
import 'package:samsara/tilemap/tile_info.dart';
import 'package:samsara/components/ui/hovertip.dart';
import 'package:provider/provider.dart';

import '../../../engine.dart';
import '../../../ui.dart';
import '../../../data/game.dart';
import '../../../logic/logic.dart';
import '../../../widgets/ui_overlay.dart';
import 'collect_panel.dart';
import '../../../data/common.dart';
import '../../cursor_state.dart';
import '../../../state/states.dart';

const _kTileCoverPriority = 500;
const _kDraggingPriority = 1000;

// 根据资源类型决定起点图标的图片索引
const _kMatchingGameKindToSourceSpriteIndex = {
  'farmland': 60,
  'timberland': 61,
  'fishery': 62,
  'huntingground': 63,
  'mine': 64,
};

/// 根据资源类型决定所生成的物品的图标的起始索引
const _kMatchingGameTypeToSpriteRow = {
  'farmland': (1, 4),
  'timberland': (5, 4),
  'fishery': (0, 2),
  'huntingground': (3, 2),
  'mine': (6, 7),
};

const _kObjectRowToMaterial = {
  0: 'water',
  1: 'grain',
  2: 'meat',
  3: 'leather',
  4: 'herb',
  5: 'timber',
  6: 'stone',
  7: 'ore',
  8: 'money',
  9: 'shard',
};

const kRarityCount = kRarityMax + 1;
const kProductionBaseMaxRarity = 3;

const _kMatchingGameMoneyObjectSpriteRow = (8, 9);
const _centerTilePosition = TilePosition(5, 3);
const _kProductionBaseAmount = 5;
const _kWorkSalaryFactor = 0.65;

const _kMoneyObjectRarityToCount = 400;

typedef TileObject = SpriteButton<(int, int)>;

class _Grid extends GameComponent {
  final int left;
  final int top;

  TilePosition get tilePosition => TilePosition(left, top);

  bool isHidden = true;
  bool isLocked = false;
  bool get isOccupied => object != null;

  // 按钮上保存的是图片 index 和 grid index
  TileObject? object;

  final Vector2 tileSize;

  _Grid(
    this.left,
    this.top, {
    required this.tileSize,
  }) : super(
          priority: _kTileCoverPriority,
        );

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();

    position = (game as MatchingGame).tilePositionToWorldPosition(left, top);
  }

  @override
  void render(Canvas canvas) {
    if (isHidden) {
      (game as MatchingGame)
          .hiddenTileSpriteSheet
          .getSprite(top, left)
          .render(canvas, size: tileSize);
    }
  }
}

class MatchingGame extends Scene with HasCursorState {
  static final random = math.Random();

  late FpsComponent fps;

  final fluent.FlyoutController menuController = fluent.FlyoutController();

  late final SpriteSheet hiddenTileSpriteSheet,
      iconSpriteSheet,
      iconHoverSpriteSheet;

  final String kind;

  late final SpriteComponent2 board;

  /// 记录地砖是否被掀开
  late final List<_Grid> _grids = [];

  late Vector2 scaleFactor;
  late Vector2 tileSize;

  late final TileObject sourceButton;

  late final Sprite border;

  final int development;
  final int maxRarity;
  final bool isProduction;

  final List<CollectPanel> collectPanels = [];

  final int staminaCost;
  final dynamic resources;

  late final boardCenter = tilePositionToWorldPosition(
          _centerTilePosition.left, _centerTilePosition.top) +
      GameUI.matchingTileSrcSize / 2;

  MatchingGame({
    required super.id,
    required super.context,
    required this.kind,
    this.development = 0,
    required this.isProduction,
    required this.staminaCost,
    required this.resources,
  })  : assert(kProductionSiteKinds.contains(kind)),
        assert(
            development >= 0 && development <= kProductionSiteDevelopmentMax),
        maxRarity = development + kProductionBaseMaxRarity,
        super(
          enableLighting: false,
          bgm: engine.bgm,
          bgmFile: 'vietnam-bamboo-flute-143601.mp3',
          bgmVolume: 0.5,
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();

    fps = FpsComponent();

    final exit = SpriteButton(
      spriteId: 'ui/button.png',
      size: GameUI.buttonSizeMedium,
      position: Vector2(size.x - GameUI.buttonSizeMedium.x - GameUI.indent,
          size.y - GameUI.buttonSizeMedium.y - GameUI.indent),
      text: engine.locale('exit'),
    );
    exit.onTap = (_, __) {
      engine.popScene(clearCache: true);
    };
    camera.viewport.add(exit);

    scaleFactor = Vector2(
        size.x / defaultGameSize.width, size.y / defaultGameSize.height);
    tileSize = Vector2(GameUI.matchingTileSrcSize.x * scaleFactor.x,
        GameUI.matchingTileSrcSize.y * scaleFactor.y);

    for (var i = 0;
        i < GameUI.matchingBoardGridWidth * GameUI.matchingBoardGridHeight;
        ++i) {
      final tilePosition = indexToTilePosition(i);
      final grid = _Grid(
        tilePosition.left,
        tilePosition.top,
        tileSize: tileSize,
      );
      world.add(grid);
      _grids.add(grid);
    }

    hiddenTileSpriteSheet = SpriteSheet(
      image: await Flame.images.load('mini_game/matching/tile_cover.png'),
      srcSize: GameUI.matchingTileSrcSize,
    );
    iconSpriteSheet = SpriteSheet(
      image: await Flame.images.load('mini_game/matching/icon.png'),
      srcSize: GameUI.matchingTileSrcSize,
    );
    iconHoverSpriteSheet = SpriteSheet(
      image: await Flame.images.load('mini_game/matching/icon_hover.png'),
      srcSize: GameUI.matchingTileSrcSize,
    );

    board = SpriteComponent2(
      sprite: Sprite(await Flame.images.load('mini_game/matching/board.png')),
      size: size,
      enableGesture: true,
    );
    world.add(board);

    border = Sprite(await Flame.images.load('mini_game/matching/border.png'));

    final sourceIndex = _kMatchingGameKindToSourceSpriteIndex[kind]!;
    sourceButton = TileObject(
      position: tilePositionToWorldPosition(
          _centerTilePosition.left, _centerTilePosition.top),
      size: GameUI.matchingTileSrcSize,
      sprite: iconHoverSpriteSheet.getSpriteById(sourceIndex),
    );
    sourceButton.onTap = (buttons, position) {
      addNewObject();
    };
    sourceButton.onMouseEnter = () {
      Hovertip.show(
        scene: this,
        direction: HovertipDirection.bottomCenter,
        content: engine.locale('tileMathcing_sourceTile_description'),
        width: 360,
        config: ScreenTextConfig(textAlign: TextAlign.center),
        margin: const EdgeInsets.only(bottom: 50),
      );
    };
    sourceButton.onMouseExit = () {
      Hovertip.hide();
    };
    world.add(sourceButton);

    _grids[tilePositionToIndex(
            _centerTilePosition.left, _centerTilePosition.top)]
        .object = sourceButton;

    _addNewCollectPanel(isMain: true);
  }

  TilePosition worldPositionToTilePosition(Vector2 position) {
    position -= GameUI.matchingBoardOffset;
    final col = position.x ~/ tileSize.x;
    final row = position.y ~/ tileSize.y;
    return TilePosition(col, row);
  }

  Vector2 tilePositionToWorldPosition(int left, int top) {
    final x =
        GameUI.matchingBoardOffset.x + left * GameUI.matchingTileSrcSize.x;
    final y = GameUI.matchingBoardOffset.y + top * GameUI.matchingTileSrcSize.y;
    return Vector2(x * scaleFactor.x, y * scaleFactor.y);
  }

  int tilePositionToIndex(int left, int top) {
    return top * GameUI.matchingBoardGridWidth + left;
  }

  TilePosition indexToTilePosition(int index) {
    final col = index % GameUI.matchingBoardGridWidth;
    final row = index ~/ GameUI.matchingBoardGridWidth;
    return TilePosition(col, row);
  }

  void openTiles(List<(int, int)> positions) async {
    for (final pos in positions) {
      await Future.delayed(const Duration(milliseconds: 80));
      openTile(pos.$1, pos.$2);
    }
  }

  void openTile(int left, int top) {
    if (top < 0 ||
        top >= GameUI.matchingBoardGridHeight ||
        left < 0 ||
        left >= GameUI.matchingBoardGridWidth) {
      return;
    }

    final grid = _grids[tilePositionToIndex(left, top)];
    if (grid.isHidden) {
      grid.isHidden = false;
      if (grid.object != null) {
        world.add(grid.object!);
      }
    }
  }

  void _collectObject(TileObject object, {CollectPanel? panel}) {
    final objectIndex = object.value!.$1;
    final grid = _grids[object.value!.$2];
    final rarity = objectIndex % kRarityCount;

    final String materialId =
        _kObjectRowToMaterial[objectIndex ~/ kRarityCount]!;

    void removeObject() {
      grid.object = null;
      object.removeFromParent();
    }

    if (materialId == 'money' || materialId == 'shard') {
      removeObject();
      if (materialId == 'money') {
        final amount = (rarity + 1) * (rarity + 1) * _kMoneyObjectRarityToCount;
        engine.hetu.invoke(
          'collect',
          namespace: 'Player',
          positionalArgs: ['money', amount],
        );
        engine.play('coins-31879.mp3');
        hintTile('${engine.locale('money')} +$amount',
            tilePosition: grid.tilePosition, color: Colors.yellow);
        context.read<HeroState>().update();
      } else {
        final amount = rarity * rarity;
        engine.hetu.invoke(
          'collect',
          namespace: 'Player',
          positionalArgs: ['shard', amount],
        );
        engine.play('pickup_item-64282.mp3');
        hintTile('${engine.locale('shard')} +$amount',
            tilePosition: grid.tilePosition, color: Colors.yellow);
      }
      return;
    }

    if (rarity < kProductionBaseMaxRarity) {
      return;
    }

    void collectMain() {
      removeObject();
      int baseAmount = resources[materialId] ?? 0;
      baseAmount *= rarity - kProductionBaseMaxRarity + 1;
      final amount = _kProductionBaseAmount + random.nearInt(baseAmount);
      engine.info('在$kind生产了$amount $materialId');
      if (isProduction) {
        engine.hetu.invoke(
          'collect',
          namespace: 'Player',
          positionalArgs: [materialId, amount],
        );
        engine.play('pickup_item-64282.mp3');
        hintTile('${engine.locale(materialId)} +$amount',
            tilePosition: grid.tilePosition, color: Colors.lightGreen);
      } else {
        final price = kMaterialBasePrice[materialId]!;
        final totalPrice = (price * amount * _kWorkSalaryFactor).round();
        engine.hetu.invoke(
          'collect',
          namespace: 'Player',
          positionalArgs: ['money', totalPrice],
        );
        engine.play('coins-31879.mp3');
        hintTile('${engine.locale('money')} +$totalPrice',
            tilePosition: grid.tilePosition, color: Colors.yellow);
        context.read<HeroState>().update();
      }
    }

    if (panel != null) {
      if (panel.isMain) {
        if (panel.collection.containsKey(objectIndex)) {
          collectMain();
        }
      } else {
        panel.collect(objectIndex);
      }
    } else {
      bool collected = false;
      for (final panel in collectPanels.skip(1)) {
        if (panel.collection.containsKey(objectIndex)) {
          collected = panel.collect(objectIndex);
          if (collected) {
            removeObject();
            break;
          }
        }
      }
      if (!collected &&
          collectPanels.first.collection.containsKey(objectIndex)) {
        collectMain();
      }
    }
  }

  void _addObject(int left, int top, int spriteCol, int spriteRow) {
    final tileIndex = tilePositionToIndex(left, top);
    final grid = _grids[tileIndex];
    assert(!grid.isOccupied);
    final objectIndex = spriteRow * kRarityCount + spriteCol;
    final object = TileObject(
      value: (objectIndex, tileIndex),
      position: tilePositionToWorldPosition(
          _centerTilePosition.left, _centerTilePosition.top),
      size: GameUI.matchingTileSrcSize,
      sprite: iconSpriteSheet.getSpriteById(objectIndex),
      hoverSprite: iconHoverSpriteSheet.getSpriteById(objectIndex),
    );
    grid.object = object;

    object.onDragStart = (buttons, position) {
      object.priority += _kDraggingPriority;
      return object;
    };
    object.onDragEnd = (buttons, position) {
      object.priority -= _kDraggingPriority;
      final prevGrid = _grids[object.value!.$2];
      final tilePos = worldPositionToTilePosition(position);
      final tileIndex = tilePositionToIndex(tilePos.left, tilePos.top);
      if (tileIndex >= 0 && tileIndex < _grids.length) {
        final targetGrid = _grids[tileIndex];
        if (targetGrid.tilePosition != _centerTilePosition) {
          if (prevGrid != targetGrid && !targetGrid.isHidden) {
            if (targetGrid.object != null) {
              final data = object.value!;
              final targetObject = targetGrid.object!;
              if (data.$1 == targetObject.value!.$1) {
                final rarity = data.$1 % kRarityCount;
                if (rarity < maxRarity) {
                  prevGrid.object = null;
                  object.removeFromParent();
                  final upgradedIconIndex = data.$1 + 1;
                  targetObject.value = (upgradedIconIndex, tileIndex);
                  targetObject.sprite =
                      iconSpriteSheet.getSpriteById(upgradedIconIndex);
                  targetObject.hoverSprite =
                      iconHoverSpriteSheet.getSpriteById(upgradedIconIndex);
                  return;
                } else {
                  hintTile(
                    engine.locale('tileMatching_maxRarity_prompt'),
                    tilePosition: targetGrid.tilePosition,
                    color: Colors.red,
                  );
                }
              }
            } else {
              prevGrid.object = null;
              targetGrid.object = object;
              object.value = (object.value!.$1, tileIndex);
              object.position =
                  tilePositionToWorldPosition(tilePos.left, tilePos.top);
              return;
            }
          }
        }
      }
      object.position =
          tilePositionToWorldPosition(prevGrid.left, prevGrid.top);
    };
    object.onDragUpdate = (buttons, position, delta) {
      object.position += delta;
    };
    object.onMouseEnter = () {
      cursorState = MouseCursorState.click;
      final objectIndex = object.value!.$1;
      if (objectIndex >=
          (_kMatchingGameMoneyObjectSpriteRow.$2 * kRarityCount)) {
        Hovertip.show(
          scene: this,
          direction: HovertipDirection.bottomCenter,
          content: engine.locale('tileMatching_shard_object'),
          width: 360,
          config: ScreenTextConfig(textAlign: TextAlign.center),
          margin: const EdgeInsets.only(bottom: 50),
        );
      } else if (objectIndex >=
          (_kMatchingGameMoneyObjectSpriteRow.$1 * kRarityCount)) {
        Hovertip.show(
          scene: this,
          direction: HovertipDirection.bottomCenter,
          content: engine.locale('tileMatching_money_object'),
          width: 360,
          config: ScreenTextConfig(textAlign: TextAlign.center),
          margin: const EdgeInsets.only(bottom: 50),
        );
      } else {
        final rarity = objectIndex % kRarityCount;
        if (rarity >= maxRarity) {
          Hovertip.show(
            scene: this,
            direction: HovertipDirection.topCenter,
            content: engine.locale(isProduction
                ? 'tileMatching_maxRarity_description_production'
                : 'tileMatching_maxRarity_description_work'),
            width: 360,
            config: ScreenTextConfig(textAlign: TextAlign.center),
            margin: const EdgeInsets.only(bottom: 50),
          );
        }
      }
    };
    object.onMouseExit = () {
      cursorState = MouseCursorState.normal;
      Hovertip.hide();
    };
    object.onDoubleTap = (buttons, position) {
      _collectObject(object);
    };

    if (!grid.isHidden) {
      world.add(object);
    }

    object.enableGesture = false;
    object.moveTo(
      duration: 0.3,
      toPosition: tilePositionToWorldPosition(left, top),
      onComplete: () {
        object.enableGesture = true;
      },
    );
  }

  void addNewObject() async {
    final double life = GameData.hero['life'];
    if (life <= 1) {
      hintTile(
        engine.locale('hint_notEnoughStamina'),
        color: Colors.red,
      );
      return;
    }

    final availableGrids =
        _grids.where((grid) => !grid.isOccupied && !grid.isHidden);
    if (availableGrids.isEmpty) {
      hintTile('空间不足！', color: Colors.red);
      return;
    }
    final targetGrid = random.nextIterable(availableGrids);

    engine.hetu.invoke('setLife',
        namespace: 'Player',
        positionalArgs: [GameData.hero['life'] - staminaCost]);
    hintTile(
      engine.locale('${engine.locale('stamina')} -$staminaCost'),
      color: Colors.red,
    );
    context.read<HeroState>().update();

    schedule(() async {
      await GameLogic.updateGame(ticks: kTicksPerTime);

      int spriteRow = 0;
      int spriteCol = 0;
      final roll = random.nextDouble();
      if (roll < kRarityDistribution[development]) {
        if (development <= 0) {
          spriteRow = _kMatchingGameMoneyObjectSpriteRow.$1;
        } else {
          spriteRow = _kMatchingGameMoneyObjectSpriteRow.$2;
        }
      } else {
        final spriteRowData = _kMatchingGameTypeToSpriteRow[kind]!;
        final roll2 = random.nextDouble();
        if (roll2 < kSiteProductionMainMaterialProduceProbability[kind]!) {
          spriteRow = spriteRowData.$1;
        } else {
          spriteRow = spriteRowData.$2;
        }
      }
      final rarityRoll = random.nextDouble();
      for (var i = 0; i < kRarityCount; ++i) {
        if (rarityRoll < kRarityDistribution[i]) {
          spriteCol = kRarityMax - i;
          break;
        }
      }

      if (spriteCol > maxRarity) {
        spriteCol = maxRarity;
      }

      _addObject(targetGrid.left, targetGrid.top, spriteCol, spriteRow);

      switch (kind) {
        case 'farmland':
          engine.play('rustling-grass-1-101282.mp3');
        case 'timberland':
          engine.play('deeper-saw-wood-37224.mp3');
        case 'fishery':
          engine.play('saildeploy-99393.mp3');
        case 'huntingground':
          engine.play('dog-bark-419014.mp3');
        case 'mine':
          engine.play('axe-drop-1-rear-88428.mp3');
        default:
      }
    });
  }

  void _addNewCollectPanel({
    bool isMain = false,
  }) {
    if (collectPanels.length >= 3) return;

    final panel = CollectPanel(
      position: GameUI.collectPanelPosition +
          Vector2(
              0,
              collectPanels.length *
                  (GameUI.collectPanalSize.y + GameUI.smallIndent)),
      isMain: isMain,
      avatarId: 'avatar/npc/${kSiteKindToNpcId[kind]}.png',
    );
    panel.onDragIn = (buttons, position, object) {
      if (object is! TileObject) return;
      _collectObject(object, panel: panel);
    };
    collectPanels.add(panel);
    world.add(panel);
  }

  @override
  void onMount() {
    super.onMount();

    Hovertip.hideAll();

    openTiles([
      (5, 3),
      (5, 2),
      (6, 3),
      (5, 4),
      (4, 3),
      (5, 1),
      (6, 2),
      (7, 3),
      (6, 4),
      (5, 5),
      (4, 4),
      (3, 3),
      (4, 2),
      (5, 0),
      (6, 1),
      (7, 2),
      (8, 3),
      (7, 4),
      (6, 5),
      (5, 6),
      (4, 5),
      (3, 4),
      (2, 3),
      (3, 2),
      (4, 1),
    ]);
  }

  @override
  void update(double dt) {
    super.update(dt);

    fps.update(dt);
  }

  void hintTile(String text,
      {TilePosition? tilePosition, Color color = Colors.white}) {
    tilePosition ??= _centerTilePosition;
    Vector2 pos =
        tilePositionToWorldPosition(tilePosition.left, tilePosition.top);
    pos.x += GameUI.matchingTileSrcSize.x / 2;
    addHintText(
      text,
      position: pos,
      textStyle: TextStyle(
        fontFamily: GameUI.fontFamily,
        fontSize: 20,
        color: color,
      ),
    );
  }

  // @override
  // void render(Canvas canvas) {
  //   super.render(canvas);

  //   if (engine.config.debugMode || engine.config.showFps) {
  //     drawScreenText(
  //       canvas,
  //       'FPS: ${fps.fps.toStringAsFixed(0)}',
  //       config: ScreenTextConfig(
  //         textStyle: const TextStyle(fontSize: 20),
  //         size: size,
  //         anchor: Anchor.topCenter,
  //         padding: const EdgeInsets.only(top: 40),
  //       ),
  //     );
  //   }
  // }

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
          showActiveJournal: false,
          actions: [
            Container(
              decoration: GameUI.boxDecoration,
              child: IconButton(
                padding: const EdgeInsets.all(0),
                onPressed: () {
                  // GameDialogContent.show(
                  //   context,
                  //   engine.locale('hint_cultivation'),
                  //   style: TextStyle(color: Colors.yellow),
                  // );
                },
                icon: Icon(Icons.question_mark),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
