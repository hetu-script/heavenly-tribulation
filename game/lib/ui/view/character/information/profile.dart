import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../../global.dart';
import '../../../avatar.dart';
import 'package:samsara/ui/flutter/constants.dart';
import 'package:samsara/ui/flutter/label.dart';
import '../../../util.dart';

class ProfileView extends StatelessWidget {
  const ProfileView({
    super.key,
    required this.characterData,
  });

  final HTStruct characterData;

  @override
  Widget build(BuildContext context) {
    final ageString =
        engine.invoke('getEntityAgeString', positionalArgs: [characterData]);
    final fame = engine
        .invoke('getCharacterFameString', positionalArgs: [characterData]);
    final birthday = engine
        .invoke('getEntityBirthDateString', positionalArgs: [characterData]);
    final organizationId = characterData['organizationId'];
    String organization = getNameFromId(organizationId);
    final title =
        engine.invoke('getCharacterTitle', positionalArgs: [characterData]) ??
            engine.locale['none'];
    final home = getNameFromId(characterData['homeId']);
    final nation = getNameFromId(characterData['nationId']);

    final father = getNameFromId(characterData['relationships']['fatherId']);
    final mother = getNameFromId(characterData['relationships']['motherId']);
    final spouse = getNameFromId(characterData['relationships']['spouseId']);
    final siblings =
        getNamesFromIds(characterData['relationships']['siblingIds'])
            .map((e) => Label(e));
    final childs =
        getNamesFromIds(characterData['relationships']['childrenIds'])
            .map((e) => Label(e));

    final personality = characterData['personality'];
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

    final motifvationNames = characterData['motivations'] as List;
    final motivations = motifvationNames.isNotEmpty
        ? motifvationNames.map((e) => Label(engine.locale[e])).toList()
        : [Text(engine.locale['none'])];
    final thinkingNames = characterData['thinkings'] as List;
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
                  margin: const EdgeInsets.only(left: 10.0, right: 16.0),
                  child: Avatar(
                    image: AssetImage('assets/images/${characterData['icon']}'),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 5.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //     '${engine.locale['name']}: ${characterData['name']}'),
                      Text(
                          '${engine.locale['sex']}: ${characterData['isFemale'] ? engine.locale['female'] : engine.locale['male']}'),
                      Text('${engine.locale['age']}: $ageString'),
                      Text(
                          '${engine.locale['charisma']}: ${characterData['charisma'].truncate()}'),
                      Text('${engine.locale['home']}: $home'),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 30.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(
                      //     '${engine.locale['money']}: ${characterData['money']}'),
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
              if (engine.config.debugMode) const Divider(),
              Text('---${engine.locale['debug']}---'),
              Wrap(
                children: [
                  Label(
                    '${engine.locale['birthday']}: $birthday',
                    width: 120.0,
                  ),
                  Label(
                    '${engine.locale['favoredCharisma']}: ${characterData['favoredCharisma'].truncate()}',
                    width: 240.0,
                  ),
                  Label(
                    '${engine.locale['birthPlace']}: ${characterData['birthPlaceId']}',
                    width: 200.0,
                  ),
                  Label(
                    '${engine.locale['currentLocation']}: ${characterData['locationId']}',
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
