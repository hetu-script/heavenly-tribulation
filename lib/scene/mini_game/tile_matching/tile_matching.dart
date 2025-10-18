import 'dart:math' as math;

import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/game/common.dart';
import 'package:hetu_script/utils/math.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:samsara/task.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flame/flame.dart';
import 'package:samsara/components/ui/sprite_button.dart';
import 'package:samsara/tilemap/tile_info.dart';

import '../../../engine.dart';
import '../../../ui.dart';
import '../../../widgets/ui_overlay.dart';

class TileMatchingGameGrid {
  final int left;
  final int top;

  bool isHidden;
  bool isLocked;
  bool get isOccupied => object != null;

  // 按钮上保存的是图片 index 和 grid index
  SpriteButton<(int, int)>? object;

  TileMatchingGameGrid(
    this.left,
    this.top, {
    this.isHidden = true,
    this.isLocked = false,
  });
}

// 根据资源类型决定起点图标的图片索引
const _kTileMatchingGameTypeToSourceSpriteIndex = {
  'farmland': 60,
  'timberland': 61,
  'fishery': 62,
  'huntingground': 63,
  'mine': 64,
};

/// 根据资源类型决定所生成的物品的图标的起始索引
const _kTileMatchingGameTypeToSpriteRow = {
  'farmland': (1, 4),
  'timberland': (5, 4),
  'fishery': (0, 2),
  'huntingground': (3, 2),
  'mine': (6, 7),
};

const _kTileMatchingGameMoneyObjectIndices = (8, 9);

final _kMoneyObjectProbability = 0.05;

const _iconSpriteColumns = 6;

const _sourceIconPosition = TilePosition(5, 3);

const _kDraggingPriority = 1000;

class TileMatchingGameScene extends Scene {
  static final random = math.Random();

  late FpsComponent fps;

  final TaskController taskController = TaskController();

  final fluent.FlyoutController menuController = fluent.FlyoutController();

  late final SpriteSheet hiddenTileSpriteSheet,
      iconSpriteSheet,
      iconHoverSpriteSheet;

  final String type;

  late final SpriteComponent2 board;

  /// 记录地砖是否被掀开
  late final List<TileMatchingGameGrid> _grids;

  late double scaleFactor;
  late Vector2 tileSize;

  late final SpriteButton<(int, int)> sourceButton;

  late final Sprite border;

  TileMatchingGameGrid? mouseHoverGrid;

  final int maxRarity;

  TileMatchingGameScene({
    required super.id,
    // required super.controller,
    required super.context,
    required this.type,
    int development = 0,
    super.bgm,
    super.bgmFile,
    super.bgmVolume = 0.5,
  })  : assert(kProductionSiteKinds.contains(type)),
        maxRarity = math.min(development + 2, kRarityMax),
        super(enableLighting: false) {
    _grids = List.generate(
        GameUI.tileMatchingGameBoardGridWidth *
            GameUI.tileMatchingGameBoardGridHeight, (i) {
      final tilePosition = indexToTilePosition(i);
      return TileMatchingGameGrid(tilePosition.left, tilePosition.top);
    });
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    fps = FpsComponent();

    scaleFactor = size.x / 1440.0;
    tileSize = GameUI.tileMatchingGameTileSrcSize * scaleFactor;

    hiddenTileSpriteSheet = SpriteSheet(
      image: await Flame.images.load('mini_game/tile_matching/tile_cover.png'),
      srcSize: GameUI.tileMatchingGameTileSrcSize,
    );
    iconSpriteSheet = SpriteSheet(
      image: await Flame.images.load('mini_game/tile_matching/icon.png'),
      srcSize: GameUI.tileMatchingGameTileSrcSize,
    );
    iconHoverSpriteSheet = SpriteSheet(
      image: await Flame.images.load('mini_game/tile_matching/icon_hover.png'),
      srcSize: GameUI.tileMatchingGameTileSrcSize,
    );

    board = SpriteComponent2(
      // position: Vector2(-size.x / 2, -size.y / 2),
      sprite:
          Sprite(await Flame.images.load('mini_game/tile_matching/board.png')),
      size: size,
      enableGesture: true,
    );
    board.onMouseHover = (Vector2 position) {
      final tilePosition = worldPositionToTilePosition(position);
      final tileIndex =
          tilePositionToIndex(tilePosition.left, tilePosition.top);
      if (tileIndex >= 0 && tileIndex < _grids.length) {
        mouseHoverGrid = _grids[tileIndex];
      }
    };
    world.add(board);

    border =
        Sprite(await Flame.images.load('mini_game/tile_matching/border.png'));

    final sourceIndex = _kTileMatchingGameTypeToSourceSpriteIndex[type]!;
    sourceButton = SpriteButton<(int, int)>(
      position:
          getTilePosition(_sourceIconPosition.left, _sourceIconPosition.top),
      size: GameUI.tileMatchingGameTileSrcSize,
      sprite: iconSpriteSheet.getSpriteById(sourceIndex),
      hoverSprite: iconHoverSpriteSheet.getSpriteById(sourceIndex),
    );
    sourceButton.onTap = (buttons, position) {
      addNewTileObject();
    };
    world.add(sourceButton);

    _grids[tilePositionToIndex(
            _sourceIconPosition.left, _sourceIconPosition.top)]
        .object = sourceButton;
  }

  void openTiles(List<(int, int)> positions) async {
    for (final pos in positions) {
      await Future.delayed(const Duration(milliseconds: 80));
      openTile(pos.$1, pos.$2);
    }
  }

  void openTile(int left, int top) {
    if (top < 0 ||
        top >= GameUI.tileMatchingGameBoardGridHeight ||
        left < 0 ||
        left >= GameUI.tileMatchingGameBoardGridWidth) {
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

  void _addTileObject(int left, int top, int spriteCol, int spriteRow) {
    final tileIndex = tilePositionToIndex(left, top);
    final grid = _grids[tileIndex];
    assert(!grid.isOccupied);
    final spriteIndex = spriteRow * _iconSpriteColumns + spriteCol;
    final button = SpriteButton<(int, int)>(
      value: (spriteIndex, tileIndex),
      position:
          getTilePosition(_sourceIconPosition.left, _sourceIconPosition.top),
      size: GameUI.tileMatchingGameTileSrcSize,
      sprite: iconSpriteSheet.getSpriteById(spriteIndex),
      hoverSprite: iconHoverSpriteSheet.getSpriteById(spriteIndex),
    );
    grid.object = button;

    button.onDragStart = (buttons, position) {
      button.priority += _kDraggingPriority;
      return button;
    };
    button.onDragEnd = (buttons, position) {
      button.priority -= _kDraggingPriority;
      final prevGrid = _grids[button.value!.$2];
      final tilePos = worldPositionToTilePosition(position);
      final tileIndex = tilePositionToIndex(tilePos.left, tilePos.top);
      if (tileIndex >= 0 && tileIndex < _grids.length) {
        final targetGrid = _grids[tileIndex];

        if (prevGrid != targetGrid && !targetGrid.isHidden) {
          if (targetGrid.object != null) {
            final data = button.value!;
            final targetObject = targetGrid.object!;
            if (data.$1 == targetObject.value!.$1) {
              final rarity = data.$1 % _iconSpriteColumns;
              if (rarity < maxRarity) {
                prevGrid.object = null;
                button.removeFromParent();
                final upgradedIconIndex = data.$1 + 1;
                targetObject.value = (upgradedIconIndex, tileIndex);
                targetObject.sprite =
                    iconSpriteSheet.getSpriteById(upgradedIconIndex);
                targetObject.hoverSprite =
                    iconHoverSpriteSheet.getSpriteById(upgradedIconIndex);
                return;
              }
            }
          } else {
            prevGrid.object = null;
            targetGrid.object = button;
            button.value = (button.value!.$1, tileIndex);
            button.position = getTilePosition(tilePos.left, tilePos.top);
            return;
          }
        }
      }
      button.position = getTilePosition(prevGrid.left, prevGrid.top);
    };
    button.onDragUpdate = (buttons, position, delta) {
      button.position += delta;
    };

    if (!grid.isHidden) {
      world.add(button);
    }

    button.moveTo(duration: 0.3, toPosition: getTilePosition(left, top));
  }

  void addNewTileObject() {
    final availableGrids =
        _grids.where((grid) => !grid.isOccupied && !grid.isHidden);

    if (availableGrids.isEmpty) {
      addHintText('空间不足！', target: sourceButton, color: Colors.red);
      return;
    }

    int spriteRow = 0;
    int spriteCol = 0;
    final roll = random.nextDouble();
    if (roll < _kMoneyObjectProbability) {
      spriteRow = _kTileMatchingGameMoneyObjectIndices.$1;
    } else {
      final spriteRowData = _kTileMatchingGameTypeToSpriteRow[type]!;
      spriteRow = spriteRowData.$1;
    }
    final rarityRoll = random.nextDouble();
    for (var i = 0; i < _iconSpriteColumns; ++i) {
      if (rarityRoll < kRarityDistribution[i]) {
        spriteCol = kRarityMax - i;
        break;
      }
    }

    if (spriteCol > maxRarity) {
      spriteCol = maxRarity;
    }

    final randomGrid = random.nextIterable(availableGrids);
    _addTileObject(randomGrid.left, randomGrid.top, spriteCol, spriteRow);
  }

  TilePosition worldPositionToTilePosition(Vector2 position) {
    position -= GameUI.tileMatchingGameBoardOffset;
    final col = position.x ~/ tileSize.x;
    final row = position.y ~/ tileSize.y;
    return TilePosition(col, row);
  }

  int tilePositionToIndex(int left, int top) {
    return top * GameUI.tileMatchingGameBoardGridWidth + left;
  }

  TilePosition indexToTilePosition(int index) {
    final col = index % GameUI.tileMatchingGameBoardGridWidth;
    final row = index ~/ GameUI.tileMatchingGameBoardGridHeight;
    return TilePosition(col, row);
  }

  Vector2 getTilePosition(int left, int top) {
    final x = GameUI.tileMatchingGameBoardOffset.x +
        left * GameUI.tileMatchingGameTileSrcSize.x;
    final y = GameUI.tileMatchingGameBoardOffset.y +
        top * GameUI.tileMatchingGameTileSrcSize.y;
    return Vector2(x, y) * scaleFactor;
  }

  @override
  void onMount() {
    // TODO: implement onMount
    super.onMount();

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

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (engine.config.debugMode || engine.config.showFps) {
      drawScreenText(
        canvas,
        'FPS: ${fps.fps.toStringAsFixed(0)}',
        config: ScreenTextConfig(
          textStyle: const TextStyle(fontSize: 20),
          size: size,
          anchor: Anchor.topCenter,
          padding: const EdgeInsets.only(top: 40),
        ),
      );
    }

    for (final grid in _grids) {
      final position = getTilePosition(grid.left, grid.top);
      if (grid.isHidden) {
        hiddenTileSpriteSheet
            .getSprite(grid.top, grid.left)
            .render(canvas, position: position, size: tileSize);
      }

      if (grid.isLocked) {
        border.render(canvas, position: position, size: tileSize);
      }
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
          enableNpcs: false,
          enableCultivation: false,
          action: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(color: GameUI.foregroundColor),
            ),
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
        ),
      ],
    );
  }
}
