import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:provider/provider.dart';

import '../../../engine.dart';
import '../../../game/data.dart';
import '../../../game/ui.dart';
import '../../../widgets/npc_list.dart';
import '../../../widgets/ui_overlay.dart';
import '../../../widgets/dialog/character_visit.dart';
import '../../../state/current_npc_list.dart';
import '../../common.dart';
import '../../game_dialog/game_dialog_content.dart';
import '../../../game/logic.dart';
import '../../../common.dart';

class LocationScene extends Scene {
  late final SpriteComponent _backgroundComponent;

  final dynamic locationData;

  late final PiledZone siteList;

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
        .invoke('getNpcsAtLocationId', positionalArgs: [locationData['id']]);
    context.read<CurrentNpcList>().updated(npcs);
  }

  Future<void> _tryEnterLocation(dynamic locationData) async {
    final result = await engine.hetu
        .invoke('onBeforeEnterLocation', positionalArgs: [locationData]);

    if (result == null) {
      engine.pushScene(
        locationData['id'],
        constructorId: Scenes.location,
        arguments: {'location': locationData},
      );
    }
  }

  void openResidenceList() async {
    final residingCharacterIds = engine.hetu
        .invoke('getResidingCharactersIds', positionalArgs: [locationData]);
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
      // 这里不知为何flutter命名Pop的是Null，传过来却变成了bool，只好用类型判断是否选择了角色
      if (selectedId is String) {
        final homeSiteId = 'home_$selectedId';
        final homeSiteData =
            engine.hetu.invoke('getLocationById', positionalArgs: [homeSiteId]);
        assert(homeSiteData != null);
        _tryEnterLocation(homeSiteData);
      }
    } else {
      GameDialogContent.show(context, {
        'lines': [engine.locale('visitEmptyVillage')],
        'isHero': true,
      });
    }
  }

  void updateSites() {
    for (final siteCard in siteList.cards) {
      siteCard.removeFromParent();
    }
    siteList.cards.clear();

    if (locationData['kind'] == 'home') {
      /// 纯功能性的场景内互动对象，不保存为数据
      if (locationData['ownerId'] == GameData.heroData['id']) {
        final siteCardRest = GameData.createSiteCard(
            spriteId: 'bed.png', title: engine.locale('rest'));
        siteCardRest.onTap = (buttons, position) {
          GameLogic.heroRest();
        };
        siteList.cards.add(siteCardRest);
        world.add(siteCardRest);
      }
    } else {
      for (final siteId in locationData['sites']) {
        final siteData =
            engine.hetu.invoke('getLocationById', positionalArgs: [siteId]);
        final siteCard = GameData.createSiteCardFromData(siteData);
        siteCard.onTap = (buttons, position) {
          if (siteCard.data['kind'] == 'residence') {
            openResidenceList();
          } else if (kLocationSiteKinds.contains(siteCard.data['kind'])) {
            _tryEnterLocation(siteCard.data);
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

    siteList.sortCards(animated: false);
  }

  @override
  void onLoad() async {
    super.onLoad();

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

    updateSites();

    final exit = GameData.createSiteCard(
      id: 'exit',
      spriteId: 'exit.png',
      title: engine.locale('exit'),
      position: GameUI.siteExitCardPositon,
    );
    exit.onTap = (_, __) async {
      final result = await engine.hetu.invoke('onWorldEvent',
          positionalArgs: ['onBeforeExitLocation', locationData]);
      if (result == false) return;
      engine.popScene(clearCache: true);
    };
    world.add(exit);

    engine.hetu.interpreter.bindExternalFunction('World::updateLocationSites', (
        {positionalArgs, namedArgs}) {
      updateSites();
    }, override: true);
  }

  @override
  void onStart([Map<String, dynamic> arguments = const {}]) {
    super.onStart(arguments);

    final Iterable<dynamic> npcs = engine.hetu
        .invoke('getNpcsAtLocationId', positionalArgs: [locationData['id']]);
    context.read<CurrentNpcList>().updated(npcs);

    engine.debug('玩家进入了 ${locationData['name']}');
    engine.hetu.invoke('onAfterEnterLocation', positionalArgs: [locationData]);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SceneWidget(scene: this),
        const Positioned(
          left: 5,
          top: 130,
          child: NpcList(),
        ),
        const Positioned(
          left: 0,
          top: 0,
          child: GameUIOverlay(),
        ),
      ],
    );
  }
}
