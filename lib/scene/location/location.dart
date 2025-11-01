import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:samsara/cardgame/zones/piled_zone.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../ui.dart';
import '../../global.dart';
import '../../data/game.dart';
import '../../widgets/ui_overlay.dart';
import '../../logic/logic.dart';
import '../../data/common.dart';
import '../../state/states.dart';
import '../world/widgets/drop_menu.dart';
import '../cursor_state.dart';
import '../game_dialog/game_dialog_content.dart';
import 'character_visit.dart';

class LocationScene extends Scene with HasCursorState {
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
  dynamic sect;

  late final PiledZone siteList;

  FutureOr<void> Function()? onEnterScene;

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
      final selectedId = await CharacterVisitDialog.show(
        context: context,
        characterIds: characterIds,
        heroResidesHere: heroResidesHere,
      );
      // 这里不知为何flutter明明Pop的是Null，传过来却变成了bool，只好用类型判断是否选择了角色
      if (selectedId is String) {
        final homeSiteId = '${selectedId}_$kLocationKindHome';
        final homeSiteData = GameData.getLocation(homeSiteId);
        GameLogic.tryEnterLocation(homeSiteData);
      }
    } else {
      GameDialogContent.show(context, {
        'lines': [engine.locale('hint_visitEmptyVillage')],
        'isHero': true,
      });
    }
  }

  void _onPreviewSiteCard() {
    cursorState = MouseCursorState.click;
  }

  void _onUnpreviewSiteCard() {
    cursorState = MouseCursorState.normal;
  }

  void _loadSites() {
    for (final siteCard in siteList.cards) {
      siteCard.removeFromParent();
    }
    siteList.cards.clear();

    // 一些纯功能性的场景内互动对象，不在数据中，而是硬编码
    switch (location['kind']) {
      case 'home':
        if (location['managerId'] == GameData.hero['id']) {
          final restCard = GameData.createSiteCard(
            spriteId: 'location/card/bed.png',
            title: engine.locale('rest'),
            onPreviewed: _onPreviewSiteCard,
            onUnpreviewed: _onUnpreviewSiteCard,
          );
          restCard.onTap = (button, position) {
            GameLogic.heroRest(location);
          };
          siteList.cards.add(restCard);
          world.add(restCard);

          final depositCard = GameData.createSiteCard(
            spriteId: 'location/card/depositBox.png',
            title: engine.locale('depositBox'),
            onPreviewed: _onPreviewSiteCard,
            onUnpreviewed: _onUnpreviewSiteCard,
          );
          depositCard.onTap = (button, position) {
            GameLogic.openDepositBox(location);
          };
          siteList.cards.add(depositCard);
          world.add(depositCard);
        }
      case 'exparray':
        final siteCard = GameData.createSiteCard(
          spriteId: 'location/card/exparray.png',
          title: engine.locale('meditate'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        siteCard.onTap = (button, position) {
          GameLogic.onInteractExpArray(
            sect,
            location: location,
          );
        };
        siteList.cards.add(siteCard);
        world.add(siteCard);
      case 'library':
        final siteCard = GameData.createSiteCard(
          spriteId: 'location/card/carddesk.png',
          title: engine.locale('cardlibrary'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        siteCard.onTap = (button, position) {
          GameLogic.onInteractCardLibraryDesk(sect: sect, location: location);
        };
        siteList.cards.add(siteCard);
        world.add(siteCard);
      case 'dungeon':
        final siteCard = GameData.createSiteCard(
          spriteId: 'location/card/dungeon.png',
          title: engine.locale('dungeon'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        siteCard.onTap = (button, position) {
          GameLogic.onInteractDungeonEntrance(sect: sect, location: location);
        };
        siteList.cards.add(siteCard);
        world.add(siteCard);
      case 'hotel':
        final restCard = GameData.createSiteCard(
          spriteId: 'location/card/bed.png',
          title: engine.locale('guestRoom'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        restCard.onTap = (button, position) {
          GameLogic.heroRest(location);
        };
        siteList.cards.add(restCard);
        world.add(restCard);
      case 'cityhall':
        final restCard = GameData.createSiteCard(
          spriteId: 'location/card/bed.png',
          title: engine.locale('guestRoom'),
          onPreviewed: _onPreviewSiteCard,
          onUnpreviewed: _onUnpreviewSiteCard,
        );
        restCard.onTap = (button, position) {
          GameLogic.heroRest(location);
        };
        siteList.cards.add(restCard);
        world.add(restCard);
      default:
        for (final siteId in location['siteIds']) {
          final siteData = GameData.getLocation(siteId);
          final siteCard = GameData.getSiteCard(
            siteData,
            onPreviewed: _onPreviewSiteCard,
            onUnpreviewed: _onUnpreviewSiteCard,
          );
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
        title: engine.locale('residence'),
        onPreviewed: _onPreviewSiteCard,
        onUnpreviewed: _onUnpreviewSiteCard,
      );
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

    final sectId = location['sectId'];
    if (sectId != null) {
      sect = GameData.getSect(sectId);
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
      onPreviewed: _onPreviewSiteCard,
      onUnpreviewed: _onUnpreviewSiteCard,
    );
    exit.onTap = (_, __) async {
      final result = await engine.hetu.invoke('onWorldEvent',
          positionalArgs: ['onBeforeExitLocation', location]);
      if (result == true) return;
      final worldId = location['worldId'];
      if (worldId != null) {
        final left = location['worldPosition']['left'];
        final top = location['worldPosition']['top'];
        assert(left != null && top != null,
            'Location ${location['id']} 缺少 worldPosition 数据');
        engine.hetu.invoke(
          'setCharacterWorldPosition',
          positionalArgs: [
            GameData.hero,
            location['worldPosition']['left'],
            location['worldPosition']['top'],
          ],
          namedArgs: {
            'worldId': location['worldId'],
          },
        );
      }
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

    context.read<HoverContentState>().hide();
    context.read<ViewPanelState>().clearAll();

    engine.hetu.assign('location', location);

    final onEnterSceneCallback = arguments['onEnterScene'];
    if (onEnterSceneCallback != null) {
      if (onEnterSceneCallback is FutureOr<void> Function()) {
        onEnterScene = onEnterSceneCallback;
      } else {
        engine.warn(
            'LocationScene: onEnterScene 必须是 FutureOr<void> Function(), 当前类型: ${onEnterSceneCallback.runtimeType}');
      }
    }
  }

  @override
  void onMount() async {
    super.onMount();

    await onEnterScene?.call();

    engine.info('玩家进入了 ${location['name']}');
    await GameLogic.onAfterEnterLocation(location);

    gameState.clearTerrain();
    gameState.updateDungeon();
    gameState.updateActiveJournals();
    gameState.updateDatetime();

    gameState.updateLocation(location);
    final npcs = GameData.getNpcsAtLocation(location);
    gameState.updateNpcs(npcs);
  }

  @override
  void onEnd() {
    super.onEnd();

    engine.hetu.assign('location', null);
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
          showNpcs: true,
          showJournal: true,
          actions: [DropMenuButton()],
        ),
      ],
    );
  }
}
