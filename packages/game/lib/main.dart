import 'package:flutter/material.dart';
import 'package:flame/flame.dart';

import 'ui/game_app.dart';
import 'engine/game.dart';
import 'ui/editor/editor.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Flame.device.setPortraitDownOnly();
  await Flame.device.fullScreen();

  final game = SamsaraGame();

  runApp(
    MaterialApp(
      title: 'Tian Dao Qi Jie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
          scrollbarTheme: const ScrollbarThemeData().copyWith(
        thumbColor: MaterialStateProperty.all(Colors.grey),
      )),
      home: GameApp(
        key: UniqueKey(),
        game: game,
      ),
      routes: {
        'editor': (context) => GameEditor(game: game),
      },
    ),
  );
}
