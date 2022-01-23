import 'package:flutter/material.dart';

import '../../../engine/engine.dart';
import '../../shared/avatar.dart';
import 'bonds.dart';
import '../history.dart';

const _kCharacterViewTabLengths = 3;

class CharacterView extends StatelessWidget {
  const CharacterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final characterId = ModalRoute.of(context)!.settings.arguments as String;

    final data =
        engine.hetu.invoke('getCharacterById', positionalArgs: [characterId]);

    final personality = data['personality'];
    final int ideal = personality['ideal'];
    final int order = personality['order'];
    final int good = personality['good'];
    final int social = personality['social'];
    final int intuition = personality['intuition'];
    final int reason = personality['reason'];
    final int controlment = personality['controlment'];

    final ageString =
        engine.hetu.invoke('getCharAgeString', positionalArgs: [data]);

    return DefaultTabController(
      length: _kCharacterViewTabLengths,
      child: Scaffold(
        appBar: AppBar(
          title: Text(data['name']),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.summarize),
                text: engine.locale['stats'],
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
        ),
        body: TabBarView(
          children: <Widget>[
            Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Avatar(
                    avatarAssetKey: 'assets/images/${data['avatar']}',
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(data['name']),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                      '${engine.locale['sex']}: ${data['isFemale'] ? engine.locale['female'] : engine.locale['male']}'),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text('${engine.locale['age']}: $ageString'),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                      '${engine.locale['looks']}: ${data['looks'].toStringAsFixed(2)}'),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(
                      '${engine.locale['fame']}: ${data['fame'].toString()}'),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(ideal > 0
                      ? '${engine.locale['ideal']}(+$ideal)'
                      : '${engine.locale['real']}($ideal)'),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(order > 0
                      ? '${engine.locale['order']}(+$order)'
                      : '${engine.locale['chaotic']}($order)'),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(good > 0
                      ? '${engine.locale['good']}(+$good)'
                      : '${engine.locale['evil']}($good)'),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(social > 0
                      ? '${engine.locale['social']}(+$social)'
                      : '${engine.locale['introspection']}($social)'),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(intuition > 0
                      ? '${engine.locale['intuition']}(+$intuition)'
                      : '${engine.locale['sensing']}($intuition)'),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(reason > 0
                      ? '${engine.locale['reason']}(+$reason)'
                      : '${engine.locale['fealing']}($reason)'),
                ),
                Padding(
                  padding: const EdgeInsets.all(5),
                  child: Text(controlment > 0
                      ? '${engine.locale['controlment']}(+$controlment)'
                      : '${engine.locale['relaxation']}($controlment)'),
                ),
              ],
            ),
            CharacterBondsView(data: data['bonds']),
            HistoryView(data: data['incidentIndexes']),
          ],
        ),
      ),
    );
  }
}
