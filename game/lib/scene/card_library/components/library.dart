import 'package:flame/components.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/components/sprite_component2.dart';
// import 'package:flame/flame.dart';
// import 'package:samsara/gestures.dart';
import 'package:samsara/components.dart';

// import '../../../global.dart';
import 'library_zone.dart';
import 'deckbuilding_zone.dart';
import '../../../ui.dart';
import '../../../config.dart';

const kBarPriority = 5000;
const kButtonPriority = 20;

enum DeckBuildingSceneState {
  expCollection, // 收集经验球提升等级和境界
  // introspection,
  skillTree, // 显示和分配天赋树技能
}

class CardLibraryScene extends Scene {
  late final SpriteComponent background;
  late final SpriteComponent2 topBar, bottomBar;

  late final CardLibraryZone libraryZone;

  late final SpriteButton close;

  final List<DeckBuildingZone> deckPiles = [];
  DeckBuildingZone? currentBuildingZone;

  late final GameComponent deckPilesZone;
  double deckPilesVirtualHeight = 0;

  final List<dynamic> library;

  CardLibraryScene({
    required super.controller,
    required this.library,
    required super.context,
  }) : super(id: 'deckBuilding');

  void onCreateDeck(DeckBuildingZone zone) {
    for (final existedZone in deckPiles) {
      if (existedZone != zone) {
        existedZone.isVisible = false;
      }
    }
    libraryZone.buildingZone = zone;
    close.isVisible = true;
  }

  void onEditDeck(DeckBuildingZone zone) {
    for (final existedZone in deckPiles) {
      if (existedZone != zone) {
        existedZone.isVisible = false;
      }
    }
    libraryZone.buildingZone = zone;
    close.isVisible = true;
  }

  void addNewDeckBuildingZone() {
    currentBuildingZone = DeckBuildingZone(
      limit: 10,
      position: GameUI.deckPileInitialPosition,
      // onCreateDeck: onCreateDeck,
      onEditDeck: onEditDeck,
    );
    currentBuildingZone!.library = libraryZone;
    world.add(currentBuildingZone!);
    deckPiles.add(currentBuildingZone!);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    close = SpriteButton(
      text: engine.locale('close'),
      anchor: Anchor.topLeft,
      position: GameUI.decksZoneCloseButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
      textConfig: ScreenTextConfig(
        textStyle: TextStyle(fontFamily: GameUI.fontFamily),
      ),
      priority: kButtonPriority,
      isVisible: false,
    );
    close.onTapUp = (buttons, position) {
      close.isVisible = false;

      currentBuildingZone!.collapse();

      currentBuildingZone = null;
    };
    camera.viewport.add(close);

    background = SpriteComponent(
      sprite: await Sprite.load('cultivation/cardlibrary_background.png'),
      size: size,
    );
    world.add(background);

    topBar = SpriteComponent2(
      sprite: await Sprite.load('cultivation/cardlibrary_background_top.png'),
      size: Vector2(size.x, GameUI.libraryZonePosition.y),
      priority: kBarPriority,
    );
    world.add(topBar);

    bottomBar = SpriteComponent2(
      sprite:
          await Sprite.load('cultivation/cardlibrary_background_bottom.png'),
      size: Vector2(size.x,
          size.y - GameUI.libraryZonePosition.y - GameUI.libraryZoneSize.y),
      position:
          Vector2(0, GameUI.libraryZonePosition.y + GameUI.libraryZoneSize.y),
      priority: kBarPriority,
    );
    world.add(bottomBar);

    libraryZone = CardLibraryZone();
    world.add(libraryZone);

    // buildingZone = DeckBuildingZone(limit: 4);
    // world.add(buildingZone);

    // libraryZone.buildingZone = buildingZone;
    // buildingZone.library = libraryZone;

    for (final data in library) {
      final card = libraryZone.addCardByData(data);
      // 如果卡牌已经存在，则library.addCard会返回null，下面就不用处理。
      // 已经改为随机生成卡牌的系统，这里不可能再返回null
      // if (card == null) continue;
      // 这里要直接加到世界上而非library管理，因为卡牌可能会在不同的区域之间拖动
      // 这样的话如果卡牌改变了区域，不用考虑修改其位置和父组件的问题
      world.add(card);
    }

    addNewDeckBuildingZone();
  }

  // @override
  // void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
  //   camera.moveBy(-details.delta.toVector2() / camera.viewfinder.zoom);

  //   super.onDragUpdate(pointer, buttons, details);
  // }
}
