import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../config.dart';
import 'package:samsara/ui/close_button.dart';
import 'package:samsara/ui/responsive_window.dart';
// import '../../shared/label.dart';
import '../../avatar.dart';
import 'package:samsara/ui/dynamic_color_progressbar.dart';

class NpcView extends StatelessWidget {
  const NpcView({
    super.key,
    required this.npcData,
  });

  final HTStruct npcData;

  @override
  Widget build(BuildContext context) {
    final ageString =
        engine.hetu.invoke('getEntityAgeString', positionalArgs: [npcData]);

    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      size: const Size(400.0, 400.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(npcData['name']),
          actions: const [CloseButton2()],
        ),
        body: Container(
          padding: const EdgeInsets.all(10),
          child: SingleChildScrollView(
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(left: 10.0, right: 16.0),
                      child: Avatar(
                        image: AssetImage(
                            'assets/images/avatar/${npcData['icon']}'),
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
                            value: npcData['stats']['life'],
                            max: npcData['stats']['lifeMax'],
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
                  spacing: 8.0,
                  children: [
                    Text('${engine.locale('name')}: ${npcData['name']}'),
                    Text('${engine.locale('age')}: $ageString'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
