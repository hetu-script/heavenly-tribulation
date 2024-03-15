import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../config.dart';
import 'package:samsara/ui/constants.dart';
import 'package:samsara/ui/empty_placeholder.dart';
import '../../history.dart';

class CharacterMemory extends StatelessWidget {
  const CharacterMemory({
    super.key,
    required this.memoryData,
  });

  final HTStruct? memoryData;

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
          Text(engine.locale('experienced')),
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
          Text(engine.locale('known')),
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
            child: memoryData != null
                ? TabBarView(
                    children: [
                      HistoryView(historyData: memoryData!['experienced']),
                      HistoryView(historyData: memoryData!['known']),
                    ],
                  )
                : EmptyPlaceholder(engine.locale('empty')),
          ),
        ],
      ),
    );
  }
}
