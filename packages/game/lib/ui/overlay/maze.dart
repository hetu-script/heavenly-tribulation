import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/event.dart';

import '../../../ui/shared/avatar.dart';
import '../../global.dart';
import '../../scene/maze.dart';

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
    final heroData = engine.invoke('getHero');
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: SceneWidget(scene: scene),
          ),
          Positioned(
            left: 5,
            top: 5,
            child: Container(
                height: 120,
                width: 180,
                decoration: BoxDecoration(
                  borderRadius: kBorderRadius,
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
                    ),
                  ],
                )),
          ),
          Positioned(
            right: 5,
            top: 5,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: kBorderRadius,
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
