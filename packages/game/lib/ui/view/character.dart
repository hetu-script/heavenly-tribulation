import 'package:flutter/material.dart';

import '../../../engine/engine.dart';
import '../shared/avatar.dart';

const _kCharacterViewTabLengths = 2;

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

    return DefaultTabController(
      length: _kCharacterViewTabLengths,
      child: Scaffold(
        appBar: AppBar(
          title: Text(engine.locale['info']),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.summarize),
                text: '${engine.locale['stats']})',
              ),
              Tab(
                icon: const Icon(Icons.history),
                text: '${engine.locale['history']})',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            Column(
              children: <Widget>[
                Avatar(
                  avatarAssetKey: 'assets/images/${data['avatar']}',
                ),
                Text(data['name']),
                Text(data['fame'].toString()),
                Text(ideal > 0
                    ? '${engine.locale['ideal']}(+$ideal)'
                    : '${engine.locale['real']}($ideal)'),
                Text(order > 0
                    ? '${engine.locale['order']}(+$order)'
                    : '${engine.locale['chaotic']}($order)'),
                Text(good > 0
                    ? '${engine.locale['good']}(+$good)'
                    : '${engine.locale['evil']}($good)'),
                Text(social > 0
                    ? '${engine.locale['social']}(+$social)'
                    : '${engine.locale['introspection']}($social)'),
                Text(intuition > 0
                    ? '${engine.locale['intuition']}(+$intuition)'
                    : '${engine.locale['sensing']}($intuition)'),
                Text(reason > 0
                    ? '${engine.locale['reason']}(+$reason)'
                    : '${engine.locale['fealing']}($reason)'),
                Text(controlment > 0
                    ? '${engine.locale['controlment']}(+$controlment)'
                    : '${engine.locale['relaxation']}($controlment)'),
              ],
            ),
            const Icon(Icons.history),
          ],
        ),
      ),
    );
  }
}
