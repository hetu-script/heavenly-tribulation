import 'package:flutter/material.dart';

import 'ui/game_app.dart';
import 'engine/game.dart';

void main() {
  runApp(MaterialApp(
      title: 'Tian Dao Qi Jie',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.light().copyWith(
          scrollbarTheme: const ScrollbarThemeData().copyWith(
        thumbColor: MaterialStateProperty.all(Colors.grey),
      )),
      home: GameApp(game: SamsaraGame())));
}
