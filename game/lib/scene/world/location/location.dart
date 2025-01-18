import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:samsara/cardgame/custom_card.dart';
import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:provider/provider.dart';

import '../../../engine.dart';
import '../../../data.dart';
import '../../../ui.dart';
import '../../../events.dart';
import '../../npc_list.dart';
import '../../../widgets/ui_overlay.dart';
import '../../../widgets/dialog/character_visit_dialog.dart';
import '../../../state/current_npc_list.dart';
import '../../common.dart';
import '../../game_dialog/game_dialog.dart';

class LocationScene extends Scene {
  late final SpriteComponent _backgroundComponent;

  final dynamic locationData;

  LocationScene({
    required this.locationData,
    required super.context,
  }) : super(
          id: locationData['id'],
          // bgmFile: 'vietnam-bamboo-flute-143601.mp3',
          // bgmVolume: GameConfig.musicVolume,
        );

  void updateNPCsInHeroSite(String? siteId) {
    if (siteId == null) return;
    final Iterable<dynamic> npcs = engine.hetu
        .invoke('getNpcsByLocationId', positionalArgs: [locationData['id']]);
    context.read<CurrentNpcList>().updated(npcs);
  }

  void openResidenceList() async {
    final residingCharacterIds = engine.hetu.invoke(
      'getCharactersByHomeId',
      positionalArgs: [locationData['id']],
    );
    if (residingCharacterIds.isNotEmpty) {
      final characterIds = residingCharacterIds.toList();
      // final heroId = engine.hetu.invoke('getHeroId');
      final selectedId = await CharacterVisitDialog.show(
        context: context,
        characterIds: characterIds,
        hideHero: false,
      );
      // 这里不知为何flutter命名Pop的是Null，传过来却变成了bool，只好用类型判断是否选择了角色
      if (selectedId is String) {
        if (context.mounted) {
          final homeSiteId = 'home.$selectedId';
          final homeSiteData = locationData['sites'][homeSiteId];
          await context
              .read<SceneControllerState>()
              .push(Scenes.location, arguments: {'location': homeSiteData});
          updateNPCsInHeroSite(homeSiteId);
          await engine.hetu.invoke('onAfterHeroEnterSite',
              positionalArgs: [locationData, homeSiteData]);
        }
      }
    } else {
      GameDialog.show(context: context, dialogData: {
        'lines': [engine.locale('visitEmptyVillage')],
        'isHero': true,
      });
    }
  }

  @override
  void onLoad() async {
    super.onLoad();

    _backgroundComponent = SpriteComponent(
      sprite: Sprite(await Flame.images.load(locationData['background'])),
      size: size,
    );
    world.add(_backgroundComponent);

    final List<CustomGameCard> siteCards = [];

    // final heroHomeId = engine.hetu.invoke('getHeroHomeLocationId');
    // if (id == heroHomeId) {
    //   final heroHomeSite = engine.hetu.invoke('getHeroHomeSite');
    //   siteCards.add(GameData.getSiteCard(heroHomeSite));
    // }

    for (final id in locationData['sites']) {
      final siteData = locationData['buildings'][id];
      siteCards.add(GameData.getSiteCard(siteData));
    }

    for (final siteCard in siteCards) {
      siteCard.onTap = (buttons, position) async {
        if (siteCard.data['category'] != 'residence') {
          openResidenceList();
        } else {
          await context.read<SceneControllerState>().push(
            Scenes.location,
            arguments: {'location': siteCard.data},
          );
        }
      };
      world.add(siteCard);
    }

    final siteList = PiledZone(
      cards: siteCards,
      position: GameUI.siteListPosition,
      pileStructure: PileStructure.queue,
      piledCardSize: GameUI.siteCardSize,
      pileOffset: Vector2(GameUI.siteCardSize.x / 3 * 2, 0),
    );
    world.add(siteList);

    final exit = GameData.getExitSiteCard();
    exit.onTap = (_, __) => engine.emit(GameEvents.popLocationSiteScene, id);
    world.add(exit);
  }

  @override
  void onMount() {
    final Iterable<dynamic> npcs = engine.hetu
        .invoke('getNpcsByLocationId', positionalArgs: [locationData['id']]);
    context.read<CurrentNpcList>().updated(npcs);

    engine.hetu
        .invoke('onAfterHeroEnterLocation', positionalArgs: [locationData]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SceneWidget(scene: this),
        const Positioned(
          left: 0,
          top: 0,
          child: GameUIOverlay(),
        ),
        const Positioned(
          left: 5,
          top: 130,
          child: NpcList(),
        ),
      ],
    );
  }
}
