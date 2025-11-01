import 'dart:async';

import 'package:flame/flame.dart';
import 'package:flame/components.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/components/ui/hovertip.dart';
import 'package:samsara/samsara.dart';

import '../../../ui.dart';
import 'matching.dart';
import '../../../global.dart';

const _kCollectPanelPriority = 5;

final _kSiteKindToMaterial = {
  'farmland': ['grain', 'herb'],
  'timberland': ['timber', 'herb'],
  'fishery': ['water', 'meat'],
  'huntingground': ['leather', 'meat'],
  'mine': ['stone', 'ore'],
};

final _kMaterialToIconScpriteIndexs = {
  'water': [0, 1, 2, 3, 4, 5],
  'grain': [6, 7, 8, 9, 10, 11],
  'meat': [12, 13, 14, 15, 16, 17],
  'ore': [42, 43, 44, 45, 46, 47],
  'leather': [18, 19, 20, 21, 22, 23],
  'herb': [24, 25, 26, 27, 28, 29],
  'timber': [30, 31, 32, 33, 34, 35],
  'stone': [36, 37, 38, 39, 40, 41],
};

class CollectPanel extends GameComponent with HandlesGesture {
  final List<Sprite> iconSprites = [];
  final Map<int, int> collection = {};
  final Map<int, int> requirements = {};
  final Map<int, bool> checked = {};

  late final Sprite frame; // , focusFrame;

  final bool isMain;

  final String? avatarId;
  Sprite? avatar;

  late final Sprite checkMark;

  String _title = '';

  MatchingGame get matchingGame => game as MatchingGame;

  bool _isFull = false;
  bool get isFull => _isFull;

  CollectPanel({
    super.position,
    required this.isMain,
    this.avatarId,
    this.avatar,
  }) : super(
          size: GameUI.collectPanalSize,
          priority: _kCollectPanelPriority,
        );

  bool collect(int objectIndex) {
    if (isMain) return false;
    if (isFull) return false;

    collection[objectIndex] = collection[objectIndex]! + 1;

    _isFull = true;
    return true;
  }

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();

    if (isMain) {
      _title =
          '${engine.locale(matchingGame.kind)}[${engine.locale('level2')}:${matchingGame.development}]'
          ' - ${matchingGame.isProduction ? engine.locale('production') : engine.locale('work')}';
    }

    onMouseEnter = () {
      Hovertip.show(
        scene: game,
        direction: HovertipDirection.bottomCenter,
        content: engine.locale('tileMatching_collectPanal_description_work'),
        width: 360,
        config: ScreenTextConfig(textAlign: TextAlign.center),
        margin: const EdgeInsets.only(bottom: 50),
      );
    };
    onMouseExit = () {
      Hovertip.hide();
    };

    // onDragIn = (buttons, position, object) {
    //   if (object is! TileObject) return;
    //   final objectIndex = object.value!.$1;
    //   final rarity = objectIndex % kRarityCount;
    //   if (rarity < matchingGame.maxRarity) return;
    //   collect(objectIndex);
    // };

    frame = Sprite(await Flame.images.load('mini_game/matching/panel.png'));
    // focusFrame = Sprite(
    //     await Flame.images.load('mini_game/matching/panel_focus.png'));

    if (avatar == null && avatarId != null) {
      avatar = Sprite(await Flame.images.load(avatarId!));
    }

    final materials = _kSiteKindToMaterial[matchingGame.kind]!;
    for (final material in materials) {
      final objectIndex =
          _kMaterialToIconScpriteIndexs[material]![matchingGame.maxRarity];
      collection[objectIndex] = 0;
      requirements[objectIndex] = 0;
      final sprite = matchingGame.iconSpriteSheet.getSpriteById(objectIndex);
      iconSprites.add(sprite);
    }

    // for (final material in materials) {
    //   final indexs = _kMaterialToIconScpriteIndexs[material]!;
    //   for (var i = 3; i <= kRarityMax; ++i) {
    //     final sprite =
    //         matchingGame.iconSpriteSheet.getSpriteById(indexs[i]);
    //     iconSprites.add(sprite);
    //   }
    // }

    checkMark = Sprite(await Flame.images.load('ui/checked.png'));
  }

  @override
  void render(Canvas canvas) {
    frame.render(canvas);

    if (isMain) {
      drawScreenText(
        canvas,
        _title,
        config: ScreenTextConfig(
          size: size,
          anchor: Anchor.topCenter,
          textStyle: TextStyles.titleSmall,
          padding: const EdgeInsets.only(top: 35),
        ),
      );
    }

    avatar?.render(canvas,
        position: GameUI.collectPanalAvatarPosition,
        size: GameUI.collectPanalAvatarSize,
        overridePaint: paint);

    for (var i = 0; i < iconSprites.length; ++i) {
      final iconSprite = iconSprites[i];
      iconSprite.render(
        canvas,
        position: GameUI.collectPanelIconPositions[i],
        size: GameUI.matchingTileSrcSize,
      );
    }
  }
}
