import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import '../../shared/avatar.dart';
import '../../shared/constants.dart';
import '../shared/label.dart';
import '../../util.dart';

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
    final timestamp = engine.invoke('getTimestamp');
    final age = timestamp - data['birthTimestamp'];
    final ageString = engine.invoke('toAgeString', positionalArgs: [age]);
    final fame =
        engine.invoke('getCharacterFameString', positionalArgs: [data]);
    final birthday = engine.invoke('formatDateTimeString',
        positionalArgs: [age], namedArgs: {'format': 'date.md'});
    final organizationId = data['organizationId'];
    String organization = getNameFromId(organizationId);
    final title = engine.locale[data['currentTitleId']];
    final home = getNameFromId(data['homeId']);
    final nation = getNameFromId(data['nationId']);

    final father = getNameFromId(data['relationships']['fatherId']);
    final mother = getNameFromId(data['relationships']['motherId']);
    final spouse = getNameFromId(data['relationships']['spouseId']);
    final siblings = getNamesFromEntityIds(data['relationships']['siblingIds'])
        .map((e) => Label(e));
    final childs = getNamesFromEntityIds(data['relationships']['childrenIds'])
        .map((e) => Label(e));

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
    final double generosity =
        (personality['generosity'] as double).toDoubleAsFixed(2);

    final motifvationNames = data['motivations'] as List;
    final motivations = motifvationNames.isNotEmpty
        ? motifvationNames.map((e) => Label(engine.locale[e])).toList()
        : [Text(engine.locale['none'])];
    final thinkingNames = data['thinkings'] as List;
    final thinkings = thinkingNames.isNotEmpty
        ? thinkingNames.map((e) => Label(engine.locale[e])).toList()
        : [Text(engine.locale['none'])];

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
              Row(children: [
                Container(
                  margin: const EdgeInsets.only(left: 10.0, right: 33.0),
                  child: Avatar(
                    avatarAssetKey: 'assets/images/${data['avatar']}',
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 10.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${engine.locale['name']}: ${data['name']}'),
                      Text(
                          '${engine.locale['sex']}: ${data['isFemale'] ? engine.locale['female'] : engine.locale['male']}'),
                      Text('${engine.locale['age']}: $ageString'),
                      Text(
                          '${engine.locale['looks']}: ${data['looks'].toStringAsFixed(2)}'),
                      Text('${engine.locale['home']}: $home'),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${engine.locale['money']}: ${data['money']}'),
                      Text('${engine.locale['fame']}: $fame'),
                      Text('${engine.locale['organization']}: $organization'),
                      Text('${engine.locale['title']}: $title'),
                      Text('${engine.locale['nation']}: $nation'),
                    ],
                  ),
                ),
              ]),
              const Divider(),
              // Text('---${engine.locale['relationship']}---'),
              Wrap(children: [
                Label(
                  '${engine.locale['father']}: $father',
                  width: 120.0,
                ),
                Label(
                  '${engine.locale['mother']}: $mother',
                  width: 120.0,
                ),
                Label(
                  '${engine.locale['spouse']}: $spouse',
                  width: 120.0,
                ),
                LabelsWrap(
                  minWidth: 120.0,
                  '${engine.locale['siblings']}: ',
                  children: siblings,
                ),
                LabelsWrap(
                  minWidth: 120.0,
                  '${engine.locale['children']}: ',
                  children: childs,
                ),
              ]),
              const Divider(),
              // Text('---${engine.locale['attributes']}---'),
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
              const Divider(),
              // Text('---${engine.locale['personality']}---'),
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
                  Label(
                    empathy > 0
                        ? '${engine.locale['generosity']}: +$generosity'
                        : '${engine.locale['stinginess']}: $generosity',
                    width: 120.0,
                  ),
                ],
              ),
              if (engine.debugMode) const Divider(),
              Text('---${engine.locale['debug']}---'),
              Wrap(
                children: [
                  Label(
                    '${engine.locale['birthday']}: $birthday',
                    width: 120.0,
                  ),
                  Label(
                    '${engine.locale['favoredLooks']}: ${data['favoredLooks'].toStringAsFixed(2)}',
                    width: 240.0,
                  ),
                  Label(
                    '${engine.locale['birthPlace']}: ${data['birthPlaceId']}',
                    width: 200.0,
                  ),
                  Label(
                    '${engine.locale['currentLocation']}: ${data['locationId']}',
                    width: 200.0,
                  ),
                  LabelsWrap(
                    '${engine.locale['motivation']}: ',
                    minWidth: 120.0,
                    children: motivations,
                  ),
                  // const Divider(
                  //   color: Colors.transparent,
                  //   height: 0,
                  // ),
                  LabelsWrap(
                    '${engine.locale['thinking']}:',
                    minWidth: 120.0,
                    children: thinkings,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
