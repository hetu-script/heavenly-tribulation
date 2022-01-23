import 'package:flutter/material.dart';

import '../../../engine/engine.dart';
import '../../shared/avatar.dart';
import 'bonds.dart';
import '../history.dart';
import '../../shared/constants.dart';

const _kCharacterViewTabLengths = 3;

class CharacterView extends StatelessWidget {
  const CharacterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final characterId = ModalRoute.of(context)!.settings.arguments as String;

    final data =
        engine.hetu.invoke('getCharacterById', positionalArgs: [characterId]);

    final personality = data['personality'];
    final double ideal = personality['ideal'];
    final double order = personality['order'];
    final double good = personality['good'];
    final double social = personality['social'];
    final double intuition = personality['intuition'];
    final double reason = personality['reason'];
    final double controlment = personality['controlment'];

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
            Container(
              padding: const EdgeInsets.all(10),
              height: MediaQuery.of(context).size.height - kTabBarHeight,
              child: SingleChildScrollView(
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Align(
                        alignment: Alignment.center,
                        child: Column(
                          children: <Widget>[
                            Container(
                              alignment: Alignment.center,
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Avatar(
                                avatarAssetKey:
                                    'assets/images/${data['avatar']}',
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
                              child:
                                  Text('${engine.locale['age']}: $ageString'),
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
                              child: Text(ideal > 0
                                  ? '${engine.locale['ideal']}(+${ideal.toStringAsFixed(2)})'
                                  : '${engine.locale['real']}(${ideal.toStringAsFixed(2)})'),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              child: Text(order > 0
                                  ? '${engine.locale['order']}(+${order.toStringAsFixed(2)})'
                                  : '${engine.locale['chaotic']}(${order.toStringAsFixed(2)})'),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              child: Text(good > 0
                                  ? '${engine.locale['good']}(+${good.toStringAsFixed(2)})'
                                  : '${engine.locale['evil']}(${good.toStringAsFixed(2)})'),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              child: Text(social > 0
                                  ? '${engine.locale['social']}(+${social.toStringAsFixed(2)})'
                                  : '${engine.locale['introspection']}(${social.toStringAsFixed(2)})'),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              child: Text(intuition > 0
                                  ? '${engine.locale['intuition']}(+${intuition.toStringAsFixed(2)})'
                                  : '${engine.locale['sensing']}(${intuition.toStringAsFixed(2)})'),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              child: Text(reason > 0
                                  ? '${engine.locale['reason']}(+${reason.toStringAsFixed(2)})'
                                  : '${engine.locale['fealing']}(${reason.toStringAsFixed(2)})'),
                            ),
                            Container(
                              padding: const EdgeInsets.all(5),
                              child: Text(controlment > 0
                                  ? '${engine.locale['controlment']}(+${controlment.toStringAsFixed(2)})'
                                  : '${engine.locale['relaxation']}(${controlment.toStringAsFixed(2)})'),
                            ),
                          ],
                        ))
                  ],
                ),
              ),
            ),
            CharacterBondsView(data: data['bonds']),
            HistoryView(data: data['incidentIndexes']),
          ],
        ),
      ),
    );
  }
}
