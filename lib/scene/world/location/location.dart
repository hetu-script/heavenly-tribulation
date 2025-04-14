import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/state/selected_tile.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:provider/provider.dart';

import '../../../engine.dart';
import '../../../game/data.dart';
import '../../../game/ui.dart';
import '../../../widgets/ui_overlay.dart';
import '../../../widgets/dialog/character_visit.dart';
import '../../../state/current_npc_list.dart';
import '../../game_dialog/game_dialog_content.dart';
import '../../../game/logic.dart';
import '../../../common.dart';

class LocationScene extends Scene {
  late final SpriteComponent _backgroundComponent;

  final dynamic locationData;
  dynamic organizationData;

  late final PiledZone siteList;

  LocationScene({
    required this.locationData,
    required super.context,
  }) : super(
          id: locationData['id'],
          // bgmFile: 'vietnam-bamboo-flute-143601.mp3',
          // bgmVolume: GameConfig.musicVolume,
        );

  void openResidenceList() async {
    final List residingCharacterIds = locationData['residents'];
    if (residingCharacterIds.isNotEmpty) {
      final List characterIds = residingCharacterIds.toList();
      bool heroResidesHere = false;
      final heroId = GameData.heroData['id'];
      if (characterIds.contains(heroId)) {
        characterIds.remove(heroId);
        heroResidesHere = true;
      }
      // final heroId = engine.hetu.invoke('getHeroId');
      final selectedId = await CharacterVisitDialog.show(
        context: context,
        characterIds: characterIds,
        heroResidesHere: heroResidesHere,
      );
      // 这里不知为何flutter明明Pop的是Null，传过来却变成了bool，只好用类型判断是否选择了角色
      if (selectedId is String) {
        final homeSiteId = 'home_$selectedId';
        final homeSiteData = GameData.gameData['locations'][homeSiteId];
        assert(homeSiteData != null);
        GameLogic.tryEnterLocation(homeSiteData);
      }
    } else {
      GameDialogContent.show(context, {
        'lines': [engine.locale('visitEmptyVillage')],
        'isHero': true,
      });
    }
  }

  void _loadSites() {
    for (final siteCard in siteList.cards) {
      siteCard.removeFromParent();
    }
    siteList.cards.clear();

    // 一些纯功能性的场景内互动对象，不在数据中，而是硬编码
    switch (locationData['kind']) {
      case 'home':
        if (locationData['ownerId'] == GameData.heroData['id']) {
          final siteCardRest = GameData.createSiteCard(
              spriteId: 'location/card/bed.png', title: engine.locale('rest'));
          siteCardRest.onTap = (buttons, position) {
            GameLogic.heroRest();
          };
          siteList.cards.add(siteCardRest);
          world.add(siteCardRest);
        }
      case 'cityhall':
        final siteCardRest = GameData.createSiteCard(
            spriteId: 'location/card/stele.png',
            title: engine.locale('cultivationStele'));
        siteCardRest.onTap = (buttons, position) {
          GameLogic.onInteractCultivationStele(organizationData);
        };
        siteList.cards.add(siteCardRest);
        world.add(siteCardRest);
      case 'library':
        final siteCardRest = GameData.createSiteCard(
            spriteId: 'location/card/carddesk.png',
            title: engine.locale('cardLibrary'));
        siteCardRest.onTap = (buttons, position) {
          GameLogic.onInteractCardLibraryDesk(organizationData);
        };
        siteList.cards.add(siteCardRest);
        world.add(siteCardRest);
      default:
        for (final siteId in locationData['sites']) {
          final siteData = GameData.gameData['locations'][siteId];
          final siteCard = GameData.createSiteCardFromData(siteData);
          siteCard.onTap = (buttons, position) {
            if (kLocationSiteKinds.contains(siteCard.data['kind'])) {
              GameLogic.tryEnterLocation(siteCard.data);
            } else {
              engine.hetu.invoke('onWorldEvent', positionalArgs: [
                'onInteractLocationObject',
                siteCard.data,
                locationData,
              ]);
            }
          };
          siteList.cards.add(siteCard);
          world.add(siteCard);
        }
    }

    if (locationData['category'] == 'city') {
      final siteCardResidence = GameData.createSiteCard(
          spriteId: 'location/card/residence.png',
          title: engine.locale('residence'));
      siteCardResidence.onTap = (buttons, position) {
        openResidenceList();
      };
      siteList.cards.add(siteCardResidence);
      world.add(siteCardResidence);
    }

    siteList.sortCards(animated: false);
  }

  @override
  void onLoad() async {
    super.onLoad();

    if (locationData['organizationId'] != null) {
      organizationData =
          GameData.gameData['organizations'][locationData['organizationId']];
    }

    _backgroundComponent = SpriteComponent(
      sprite: Sprite(await Flame.images.load(locationData['background'])),
      size: size,
    );
    world.add(_backgroundComponent);

    siteList = PiledZone(
      position: GameUI.siteListPosition,
      pileStyle: PileStyle.queue,
      piledCardSize: GameUI.siteCardSize,
      pileOffset: Vector2(GameUI.siteCardSize.x / 3 * 2, 0),
    );
    world.add(siteList);

    _loadSites();

    final exit = GameData.createSiteCard(
      id: 'exit',
      spriteId: 'location/card/exit.png',
      title: engine.locale('exit'),
      position: GameUI.siteExitCardPositon,
    );
    exit.onTap = (_, __) async {
      final result = await engine.hetu.invoke('onWorldEvent',
          positionalArgs: ['onBeforeExitLocation', locationData]);
      if (result == true) return;
      engine.popScene(clearCache: true);
    };
    world.add(exit);

    engine.hetu.interpreter.bindExternalFunction('World::updateLocationSites', (
        {positionalArgs, namedArgs}) {
      _loadSites();
    }, override: true);
  }

  @override
  void onStart([Map<String, dynamic> arguments = const {}]) {
    super.onStart(arguments);

    final List npcs = engine.hetu
        .invoke('getNpcsAtLocationId', positionalArgs: [locationData['id']]);
    context.read<NpcListState>().update(npcs);
    context.read<HeroPositionState>().updateTerrain(
          currentZoneData: null,
          currentNationData: null,
          currentTerrainData: null,
        );
    context.read<HeroPositionState>().updateLocation(locationData);

    engine.debug('玩家进入了 ${locationData['name']}');

    GameLogic.onAfterEnterLocation(locationData);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SceneWidget(scene: this),
        GameUIOverlay(),
      ],
    );
  }
}
