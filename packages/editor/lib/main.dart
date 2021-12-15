import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'src/editor.dart';

void main() {
  runApp(MaterialApp(
    title: 'Tian Dao Qi Jie Module Editor',
    localizationsDelegates: const [
      AppLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeData(
      brightness: Brightness.light,
    ),
    home: const GameEditor(),
  ));
}
