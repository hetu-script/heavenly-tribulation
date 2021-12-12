import 'package:flutter/material.dart';

// import 'widget/view/main_frame.dart';

import 'game_app.dart';
import 'engine/game.dart';

void main() {
  runApp(MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      home: GameApp(game: SamsaraGame())));
}
