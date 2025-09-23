import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/state/selected_tile.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../game/data.dart';
import '../../game/ui.dart';
import '../../widgets/ui_overlay.dart';
import '../../widgets/dialog/character_visit.dart';
import '../../state/npc_list.dart';
import '../game_dialog/game_dialog_content.dart';
import '../../game/logic.dart';
import '../../common.dart';
import '../../widgets/ui/menu_builder.dart';
import '../../state/game_save.dart';
import '../../widgets/dialog/input_string.dart';
import '../../widgets/world_infomation.dart';
import '../common.dart';

enum LocationDropMenuItems { save, saveAs, info, console, exit }

class LocationScene extends Scene {
  LocationScene({
    required this.location,
    required super.context,
  }) : super(
          id: location['id'],
          // bgmFile: 'vietnam-bamboo-flute-143601.mp3',
          // bgmVolume: GameConfig.musicVolume,
        );
  final menuController = fluent.FlyoutController();

  late final SpriteComponent _backgroundComponent;

  final dynamic location;
  dynamic organization;

  late final PiledZone siteList;

  void openResidenceList() async {
    final List residingCharacterIds = location['residents'];
    if (residingCharacterIds.isNotEmpty) {
      final List characterIds = residingCharacterIds.toList();
      bool heroResidesHere = false;
      final heroId = GameData.hero['id'];
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
        final homeSiteData = GameData.game['locations'][homeSiteId];
        assert(homeSiteData != null);
        GameLogic.tryEnterLocation(homeSiteData);
      }
    } else {
      GameDialogContent.show(context, {
        'lines': [engine.locale('hint_visitEmptyVillage')],
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
    switch (location['kind']) {
      case 'home':
        if (location['ownerId'] == GameData.hero['id']) {
          final siteCard = GameData.createSiteCard(
              spriteId: 'location/card/bed.png', title: engine.locale('rest'));
          siteCard.onTap = (button, position) {
            GameLogic.heroRest();
          };
          siteList.cards.add(siteCard);
          world.add(siteCard);
        }
      case 'stele':
        final siteCard = GameData.createSiteCard(
            spriteId: 'location/card/stele.png',
            title: engine.locale('meditate'));
        siteCard.onTap = (button, position) {
          GameLogic.onInteractCultivationStele(organization,
              location: location);
        };
        siteList.cards.add(siteCard);
        world.add(siteCard);
      case 'library':
        final siteCard = GameData.createSiteCard(
            spriteId: 'location/card/carddesk.png',
            title: engine.locale('cardlibrary'));
        siteCard.onTap = (button, position) {
          GameLogic.onInteractLibraryDesk(
              organization: organization, location: location);
        };
        siteList.cards.add(siteCard);
        world.add(siteCard);
      case 'dungeon':
        final siteCard = GameData.createSiteCard(
            spriteId: 'location/card/dungeon.png',
            title: engine.locale('dungeon'));
        siteCard.onTap = (button, position) {
          GameLogic.onInteractDungeonEntrance(location);
        };
        siteList.cards.add(siteCard);
        world.add(siteCard);
      default:
        for (final siteId in location['sites']) {
          final siteData = GameData.game['locations'][siteId];
          final siteCard = GameData.createSiteCardFromData(siteData);
          siteCard.onTap = (button, position) {
            if (kLocationSiteKinds.contains(siteCard.data['kind'])) {
              GameLogic.tryEnterLocation(siteCard.data);
            } else {
              engine.hetu.invoke('onWorldEvent', positionalArgs: [
                'onInteractLocationObject',
                siteCard.data,
                location,
              ]);
            }
          };
          siteList.cards.add(siteCard);
          world.add(siteCard);
        }
    }

    if (location['category'] == 'city') {
      final siteCardResidence = GameData.createSiteCard(
          spriteId: 'location/card/residence.png',
          title: engine.locale('residence'));
      siteCardResidence.onTap = (button, position) {
        openResidenceList();
      };
      siteList.cards.add(siteCardResidence);
      world.add(siteCardResidence);
    }

    siteList.sortCards(animated: false, reversed: true);
  }

  @override
  void onLoad() async {
    super.onLoad();

    if (location['organizationId'] != null) {
      organization = GameData.game['organizations'][location['organizationId']];
    }

    _backgroundComponent = SpriteComponent(
      sprite: Sprite(await Flame.images.load(location['background'])),
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
          positionalArgs: ['onBeforeExitLocation', location]);
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
  void onStart([dynamic arguments = const {}]) {
    super.onStart(arguments);

    engine.hetu.assign('location', location);

    final List npcs = engine.hetu
        .invoke('getNpcsAtLocationId', positionalArgs: [location['id']]);
    context.read<NpcListState>().update(npcs);
    context.read<HeroPositionState>().updateTerrain(
          currentZoneData: null,
          currentNationData: null,
          currentTerrainData: null,
        );
    context.read<HeroPositionState>().updateLocation(location);

    engine.debug('玩家进入了 ${location['name']}');

    GameLogic.onAfterEnterLocation(location);
  }

  @override
  void onEnd() {
    super.onEnd();

    engine.hetu.assign('location', null);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SceneWidget(scene: this),
        GameUIOverlay(
          action: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(5.0),
              border: Border.all(color: GameUI.foregroundColor),
            ),
            child: fluent.FlyoutTarget(
              controller: menuController,
              child: IconButton(
                icon: const Icon(Icons.menu_open, size: 20.0),
                mouseCursor: MouseCursor.defer,
                padding: const EdgeInsets.all(0),
                onPressed: () {
                  showFluentMenu<LocationDropMenuItems>(
                    controller: menuController,
                    items: {
                      engine.locale('save'): LocationDropMenuItems.save,
                      engine.locale('saveAs'): LocationDropMenuItems.saveAs,
                      '___1': null,
                      engine.locale('info'): LocationDropMenuItems.info,
                      '___2': null,
                      engine.locale('console'): LocationDropMenuItems.console,
                      '___3': null,
                      engine.locale('exit'): LocationDropMenuItems.exit,
                    },
                    onSelectedItem: (LocationDropMenuItems item) async {
                      switch (item) {
                        case LocationDropMenuItems.save:
                          String worldId = engine.hetu
                              .fetch('currentWorldId', namespace: 'game');
                          String? saveName =
                              engine.hetu.fetch('saveName', namespace: 'game');
                          context
                              .read<GameSavesState>()
                              .saveGame(worldId, saveName)
                              .then(
                            (saveInfo) {
                              GameDialogContent.show(
                                context,
                                engine.locale('savedSuccessfully',
                                    interpolations: [saveInfo.savePath]),
                              );
                            },
                          );
                        case LocationDropMenuItems.saveAs:
                          showDialog(
                            context: context,
                            builder: (context) {
                              return InputStringDialog(
                                title: engine.locale('inputName'),
                              );
                            },
                          ).then((saveName) {
                            if (saveName == null) return;
                            engine.hetu.assign('saveName', saveName,
                                namespace: 'game');
                            String worldId = engine.hetu
                                .fetch('currentWorldId', namespace: 'game');
                            context
                                .read<GameSavesState>()
                                .saveGame(worldId, saveName)
                                .then((saveInfo) {
                              GameDialogContent.show(
                                context,
                                engine.locale('savedSuccessfully',
                                    interpolations: [saveInfo.savePath]),
                              );
                            });
                          });
                        case LocationDropMenuItems.info:
                          showDialog(
                              context: context,
                              builder: (context) =>
                                  const WorldInformationPanel());
                        case LocationDropMenuItems.console:
                          showDialog(
                            context: context,
                            builder: (BuildContext context) => Console(
                              engine: engine,
                              margin: const EdgeInsets.all(50.0),
                              backgroundColor: GameUI.backgroundColor2,
                            ),
                          );
                        case LocationDropMenuItems.exit:
                          context.read<SelectedPositionState>().clear();
                          engine.clearAllCachedScene(
                              except: Scenes.mainmenu,
                              arguments: {'reset': true});
                      }
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
