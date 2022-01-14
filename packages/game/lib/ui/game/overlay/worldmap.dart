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

enum _CenterButtonMode {
  rest,
  moveTo,
  movingNorth,
  movingSouth,
  movingWest,
  movingEast,
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

  SpriteSheet? walkingSpriteSheet;

  var _centerButtonMode = _CenterButtonMode.rest;

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
      setState(() {
        if (_centerButtonMode == _CenterButtonMode.rest ||
            _centerButtonMode == _CenterButtonMode.moveTo) {
          final e = event as MapEvent;
          final terrain = e.terrain!;
          if (terrain.left == scene.map?.heroX &&
              terrain.top == scene.map?.heroY) {
            _centerButtonMode = _CenterButtonMode.rest;
          } else {
            _centerButtonMode = _CenterButtonMode.moveTo;
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

    Widget? centerButtonWidget;
    switch (_centerButtonMode) {
      case _CenterButtonMode.rest:
        if (walkingSpriteSheet != null) {
          centerButtonWidget = SpriteWidget(
            anchor: Anchor.center,
            sprite: walkingSpriteSheet!.getSpriteById(0),
          );
        }
        break;
      case _CenterButtonMode.moveTo:
        centerButtonWidget =
            const Image(image: AssetImage('assets/images/icon/move_to.png'));
        break;
      case _CenterButtonMode.movingSouth:
        if (walkingSpriteSheet != null) {
          centerButtonWidget = SpriteAnimationWidget(
              animation:
                  walkingSpriteSheet!.createAnimation(row: 0, stepTime: 0.2));
        }
        break;
      case _CenterButtonMode.movingEast:
        if (walkingSpriteSheet != null) {
          centerButtonWidget = SpriteAnimationWidget(
              animation:
                  walkingSpriteSheet!.createAnimation(row: 1, stepTime: 0.2));
        }
        break;
      case _CenterButtonMode.movingNorth:
        if (walkingSpriteSheet != null) {
          centerButtonWidget = SpriteAnimationWidget(
              animation:
                  walkingSpriteSheet!.createAnimation(row: 2, stepTime: 0.2));
        }
        break;
      case _CenterButtonMode.movingWest:
        if (walkingSpriteSheet != null) {
          centerButtonWidget = SpriteAnimationWidget(
              animation:
                  walkingSpriteSheet!.createAnimation(row: 3, stepTime: 0.2));
        }
        break;
    }

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
                      child: centerButtonWidget,
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
