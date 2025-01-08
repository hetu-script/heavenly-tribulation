import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';

import '../engine.dart';

class GameOver extends StatelessWidget {
  const GameOver({
    super.key,
    this.child,
  });

  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Container(
        alignment: AlignmentDirectional.center,
        width: 300.0,
        height: 300.0,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            child ??
                Text(
                  engine.locale('gameOver'),
                  style: const TextStyle(fontSize: 48.0),
                ),
            Padding(
              padding: const EdgeInsets.all(25.0),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Label(
                  engine.locale('back2menu'),
                  width: 100.0,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
