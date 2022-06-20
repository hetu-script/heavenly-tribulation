import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import '../../shared/avatar.dart';
import '../../shared/constants.dart';

extension DoubleFixed on double {
  double toDoubleAsFixed([int n = 2]) {
    return double.parse(toStringAsFixed(n));
  }
}

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
    final double ideal = (personality['ideal'] as double).toDoubleAsFixed(2);
    final double order = (personality['order'] as double).toDoubleAsFixed(2);
    final double good = (personality['good'] as double).toDoubleAsFixed(2);
    final double social = (personality['social'] as double).toDoubleAsFixed(2);
    final double reason = (personality['reason'] as double).toDoubleAsFixed(2);
    final double control =
        (personality['control'] as double).toDoubleAsFixed(2);
    final double frugal = (personality['frugal'] as double).toDoubleAsFixed(2);
    final double frank = (personality['frank'] as double).toDoubleAsFixed(2);
    final double confidence =
        (personality['confidence'] as double).toDoubleAsFixed(2);
    final double prudence =
        (personality['prudence'] as double).toDoubleAsFixed(2);
    final double empathy =
        (personality['empathy'] as double).toDoubleAsFixed(2);

    final ageString = engine.hetu.interpreter
        .invoke('getCharacterAgeString', positionalArgs: [data]);

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
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
                Text('---${engine.locale['attributes']}---'),
                Text('${engine.locale['strength']}: $strength'),
                Text('${engine.locale['intelligence']}: $intelligence'),
                Text('${engine.locale['perception']}: $perception'),
                Text('${engine.locale['superpower']}: $superpower'),
                Text('${engine.locale['leadership']}: $leadership'),
                Text('${engine.locale['management']}: $management'),
                Text('---${engine.locale['personality']}---'),
                Text(ideal > 0
                    ? '${engine.locale['ideal']}: +$ideal'
                    : '${engine.locale['real']}: $ideal'),
                Text(order > 0
                    ? '${engine.locale['order']}: +$order'
                    : '${engine.locale['chaotic']}: $order'),
                Text(good > 0
                    ? '${engine.locale['good']}: +$good'
                    : '${engine.locale['evil']}: $good'),
                Text(social > 0
                    ? '${engine.locale['extraversion']}: +$social'
                    : '${engine.locale['introspection']}: $social'),
                Text(reason > 0
                    ? '${engine.locale['reasoning']}: +$reason'
                    : '${engine.locale['fealing']}: $reason'),
                Text(control > 0
                    ? '${engine.locale['organizing']}: +$control'
                    : '${engine.locale['relaxing']}: $control'),
                Text(frugal > 0
                    ? '${engine.locale['frugality']}: +$frugal'
                    : '${engine.locale['lavishness']}: $frugal'),
                Text(frank > 0
                    ? '${engine.locale['frankness']}: +$frank'
                    : '${engine.locale['tactness']}: $frank'),
                Text(confidence > 0
                    ? '${engine.locale['confidence']}: +$confidence'
                    : '${engine.locale['cowardness']}: $confidence'),
                Text(prudence > 0
                    ? '${engine.locale['prudence']}: +$prudence'
                    : '${engine.locale['adventurousness']}: $prudence'),
                Text(empathy > 0
                    ? '${engine.locale['empathy']}: +$empathy'
                    : '${engine.locale['indifference']}: $empathy'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
