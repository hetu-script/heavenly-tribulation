import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../shared/pointer_detector.dart';
import '../../../engine/engine.dart';
import '../../../engine/scene/maze.dart';
import '../../../ui/shared/avatar.dart';
import '../../../event/event.dart';
import '../../../event/events.dart';

class MazeOverlay extends StatefulWidget {
  final MazeScene scene;

  const MazeOverlay({required Key? key, required this.scene}) : super(key: key);

  @override
  _MazeOverlayState createState() => _MazeOverlayState();
}

class _MazeOverlayState extends State<MazeOverlay> {
  MazeScene get scene => widget.scene;

  @override
  void initState() {
    super.initState();

    engine.registerListener(
      Events.tappedMap,
      EventHandler(widget.key!, (event) {
        setState(() {});
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final heroData = engine.hetu.invoke('getHero');
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
                  borderRadius: BorderRadius.circular(5.0),
                  border: Border.all(
                    width: 2,
                    color: Colors.lightBlue,
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
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(
                  width: 2,
                  color: Colors.lightBlue,
                ),
              ),
              child: IconButton(
                onPressed: () {
                  engine.leaveScene('Maze');
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