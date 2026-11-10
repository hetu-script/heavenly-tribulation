import 'dart:async';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:samsara/hover_info.dart';
import 'package:samsara/samsara.dart';

import '../../data/game.dart';
import '../../global.dart';
import '../../logic/logic.dart';
import '../../state/states.dart';
import '../../ui.dart';
import '../common.dart';
import '../cursor_state.dart';
import '../world/widgets/drop_menu.dart';

class CampScene extends Scene with HasCursorState {
  CampScene() : super(id: Scenes.camp);

  late final SpriteComponent2 _backgroundComponent;
  late final PiledZone _siteList;

  int get _development => GameData.hero['rank'] as int? ?? 0;

  void _onPreviewSiteCard() {
    cursorState = MouseCursorState.click;
    engine.context.read<HoverContentState>().hide();
  }

  void _onUnpreviewSiteCard() {
    cursorState = MouseCursorState.normal;
  }

  void _addSiteCard({
    required String id,
    required String title,
    String? image,
    String? spriteId,
    Vector2? position,
    bool inPile = true,
    required FutureOr<void> Function() onTap,
  }) {
    assert(image != null || spriteId != null);
    final card = GameData.createSiteCard(
      id: id,
      spriteId: spriteId ?? 'dungeon/card/$image.jpg',
      title: title,
      position: position,
      onPreviewed: _onPreviewSiteCard,
      onUnpreviewed: _onUnpreviewSiteCard,
    );
    card.onTap = (_, __) => onTap();
    if (inPile) _siteList.tryAddCard(card);
    world.add(card);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    _backgroundComponent = SpriteComponent2(
      sprite: await Sprite.load('dungeon/background/initial_camp.jpg'),
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

    _addSiteCard(
      id: 'deck',
      title: engine.locale('cardlibrary'),
      image: 'camp_deck',
      onTap: () {
        engine.pushScene(Scenes.library, arguments: {
          'enableCardCraft': true,
          'enableScrollCraft': true,
        });
      },
    );
    _addSiteCard(
      id: 'workshop',
      title: engine.locale('workshop'),
      image: 'camp_workshop',
      onTap: () {
        engine.context.read<ViewPanelState>().toogle(
          ViewPanels.workbench,
          arguments: {'development': _development},
        );
      },
    );
    _addSiteCard(
      id: 'alchemy',
      title: engine.locale('alchemy_furnace'),
      image: 'camp_alchemy',
      onTap: () {
        engine.context.read<ViewPanelState>().toogle(
          ViewPanels.alchemy,
          arguments: {'development': _development},
        );
      },
    );
    _addSiteCard(
      id: 'cultivation',
      title: engine.locale('cultivation'),
      image: 'camp_cultivation',
      onTap: () {
        engine.pushScene(Scenes.cultivation, arguments: {
          'mode': 'none',
          'development': _development,
          'advanceTime': false,
        });
      },
    );
    _addSiteCard(
      id: 'warehouse',
      title: engine.locale('storage'),
      spriteId: 'location/card/depositBox.png',
      onTap: () {
        GameLogic.openDepositBox(GameData.hero['warehouse']);
      },
    );
    _addSiteCard(
      id: 'start',
      title: engine.locale('startDungeon'),
      image: 'camp_start',
      position: GameUI.siteExitCardPositon,
      inPile: false,
      onTap: () {
        engine.pushScene(
          Scenes.dungeon,
          constructorId: Scenes.dungeon,
        );
      },
    );
    _siteList.sortCards(animated: false);
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
          enableCultivation: false,
          actions: [DropMenuButton()],
        ),
      ],
    );
  }
}
