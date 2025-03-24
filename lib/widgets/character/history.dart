import 'package:flutter/material.dart';
import 'package:samsara/ui/empty_placeholder.dart';

import '../../engine.dart';
import '../common.dart';
import '../history_list.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({
    super.key,
    required this.characterData,
    this.isHero = false,
  });

  final dynamic characterData;
  final bool isHero;

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
            child: characterData != null
                ? TabBarView(
                    children: [
                      HistoryList(historyData: characterData['experienced']),
                      HistoryList(historyData: characterData['known']),
                    ],
                  )
                : EmptyPlaceholder(engine.locale('empty')),
          ),
        ],
      ),
    );
  }
}
