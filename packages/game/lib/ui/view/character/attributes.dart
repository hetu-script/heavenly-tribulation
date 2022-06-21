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
    final timestamp = engine.hetu.invoke('getTimestamp');
    final age = timestamp - data['birthTimestamp'];
    final ageString = engine.hetu.invoke('toAgeString', positionalArgs: [age]);
    final birthday = engine.hetu.invoke('formatDateTimeString',
        positionalArgs: [age], namedArgs: {'format': 'date.md'});

    final homeData =
        engine.hetu.invoke('getLocationById', positionalArgs: [data['homeId']]);
    final home = homeData['name'];

    final fatherData = engine.hetu.invoke('getCharacterById',
        positionalArgs: [data['relationships']['fatherId']]);
    final father =
        fatherData != null ? fatherData['name'] : engine.locale['unknown'];
    final motherData = engine.hetu.invoke('getCharacterById',
        positionalArgs: [data['relationships']['motherId']]);
    final mother =
        motherData != null ? motherData['name'] : engine.locale['unknown'];
    final spouseData = engine.hetu.invoke('getCharacterById',
        positionalArgs: [data['relationships']['spouseId']]);
    final spouse =
        spouseData != null ? spouseData['name'] : engine.locale['unknown'];
    final children = <String>[];
    final childrenIds = data['relationships']['childrenIds'];
    for (final id in childrenIds) {
      final childData =
          engine.hetu.invoke('getCharacterById', positionalArgs: [id]);
      children.add(childData['name']);
    }

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
                Text('${engine.locale['birthday']}: $birthday'),
                Text(
                    '${engine.locale['looks']}: ${data['looks'].toStringAsFixed(2)}'),
                if (engine.debugMode)
                  Text(
                      '${engine.locale['favoredLooks']}: ${data['favoredLooks'].toStringAsFixed(2)}'),
                Text('${engine.locale['fame']}: ${data['fame']}'),
                if (engine.debugMode)
                  Text(
                      '${engine.locale['birthPlace']}: ${data['birthPlaceId']}'),
                Text('${engine.locale['home']}: $home'),
                if (engine.debugMode)
                  Text(
                      '${engine.locale['currentLocation']}: ${data['locationId']}'),
                Text('${engine.locale['money']}: ${data['money']}'),
                Text('---${engine.locale['attributes']}---'),
                Text('${engine.locale['strength']}: $strength'),
                Text('${engine.locale['intelligence']}: $intelligence'),
                Text('${engine.locale['perception']}: $perception'),
                Text('${engine.locale['superpower']}: $superpower'),
                Text('${engine.locale['leadership']}: $leadership'),
                Text('${engine.locale['management']}: $management'),
                Text('---${engine.locale['relationship']}---'),
                Text('${engine.locale['father']}: $father'),
                Text('${engine.locale['mother']}: $mother'),
                Text('${engine.locale['spouse']}: $spouse'),
                Text('${engine.locale['children']}: $children'),
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
                Text('---${engine.locale['motivation']}---'),
                Text((data['motivations'] as List)
                    .map((e) => engine.locale[e])
                    .toString()),
                Text('---${engine.locale['thinking']}---'),
                Text((data['thinkings'] as List)
                    .map((e) => engine.locale[e])
                    .toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
