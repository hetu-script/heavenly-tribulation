import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../../../ui/pointer_detector.dart';
import '../../../engine/game.dart';
import '../../../engine/scene/worldmap.dart';
import '../../../ui/shared/avatar.dart';
import '../../../engine/tilemap/map.dart';

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

  @override
  void initState() {
    super.initState();

    game.registerListener(MapEvents.tileTapped, (event) {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final heroData = game.hetu.invoke('getCurrentCharacterData');
    final informationWidgets = <Widget>[];
    if (scene.map != null) {
      informationWidgets.addAll(
        [
          Text(
              'X: ${scene.map!.selectedTerrain!.left}, Y: ${scene.map!.selectedTerrain!.top}'),
          Text(
              '地域: ${scene.map!.zones[scene.map!.selectedTerrain!.zoneIndex].name}')
        ],
      );
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

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
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
            left: 5,
            top: 5,
            child: Container(
                height: 120,
                width: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5.0),
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
            right: 5,
            top: 5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5.0),
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
            left: 5,
            bottom: 5,
            child: Container(
              height: 200,
              width: 240,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(5.0),
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
        ],
      ),
    );
  }
}
