import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/tilemap.dart';
// import 'package:flame_audio/flame_audio.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/event.dart';
// import 'package:samsara/widgets.dart';
// import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/console.dart';
// import 'package:samsara/utils/uid.dart';
// import 'package:samsara/task.dart';

import '../../../config.dart';
// import '../../avatar.dart';
import 'components/location_site.dart';
import 'drop_menu.dart';
import '../../hero_info.dart';
import '../npc_list.dart';
import '../../../events.dart';
import '../../../state/location_site_scene.dart';
import '../../../dialog/character_visit_dialog.dart';
import '../../../dialog/game_dialog/game_dialog.dart';
import '../../../state/current_npc_list.dart';

class LocationSiteSceneOverlay extends StatefulWidget {
  const LocationSiteSceneOverlay({
    required super.key,
    this.terrainObject,
    required this.locationData,
  });

  final TileMapTerrain? terrainObject;
  final dynamic locationData;

  @override
  State<LocationSiteSceneOverlay> createState() =>
      _LocationSiteSceneOverlayState();
}

class _LocationSiteSceneOverlayState extends State<LocationSiteSceneOverlay>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  // late Animation<double> battleStartBannerAnimation, battleEndBannerAnimation;
  // late AnimationController battleStartBannerAnimationController,
  //     battleEndBannerAnimationController;

  bool _isLoading = true;

  late String locationId;

  void refreshNPCsInHeroSite(String? siteId) {
    if (siteId == null) return;
    final Iterable<dynamic> npcs = engine.hetu.invoke(
        'getNpcsByLocationAndSiteId',
        positionalArgs: [widget.locationData['id'], siteId]);
    context.read<CurrentNpcList>().updated(npcs);
  }

  void close() {
    context.read<LocationSiteSceneState>().clear();
    Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();

    locationId = widget.locationData['id'];

    engine.addEventListener(
      GameEvents.popLocationSiteScene,
      EventHandler(
        widgetKey: widget.key!,
        handle: (eventId, sceneId, scene) async {
          final currentSiteId =
              await context.read<LocationSiteSceneState>().popScene();
          if (sceneId == locationId) {
            if (mounted) {
              close();
            }
          } else {
            if (currentSiteId == locationId) {
              if (mounted) {
                final Iterable<dynamic> npcs = engine.hetu.invoke(
                    'getNpcsByLocationId',
                    positionalArgs: [locationId]);
                context.read<CurrentNpcList>().updated(npcs);
              }
            } else {
              refreshNPCsInHeroSite(currentSiteId);
            }
          }
        },
      ),
    );

    engine.addEventListener(
      GameEvents.pushLocationSiteScene,
      EventHandler(
        widgetKey: widget.key!,
        handle: (eventId, sceneId, scene) async {
          await context
              .read<LocationSiteSceneState>()
              .pushScene(siteId: sceneId);
          refreshNPCsInHeroSite(sceneId);
          await engine.hetu.invoke('onAfterHeroEnterSite', positionalArgs: [
            widget.locationData,
            widget.locationData['sites'][sceneId]
          ]);
        },
      ),
    );

    engine.addEventListener(
      GameEvents.residenceSiteScene,
      EventHandler(
        widgetKey: widget.key!,
        handle: (eventId, sceneId, scene) async {
          final residingCharacterIds = engine.hetu.invoke(
            'getCharactersByHomeId',
            positionalArgs: [widget.locationData['id']],
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
              if (mounted) {
                final homeSiteId = 'home.$selectedId';
                final homeSiteData = widget.locationData['sites'][homeSiteId];
                await context
                    .read<LocationSiteSceneState>()
                    .pushScene(siteId: homeSiteId);
                refreshNPCsInHeroSite(homeSiteId);
                await engine.hetu.invoke('onAfterHeroEnterSite',
                    positionalArgs: [widget.locationData, homeSiteData]);
              }
            }
          } else {
            GameDialog.show(context: context, dialogData: {
              'lines': [engine.locale('visitEmptyVillage')],
              'isHero': true,
            });
          }
        },
      ),
    );

    _prepareData();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      engine.hetu.invoke('onAfterHeroEnterLocation',
          positionalArgs: [widget.locationData]);
    });
  }

  @override
  void dispose() {
    engine.removeEventListener(widget.key!);

    // _scene.detach();
    super.dispose();
  }

  Future<void> _prepareData() async {
    await context
        .read<LocationSiteSceneState>()
        .pushScene(locationData: widget.locationData);

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final LocationSiteScene? scene =
        context.watch<LocationSiteSceneState>().scene;

    return (_isLoading || scene == null || scene.isLoading)
        ? LoadingScreen(
            text: engine.locale('loading'),
          )
        : Material(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                SceneWidget(scene: scene),
                const Positioned(
                  left: 0,
                  top: 0,
                  child: HeroInfoPanel(),
                ),
                const Positioned(
                  left: 5,
                  top: 130,
                  child: NpcList(),
                ),
                if (GameConfig.isDebugMode)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: LocationSceneDropMenu(
                      onSelected: (LocationSceneDropMenuItems item) async {
                        switch (item) {
                          case LocationSceneDropMenuItems.console:
                            showDialog(
                              context: context,
                              builder: (BuildContext context) => Console(
                                engine: engine,
                              ),
                            ).then((_) => setState(() {}));
                          case LocationSceneDropMenuItems.quit:
                            close();
                        }
                      },
                    ),
                  ),
              ],
            ),
          );
  }
}
