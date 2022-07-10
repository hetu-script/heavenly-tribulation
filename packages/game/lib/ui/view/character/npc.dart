import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import '../../shared/close_button.dart';
import '../../shared/responsive_route.dart';
import '../../shared/label.dart';
import '../../avatar.dart';
import '../../shared/dynamic_color_progressbar.dart';

class NpcView extends StatelessWidget {
  const NpcView({
    super.key,
    required this.npcData,
  });

  final HTStruct npcData;

  @override
  Widget build(BuildContext context) {
    final ageString =
        engine.invoke('getEntityAgeString', positionalArgs: [npcData]);

    return ResponsiveRoute(
      alignment: AlignmentDirectional.topCenter,
      size: const Size(400.0, 400.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(npcData['name']),
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(left: 10.0, right: 16.0),
                        child: Avatar(
                          avatarAssetKey: 'assets/images/${npcData['icon']}',
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 5.0, top: 5.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DynamicColorProgressBar(
                              width: 175.0,
                              height: 20.0,
                              value: npcData['life'],
                              max: npcData['lifeMax'],
                              showNumberAsPercentage: false,
                              colors: const <Color>[Colors.red, Colors.green],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  Wrap(
                    children: [
                      Text('${engine.locale['name']}: ${npcData['name']}'),
                      Text('${engine.locale['age']}: $ageString'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
