import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../../global.dart';
import '../../../shared/constants.dart';
import '../../../shared/label.dart';

class StatusEffectsView extends StatelessWidget {
  const StatusEffectsView({
    super.key,
    required this.characterData,
  });

  final HTStruct characterData;

  @override
  Widget build(BuildContext context) {
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
              // Text('---${engine.locale['attributes']}---'),
              Wrap(),
              const Divider(),
            ],
          ),
        ),
      ),
    );
  }
}
