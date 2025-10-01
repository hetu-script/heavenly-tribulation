import 'package:flutter/material.dart';

import '../engine.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({
    super.key,
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.canvas,
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.center,
            child: Text(
              engine.isInitted ? engine.locale('loading') : 'loading...',
              style: const TextStyle(fontSize: 18.0),
            ),
          ),
        ],
      ),
    );
  }
}
