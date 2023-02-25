import 'package:flutter/material.dart';

import '../../global.dart';
import 'package:samsara/ui/constants.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({super.key, required this.historyData});

  final Iterable<dynamic> historyData;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    for (final index in historyData) {
      final incident =
          engine.invoke('getIncidentByIndex', positionalArgs: [index]);
      widgets.add(Text(incident['content']));
    }

    return Container(
      padding: const EdgeInsets.all(10),
      height: MediaQuery.of(context).size.height - kTabBarHeight,
      child: SingleChildScrollView(
        child: ListView(
          shrinkWrap: true,
          children: widgets,
        ),
      ),
    );
  }
}
