import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';

import '../../../ui/pointer_detector.dart';
import '../../../engine/game.dart';
import '../../../engine/scene/worldmap.dart';
import '../../../ui/shared/avatar.dart';
import '../../../event/map_event.dart';
import '../../../ui/shared/bordered_icon_button.dart';

class WorldMapPopup extends StatelessWidget {
  final double left, top, width, height;

  const WorldMapPopup(
      {Key? key,
      required this.left,
      required this.top,
      this.width = 160,
      this.height = 160})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          print("Container was tapped");
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
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: BorderedIconButton(
                    icon: const Image(
                      image: AssetImage('assets/images/icon/move_to.png'),
                    ),
                    onPressed: () {},
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

  const WorldMapOverlay({required this.game, required this.scene, Key? key})
      : super(key: key);

  @override
  _WorldMapOverlayState createState() => _WorldMapOverlayState();
}

class _WorldMapOverlayState extends State<WorldMapOverlay> {
  SamsaraGame get game => widget.game;
  WorldMapScene get scene => widget.scene;

  Vector2? menuPosition;

  void init() async {}

  @override
  void initState() {
    super.initState();

    Flame.images.load('character/tile_character.png').then((image) {
      setState(() {});
    });

    game.registerListener(MapEvents.onMapLoaded, (event) {
      setState(() {});
    });

    game.registerListener(MapEvents.onMapTapped, (event) {
      setState(() {
        if (menuPosition != null) {
          menuPosition = null;
        } else {
          final e = event as MapEvent;
          if (e.terrain != null) {
            final tilePos = e.terrain!.tilePosition;
            final worldPos = scene.map!
                .tilePosition2TileCenterInWorld(tilePos.left, tilePos.top);
            menuPosition = scene.map!.worldPosition2Screen(worldPos);
          }
        }
      });
    });
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
      screenWidgets.add(
        WorldMapPopup(left: menuPosition!.x, top: menuPosition!.y),
      );
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
