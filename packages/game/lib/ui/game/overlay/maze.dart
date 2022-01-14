import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../../../ui/pointer_detector.dart';
import '../../../engine/game.dart';
import '../../../engine/scene/maze.dart';
import '../../../ui/shared/avatar.dart';
import '../../../event/event.dart';
import '../../../event/map_event.dart';

class MazeOverlay extends StatefulWidget {
  final SamsaraGame game;
  final MazeScene scene;

  const MazeOverlay(
      {required Key? key, required this.game, required this.scene})
      : super(key: key);

  @override
  _MazeOverlayState createState() => _MazeOverlayState();
}

class _MazeOverlayState extends State<MazeOverlay> {
  SamsaraGame get game => widget.game;
  MazeScene get scene => widget.scene;

  @override
  void initState() {
    super.initState();

    game.registerListener(
      MapEvents.onMapTapped,
      EventHandler(widget.key!, (event) {
        setState(() {});
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroData = game.hetu.invoke('getCurrentCharacterData');
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
                  game.leaveScene('Maze');
                },
                icon: const Icon(Icons.menu_open),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
