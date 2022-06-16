import 'package:flutter/material.dart';

import '../../../global.dart';
import 'bonds.dart';
import '../history.dart';
import '../../shared/constants.dart';
import 'skills.dart';
import '../../shared/responsive_route.dart';
import '../../shared/close_button.dart';
import 'attributes.dart';

class CharacterView extends StatelessWidget {
  final String? characterId;

  const CharacterView({Key? key, this.characterId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final charId =
        characterId ?? ModalRoute.of(context)!.settings.arguments as String;

    final data = engine.hetu.interpreter
        .invoke('getCharacterById', positionalArgs: [charId]);

    final layout = DefaultTabController(
      length: kCharacterViewTabLengths,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(data['name']),
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                icon: const Icon(Icons.summarize),
                text: engine.locale['infomation'],
              ),
              Tab(
                icon: const Icon(Icons.flash_on),
                text: engine.locale['cultivation'],
              ),
              Tab(
                icon: const Icon(Icons.sync_alt),
                text: engine.locale['bonds'],
              ),
              Tab(
                icon: const Icon(Icons.history),
                text: engine.locale['history'],
              ),
            ],
          ),
          actions: const [ButtonClose()],
        ),
        body: TabBarView(
          children: <Widget>[
            CharacterAttributesView(data: data),
            CharacterSkillsView(data: data['skills']),
            CharacterBondsView(data: data['bonds']),
            HistoryView(data: data['experiencedIncidentIndexes']),
          ],
        ),
      ),
    );

    return ResponsiveRoute(
      child: layout,
      alignment: AlignmentDirectional.topStart,
      size: const Size(400.0, 400.0),
    );
  }
}
