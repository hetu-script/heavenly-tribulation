import 'package:flutter/material.dart';
import 'package:flame/flame.dart';

import 'ui/game_app.dart';
import 'engine/game.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Flame.device.setPortraitDownOnly();
  await Flame.device.fullScreen();

  runApp(MaterialApp(
      title: 'Tian Dao Qi Jie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
          scrollbarTheme: const ScrollbarThemeData().copyWith(
        thumbColor: MaterialStateProperty.all(Colors.grey),
      )),
      home: GameApp(key: UniqueKey(), game: SamsaraGame())));
}
