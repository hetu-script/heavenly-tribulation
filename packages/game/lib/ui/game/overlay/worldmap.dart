import 'package:flutter/material.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/widgets.dart';
import 'package:flame/sprite.dart';

import '../../../ui/pointer_detector.dart';
import '../../../engine/game.dart';
import '../../../engine/scene/worldmap.dart';
import '../../../ui/shared/avatar.dart';
import '../../../event/map_event.dart';

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

  SpriteSheet? walkingSpriteSheet;

  void init() async {}

  @override
  void initState() {
    super.initState();

    Flame.images.load('character/tile_character.png').then((image) {
      setState(() {
        walkingSpriteSheet = SpriteSheet.fromColumnsAndRows(
          image: image,
          columns: 4,
          rows: 4,
        );
      });
    });

    game.registerListener(MapEvents.onMapLoaded, (event) {
      setState(() {});
    });

    game.registerListener(MapEvents.onTileTapped, (event) {
      final e = event as MapEvent;
      setState(() {});
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

    if (walkingSpriteSheet != null) {
      screenWidgets.add(
        Align(
          alignment: Alignment.bottomCenter,
          child: SizedBox(
            height: 160,
            child: Align(
              alignment: Alignment.topCenter,
              child: Ink(
                width: 100,
                height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(
                      width: 2,
                      color: Colors.lightBlue.withOpacity(0.5),
                    ),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () {},
                      child: SpriteWidget(
                        anchor: Anchor.center,
                        sprite: walkingSpriteSheet!.getSpriteById(0),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
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
