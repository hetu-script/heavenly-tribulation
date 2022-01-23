import 'package:flutter/material.dart';
import '../../engine/engine.dart';

const _kTabBarHeight = 72.0;

class HistoryView extends StatelessWidget {
  const HistoryView({Key? key, required this.data}) : super(key: key);

  final List<dynamic> data;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    for (final index in data) {
      final incident =
          engine.hetu.invoke('getIncidentByIndex', positionalArgs: [index]);
      widgets.add(Text(incident['content']));
    }

    return Container(
      padding: const EdgeInsets.all(10),
      height: MediaQuery.of(context).size.height - _kTabBarHeight,
      child: SingleChildScrollView(
        child: ListView(
          shrinkWrap: true,
          children: widgets,
        ),
      ),
    );
  }
}
