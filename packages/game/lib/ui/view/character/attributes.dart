import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import '../../shared/avatar.dart';
import '../../shared/constants.dart';
import '../shared/label.dart';

extension DoubleFixed on double {
  double toDoubleAsFixed([int n = 2]) {
    return double.parse(toStringAsFixed(n));
  }
}

class CharacterAttributesView extends StatelessWidget {
  const CharacterAttributesView({
    super.key,
    required this.data,
  });

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
        child: SingleChildScrollView(
          child: Column(
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
              Text('${engine.locale['home']}: $home'),
              Text('${engine.locale['money']}: ${data['money']}'),
              Text('${engine.locale['fame']}: ${data['fame']}'),
              if (engine.debugMode) ...[
                Text('---${engine.locale['debug']}---'),
                Text(
                    '${engine.locale['favoredLooks']}: ${data['favoredLooks'].toStringAsFixed(2)}'),
                Text('${engine.locale['birthPlace']}: ${data['birthPlaceId']}'),
                Text(
                    '${engine.locale['currentLocation']}: ${data['locationId']}'),
              ],
              Text('---${engine.locale['attributes']}---'),
              Wrap(children: [
                Label(
                  '${engine.locale['strength']}: $strength',
                  width: 120.0,
                ),
                Label(
                  '${engine.locale['intelligence']}: $intelligence',
                  width: 120.0,
                ),
                Label(
                  '${engine.locale['perception']}: $perception',
                  width: 120.0,
                ),
                Label(
                  '${engine.locale['superpower']}: $superpower',
                  width: 120.0,
                ),
                Label(
                  '${engine.locale['leadership']}: $leadership',
                  width: 120.0,
                ),
                Label(
                  '${engine.locale['management']}: $management',
                  width: 120.0,
                ),
              ]),
              Text('---${engine.locale['relationship']}---'),
              Text('${engine.locale['father']}: $father'),
              Text('${engine.locale['mother']}: $mother'),
              Text('${engine.locale['spouse']}: $spouse'),
              Text('${engine.locale['children']}: $children'),
              Text('---${engine.locale['personality']}---'),
              Wrap(
                children: [
                  Label(
                    ideal > 0
                        ? '${engine.locale['ideal']}: +$ideal'
                        : '${engine.locale['real']}: $ideal',
                    width: 120.0,
                  ),
                  Label(
                    order > 0
                        ? '${engine.locale['order']}: +$order'
                        : '${engine.locale['chaotic']}: $order',
                    width: 120.0,
                  ),
                  Label(
                    good > 0
                        ? '${engine.locale['good']}: +$good'
                        : '${engine.locale['evil']}: $good',
                    width: 120.0,
                  ),
                  Label(
                    social > 0
                        ? '${engine.locale['extraversion']}: +$social'
                        : '${engine.locale['introspection']}: $social',
                    width: 120.0,
                  ),
                  Label(
                    reason > 0
                        ? '${engine.locale['reasoning']}: +$reason'
                        : '${engine.locale['fealing']}: $reason',
                    width: 120.0,
                  ),
                  Label(
                    control > 0
                        ? '${engine.locale['organizing']}: +$control'
                        : '${engine.locale['relaxing']}: $control',
                    width: 120.0,
                  ),
                  Label(
                    frugal > 0
                        ? '${engine.locale['frugality']}: +$frugal'
                        : '${engine.locale['lavishness']}: $frugal',
                    width: 120.0,
                  ),
                  Label(
                    frank > 0
                        ? '${engine.locale['frankness']}: +$frank'
                        : '${engine.locale['tactness']}: $frank',
                    width: 120.0,
                  ),
                  Label(
                    confidence > 0
                        ? '${engine.locale['confidence']}: +$confidence'
                        : '${engine.locale['cowardness']}: $confidence',
                    width: 120.0,
                  ),
                  Label(
                    prudence > 0
                        ? '${engine.locale['prudence']}: +$prudence'
                        : '${engine.locale['adventurousness']}: $prudence',
                    width: 120.0,
                  ),
                  Label(
                    empathy > 0
                        ? '${engine.locale['empathy']}: +$empathy'
                        : '${engine.locale['indifference']}: $empathy',
                    width: 120.0,
                  ),
                ],
              ),
              Text('---${engine.locale['motivation']}---'),
              Wrap(
                children: (data['motivations'] as List)
                    .map((e) => Label(engine.locale[e]))
                    .toList(),
              ),
              Text('---${engine.locale['thinking']}---'),
              Wrap(
                children: (data['thinkings'] as List)
                    .map((e) => Label(engine.locale[e]))
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
