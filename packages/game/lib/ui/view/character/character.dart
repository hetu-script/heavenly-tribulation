import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../global.dart';
import '../../shared/avatar.dart';
import 'bonds.dart';
import '../history.dart';
import '../../shared/constants.dart';
import 'skills.dart';
import '../../shared/responsive_route.dart';
import '../../shared/close_button.dart';

class CharacterView extends StatelessWidget {
  final String? characterId;

  const CharacterView({Key? key, this.characterId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final charId =
        characterId ?? ModalRoute.of(context)!.settings.arguments as String;

    final data = engine.hetu.interpreter
        .invoke('getCharacterById', positionalArgs: [charId]);

    final attributes = data['attributes'];
    final int strength = attributes['strength'];
    final int intelligence = attributes['intelligence'];
    final int perception = attributes['perception'];
    final int superpower = attributes['superpower'];
    final int leadership = attributes['leadership'];
    final int management = attributes['management'];

    final personality = data['personality'];
    final double ideal = personality['ideal'].toStringAsFixed(2);
    final double order = personality['order'].toStringAsFixed(2);
    final double good = personality['good'].toStringAsFixed(2);
    final double social = personality['social'].toStringAsFixed(2);
    final double intuition = personality['intuition'].toStringAsFixed(2);
    final double reason = personality['reason'].toStringAsFixed(2);
    final double controlment = personality['controlment'].toStringAsFixed(2);

    final ageString = engine.hetu.interpreter
        .invoke('getCharAgeString', positionalArgs: [data]);

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
            Container(
              padding: const EdgeInsets.all(10),
              height: MediaQuery.of(context).size.height - kTabBarHeight,
              child: SingleChildScrollView(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics()),
                    shrinkWrap: true,
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Container(
                            alignment: Alignment.center,
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Avatar(
                              avatarAssetKey: 'assets/images/${data['avatar']}',
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(data['name']),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(
                                '${engine.locale['sex']}: ${data['isFemale'] ? engine.locale['female'] : engine.locale['male']}'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text('${engine.locale['age']}: $ageString'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(
                                '${engine.locale['looks']}: ${data['looks'].toStringAsFixed(2)}'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(
                                '${engine.locale['fame']}: ${data['fame'].toString()}'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child:
                                Text('${engine.locale['strength']}: $strength'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(
                                '${engine.locale['intelligence']}: $intelligence'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(
                                '${engine.locale['perception']}: $perception'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(
                                '${engine.locale['superpower']}: $superpower'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(
                                '${engine.locale['leadership']}: $leadership'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(
                                '${engine.locale['management']}: $management'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(ideal > 0
                                ? '${engine.locale['ideal']}(+$ideal)'
                                : '${engine.locale['real']}($ideal)'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(order > 0
                                ? '${engine.locale['order']}(+$order)'
                                : '${engine.locale['chaotic']}($order)'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(good > 0
                                ? '${engine.locale['good']}(+$good)'
                                : '${engine.locale['evil']}($good)'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(social > 0
                                ? '${engine.locale['social']}(+$social)'
                                : '${engine.locale['introspection']}($social)'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(intuition > 0
                                ? '${engine.locale['intuition']}(+$intuition)'
                                : '${engine.locale['sensing']}($intuition)'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(reason > 0
                                ? '${engine.locale['reason']}(+$reason)'
                                : '${engine.locale['fealing']}($reason)'),
                          ),
                          Container(
                            padding: const EdgeInsets.all(5),
                            child: Text(controlment > 0
                                ? '${engine.locale['controlment']}(+$controlment)'
                                : '${engine.locale['relaxation']}($controlment)'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
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
