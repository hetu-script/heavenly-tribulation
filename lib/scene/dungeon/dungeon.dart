import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:samsara/hover_info.dart';
import 'package:samsara/samsara.dart';

import '../../data/game.dart';
import '../../global.dart';
import '../../state/states.dart';
import '../../ui.dart';
import '../common.dart';
import '../cursor_state.dart';
import '../world/widgets/drop_menu.dart';

class DungeonScene extends Scene with HasCursorState {
  DungeonScene() : super(id: Scenes.dungeon);

  late final SpriteComponent2 _backgroundComponent;
  late final PiledZone _siteList;

  int get _development => GameData.hero['rank'] as int? ?? 0;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _backgroundComponent = SpriteComponent2(
      sprite: await Sprite.load('dungeon/background/spellcraft_gate.jpg'),
      size: size,
    );
    _backgroundComponent.onTapDown = (_, __) {
      engine.context.read<HoverContentState>().hide();
    };
    world.add(_backgroundComponent);

    _siteList = PiledZone(
      position: GameUI.siteListPosition,
      pileStyle: PileStyle.queue,
      piledCardSize: GameUI.siteCardSize,
      pileOffset: Vector2(GameUI.siteCardSize.x / 2, 0),
      spreadOnFocus: true,
      spreadMargin: GameUI.siteCardSize.x / 2,
    );
    world.add(_siteList);
  }

  @override
  void onStart([dynamic arguments = const {}]) {
    super.onStart(arguments);

    engine.context.read<HoverContentState>().hide();
    engine.context.read<ViewPanelState>().clearAll();
    gameState.updateNpcs([]);
    gameState.updateLocation();
    gameState.updateDungeon();
  }

  @override
  void onEnd() {
    gameState.updateNpcs([]);
    super.onEnd();
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
          cultivationArguments: {
            'mode': 'none',
            'development': _development,
            'advanceTime': false,
          },
          showNpcs: true,
          showNpcNamesWithoutMeeting: true,
          actions: [DropMenuButton()],
        ),
      ],
    );
  }
}
