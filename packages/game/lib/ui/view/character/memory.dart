import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import '../../shared/constants.dart';
import '../history.dart';

class CharacterMemory extends StatelessWidget {
  const CharacterMemory({
    super.key,
    required this.data,
  });

  final HTStruct data;

  static final List<Tab> _tabs = <Tab>[
    Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.history),
          ),
          Text(engine.locale['experience']),
        ],
      ),
    ),
    Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.visibility),
          ),
          Text(engine.locale['witness']),
        ],
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: _tabs.length,
      child: Column(
        children: [
          PreferredSize(
            preferredSize: const Size.fromHeight(kNestedTabBarHeight),
            child: TabBar(
              tabs: _tabs,
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                HistoryView(data: data['experienced']),
                HistoryView(data: data['witnessed']),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
