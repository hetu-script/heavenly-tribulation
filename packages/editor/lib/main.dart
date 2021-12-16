import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'src/editor.dart';

void main() {
  runApp(MaterialApp(
    title: 'The Banished Immortal: Game Module Editor',
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      brightness: Brightness.light,
    ),
    home: const GameEditor(),
  ));
}
