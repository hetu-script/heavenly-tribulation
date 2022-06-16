import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import '../../shared/avatar.dart';
import '../../shared/constants.dart';

class CharacterAttributesView extends StatelessWidget {
  const CharacterAttributesView({
    Key? key,
    required this.data,
  }) : super(key: key);

  final HTStruct data;

  @override
  Widget build(BuildContext context) {
    final attributes = data['attributes'];
    final int strength = attributes['strength'];
    final int intelligence = attributes['intelligence'];
    final int perception = attributes['perception'];
    final int superpower = attributes['superpower'];
    final int leadership = attributes['leadership'];
    final int management = attributes['management'];

    final personality = data['personality'];
    final double ideal = personality['ideal'];
    final String idealString = ideal.toStringAsFixed(2);
    final double order = personality['order'];
    final String orderString = order.toStringAsFixed(2);
    final double good = personality['good'];
    final String goodString = good.toStringAsFixed(2);
    final double social = personality['social'];
    final String socialString = social.toStringAsFixed(2);
    final double intuition = personality['intuition'];
    final String intuitionString = intuition.toStringAsFixed(2);
    final double reason = personality['reason'];
    final String reasonString = reason.toStringAsFixed(2);
    final double controlment = personality['controlment'];
    final String controlmentString = controlment.toStringAsFixed(2);

    final ageString = engine.hetu.interpreter
        .invoke('getCharAgeString', positionalArgs: [data]);

    return Container(
      padding: const EdgeInsets.all(10),
      height: MediaQuery.of(context).size.height - kTabBarHeight,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
          },
        ),
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  alignment: Alignment.topLeft,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: Avatar(
                    avatarAssetKey: 'assets/images/${data['avatar']}',
                  ),
                ),
                Text(data['name']),
                Text(
                    '${engine.locale['sex']}: ${data['isFemale'] ? engine.locale['female'] : engine.locale['male']}'),
                Text('${engine.locale['age']}: $ageString'),
                Text(
                    '${engine.locale['looks']}: ${data['looks'].toStringAsFixed(2)}'),
                Text('${engine.locale['fame']}: ${data['fame'].toString()}'),
                Text('${engine.locale['fame']}: ${data['fame'].toString()}'),
                Text('---${engine.locale['attributes']}---'),
                Text('${engine.locale['strength']}: $strength'),
                Text('${engine.locale['intelligence']}: $intelligence'),
                Text('${engine.locale['perception']}: $perception'),
                Text('${engine.locale['superpower']}: $superpower'),
                Text('${engine.locale['leadership']}: $leadership'),
                Text('${engine.locale['management']}: $management'),
                Text('---${engine.locale['personality']}---'),
                Text(ideal > 0
                    ? '${engine.locale['ideal']}: +$idealString'
                    : '${engine.locale['real']}: $idealString'),
                Text(order > 0
                    ? '${engine.locale['order']}: +$orderString'
                    : '${engine.locale['chaotic']}: $orderString'),
                Text(good > 0
                    ? '${engine.locale['good']}: +$goodString'
                    : '${engine.locale['evil']}: $goodString'),
                Text(social > 0
                    ? '${engine.locale['social']}: +$socialString'
                    : '${engine.locale['introspection']}: $socialString'),
                Text(intuition > 0
                    ? '${engine.locale['intuition']}: +$intuitionString'
                    : '${engine.locale['sensing']}: $intuitionString'),
                Text(reason > 0
                    ? '${engine.locale['reason']}: +$reasonString'
                    : '${engine.locale['fealing']}: $reasonString'),
                Text(controlment > 0
                    ? '${engine.locale['controlment']}: +$controlmentString'
                    : '${engine.locale['relaxation']}: $controlmentString'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
