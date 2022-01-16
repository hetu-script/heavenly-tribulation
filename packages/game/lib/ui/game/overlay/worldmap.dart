import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';

import '../../../engine/tilemap/map.dart';
import '../../../event/event.dart';
import '../../../ui/shared/ink_image_button.dart';
import '../../../ui/pointer_detector.dart';
import '../../../engine/game.dart';
import '../../../engine/scene/worldmap.dart';
import '../../../ui/shared/avatar.dart';
import '../../../event/map_event.dart';

class WorldMapPopup extends StatelessWidget {
  static const defaultSize = 160.0;

  final double left, top, width = defaultSize, height = defaultSize;

  final void Function()? onPanelTapped;

  final bool moveToIcon;
  final bool checkIcon;
  final bool enterIcon;
  final bool talkIcon;
  final bool restIcon;

  final void Function()? onMoveToIconTapped;
  final void Function()? onCheckIconTapped;
  final void Function()? onEnterIconTapped;
  final void Function()? onTalkIconTapped;
  final void Function()? onRestIconTapped;

  const WorldMapPopup({
    Key? key,
    required this.left,
    required this.top,
    this.onPanelTapped,
    this.moveToIcon = false,
    this.onMoveToIconTapped,
    this.checkIcon = false,
    this.onCheckIconTapped,
    this.enterIcon = false,
    this.onEnterIconTapped,
    this.talkIcon = false,
    this.onTalkIconTapped,
    this.restIcon = false,
    this.onRestIconTapped,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          if (onPanelTapped != null) {
            onPanelTapped!();
          }
        },
        child: Container(
          color: Colors.transparent,
          width: width,
          height: height,
          child: Stack(
            children: <Widget>[
              Positioned.fill(
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      border: Border.all(
                        color: Colors.blue,
                        width: 2,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.5),
                          spreadRadius: 3,
                          blurRadius: 6,
                          offset:
                              const Offset(0, 2), // changes position of shadow
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (moveToIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: InkImageButton(
                      width: 40,
                      height: 40,
                      child: const Image(
                        image: AssetImage('assets/images/icon/move_to.png'),
                      ),
                      onPressed: () {
                        if (onMoveToIconTapped != null) {
                          onMoveToIconTapped!();
                        }
                      },
                    ),
                  ),
                ),
              if (checkIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: InkImageButton(
                      width: 40,
                      height: 40,
                      child: const Image(
                        image: AssetImage('assets/images/icon/check.png'),
                      ),
                      onPressed: () {
                        if (onCheckIconTapped != null) {
                          onCheckIconTapped!();
                        }
                      },
                    ),
                  ),
                ),
              if (enterIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkImageButton(
                      width: 40,
                      height: 40,
                      child: const Image(
                        image: AssetImage('assets/images/icon/enter.png'),
                      ),
                      onPressed: () {
                        if (onEnterIconTapped != null) {
                          onEnterIconTapped!();
                        }
                      },
                    ),
                  ),
                ),
              if (talkIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkImageButton(
                      width: 40,
                      height: 40,
                      child: const Image(
                        image: AssetImage('assets/images/icon/talk.png'),
                      ),
                      onPressed: () {
                        if (onTalkIconTapped != null) {
                          onTalkIconTapped!();
                        }
                      },
                    ),
                  ),
                ),
              if (restIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: InkImageButton(
                      width: 40,
                      height: 40,
                      child: const Image(
                        image: AssetImage('assets/images/icon/rest.png'),
                      ),
                      onPressed: () {
                        if (onRestIconTapped != null) {
                          onRestIconTapped!();
                        }
                      },
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class WorldMapOverlay extends StatefulWidget {
  final SamsaraGame game;
  final WorldMapScene scene;

  const WorldMapOverlay(
      {required Key key, required this.game, required this.scene})
      : super(key: key);

  @override
  _WorldMapOverlayState createState() => _WorldMapOverlayState();
}

class _WorldMapOverlayState extends State<WorldMapOverlay> {
  SamsaraGame get game => widget.game;
  WorldMapScene get scene => widget.scene;
  MapComponent get map => widget.scene.map!;

  Vector2? menuPosition;

  void init() async {}

  @override
  void initState() {
    super.initState();

    Flame.images.load('character/tile_character.png').then((image) {
      setState(() {});
    });

    game.registerListener(
      MapEvents.onMapLoaded,
      EventHandler(widget.key!, (event) {
        setState(() {});
      }),
    );

    game.registerListener(
      MapEvents.onMapTapped,
      EventHandler(widget.key!, (event) {
        setState(() {
          final e = event as MapInteractionEvent;
          if (e.terrain != null) {
            final tilePos = e.terrain!.tilePosition;
            menuPosition = scene.map!
                .tilePosition2TileCenterInScreen(tilePos.left, tilePos.top);
          }
        });
      }),
    );
  }

  @override
  void dispose() {
    super.dispose();
    game.disposeListenders(widget.key!);
  }

  @override
  Widget build(BuildContext context) {
    final heroData = game.hetu.invoke('getCurrentCharacterData');
    final screenSize = MediaQuery.of(context).size;

    final informationWidgets = <Widget>[];
    if (scene.map != null) {
      if (scene.map!.selectedTerrain != null) {
        informationWidgets.addAll(
          [
            Text(
                'X: ${scene.map!.selectedTerrain!.left}, Y: ${scene.map!.selectedTerrain!.top}'),
            Text(
                '地域: ${scene.map!.zones[scene.map!.selectedTerrain!.zoneIndex].name}')
          ],
        );
      }
      if (scene.map!.selectedEntity != null) {
        informationWidgets.add(
          Row(
            children: <Widget>[
              Text('据点: ${scene.map!.selectedEntity!.name}'),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: const Text('查看详情'),
              )
            ],
          ),
        );
      }
    }

    final screenWidgets = <Widget>[
      SizedBox(
        height: screenSize.height,
        width: screenSize.width,
        child: PointerDetector(
          child: GameWidget(
            game: scene,
          ),
          onTapDown: scene.onTapDown,
          onTapUp: scene.onTapUp,
          onDragStart: scene.onDragStart,
          onDragUpdate: scene.onDragUpdate,
          onDragEnd: scene.onDragEnd,
          onScaleStart: scene.onScaleStart,
          onScaleUpdate: scene.onScaleUpdate,
          onScaleEnd: scene.onScaleEnd,
          onLongPress: scene.onLongPress,
          onMouseMove: scene.onMouseMove,
        ),
      ),
      Positioned(
        left: 0,
        top: 0,
        child: Container(
            height: 120,
            width: 180,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius:
                  const BorderRadius.only(bottomRight: Radius.circular(5.0)),
              border: Border.all(
                width: 2,
                color: Colors.lightBlue.withOpacity(0.5),
              ),
            ),
            padding: const EdgeInsets.all(10.0),
            child: Row(
              children: <Widget>[
                Avatar(
                  avatarAssetKey: 'assets/images/${heroData['avatar']}',
                  size: 100,
                ),
              ],
            )),
      ),
      Positioned(
        right: 0,
        top: 0,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.only(bottomLeft: Radius.circular(5.0)),
            border: Border.all(
              width: 2,
              color: Colors.lightBlue.withOpacity(0.5),
            ),
          ),
          child: IconButton(
            onPressed: () {
              game.leaveScene('WorldMap');
            },
            icon: const Icon(Icons.menu_open),
          ),
        ),
      ),
      Positioned(
        left: 0,
        bottom: 0,
        child: Container(
          height: 200,
          width: 240,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius:
                const BorderRadius.only(topRight: Radius.circular(5.0)),
            border: Border.all(
              width: 2,
              color: Colors.lightBlue.withOpacity(0.5),
            ),
          ),
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: informationWidgets,
          ),
        ),
      ),
    ];

    if (menuPosition != null) {
      if (map.selectedTerrain != null) {
        final terrain = map.selectedTerrain!;
        final terrainZone = map.zones[terrain.zoneIndex];
        final location = map.selectedEntity;
        final characters = map.selectedActors;
        final hero = map.hero;
        List<int>? route;
        var isHeroPosition = false;
        if (terrain.tilePosition != hero!.tilePosition) {
          final start = game.hetu
              .invoke('getTerrain', positionalArgs: [hero.left, hero.top]);
          final end = game.hetu.invoke('getTerrain',
              positionalArgs: [terrain.left, terrain.top]);
          List? calculatedRoute =
              game.hetu.invoke('calculateRoute', positionalArgs: [start, end]);
          if (calculatedRoute != null) {
            route = List<int>.from(calculatedRoute);
            // for (var i = 1; i < route.length; ++i) {
            //   final index = route[i];
            //   final tilePosition = map.index2TilePos(index);
            //   print(tilePosition);
            // }
          }
        } else {
          isHeroPosition = true;
        }
        screenWidgets.add(
          WorldMapPopup(
            left: menuPosition!.x - WorldMapPopup.defaultSize / 2,
            top: menuPosition!.y - WorldMapPopup.defaultSize / 2,
            onPanelTapped: () {
              setState(() {
                menuPosition = null;
                scene.map!.selectedTerrain = null;
                scene.map!.selectedEntity = null;
              });
            },
            moveToIcon: route != null,
            onMoveToIconTapped: () {
              map.moveHeroToTilePositionByRoute(route!);
              setState(() {
                menuPosition = null;
              });
            },
            checkIcon: terrainZone.index != 0,
            onCheckIconTapped: () {
              setState(() {
                menuPosition = null;
              });
            },
            enterIcon: (route != null && location != null) ? true : false,
            onEnterIconTapped: () {
              setState(() {
                menuPosition = null;
              });
            },
            talkIcon: characters != null ? true : false,
            onTalkIconTapped: () {
              setState(() {
                menuPosition = null;
              });
            },
            restIcon: isHeroPosition,
            onRestIconTapped: () {
              setState(() {
                menuPosition = null;
              });
            },
          ),
        );
      }
    }

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        height: screenSize.height,
        width: screenSize.width,
        child: Stack(
          children: screenWidgets,
        ),
      ),
    );
  }
}
