import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '..,/../../../../global.dart';
import '../../shared/close_button.dart';
import '../../shared/responsive_route.dart';
import '../../shared/label.dart';
import '../../avatar.dart';

const kEnemyStats = [
  'strength',
  'dexterity',
  'constitution',
  'superpower',
  'perception',
];

class EnemyView extends StatelessWidget {
  const EnemyView({
    super.key,
    required this.data,
  });

  final HTStruct data;

  @override
  Widget build(BuildContext context) {
    final ageString =
        engine.invoke('getEntityAgeString', positionalArgs: [data]);

    return ResponsiveRoute(
      alignment: AlignmentDirectional.topCenter,
      size: const Size(400.0, 400.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(data['name']),
          actions: const [ButtonClose()],
        ),
        body: Container(
          padding: const EdgeInsets.all(10),
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
                        avatarAssetKey: 'assets/images/${data['icon']}',
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(left: 5.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${engine.locale['name']}: ${data['name']}'),
                          Text('${engine.locale['age']}: $ageString'),
                        ],
                      ),
                    ),
                    // Container(
                    //   margin: const EdgeInsets.only(left: 30.0),
                    //   child: Column(
                    //     crossAxisAlignment: CrossAxisAlignment.start,
                    //     children: [
                    //       Text(
                    //           '${engine.locale['money']}: ${characterData['money']}'),
                    //       Text('${engine.locale['fame']}: $fame'),
                    //       Text(
                    //           '${engine.locale['organization']}: $organization'),
                    //       Text('${engine.locale['title']}: $title'),
                    //       Text('${engine.locale['nation']}: $nation'),
                    //     ],
                    //   ),
                    // ),
                  ]),
                  const Divider(),
                  // Text('---${engine.locale['attributes']}---'),
                  Wrap(
                    children: kEnemyStats
                        .map(
                          (name) => Label(
                            '${engine.locale[name]}: ${data['stats'][name] ?? 0}',
                            width: 120.0,
                          ),
                        )
                        .toList(),
                  ),
                  // if (engine.debugMode) const Divider(),
                  // Text('---${engine.locale['debug']}---'),
                  // Wrap(
                  //   children: [
                  //     Label(
                  //       '${engine.locale['birthday']}: $birthday',
                  //       width: 120.0,
                  //     ),
                  //     Label(
                  //       '${engine.locale['favoredLooks']}: ${characterData['favoredLooks'].toStringAsFixed(2)}',
                  //       width: 240.0,
                  //     ),
                  //     Label(
                  //       '${engine.locale['birthPlace']}: ${characterData['birthPlaceId']}',
                  //       width: 200.0,
                  //     ),
                  //     Label(
                  //       '${engine.locale['currentLocation']}: ${characterData['locationId']}',
                  //       width: 200.0,
                  //     ),
                  //     LabelsWrap(
                  //       '${engine.locale['motivation']}: ',
                  //       minWidth: 120.0,
                  //       children: motivations,
                  //     ),
                  //     // const Divider(
                  //     //   color: Colors.transparent,
                  //     //   height: 0,
                  //     // ),
                  //     LabelsWrap(
                  //       '${engine.locale['thinking']}:',
                  //       minWidth: 120.0,
                  //       children: thinkings,
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
