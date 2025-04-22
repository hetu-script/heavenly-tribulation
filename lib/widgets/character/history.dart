import 'package:flutter/material.dart';
import 'package:samsara/ui/empty_placeholder.dart';

import '../../engine.dart';
import '../common.dart';
import '../history_list.dart';

class HistoryView extends StatelessWidget {
  const HistoryView({
    super.key,
    required this.character,
    this.isHero = false,
  });

  final dynamic character;
  final bool isHero;

  static final List<Tab> _tabs = <Tab>[
    Tab(text: engine.locale('experienced')),
    Tab(text: engine.locale('known')),
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
            child: character != null
                ? TabBarView(
                    children: [
                      HistoryList(historyData: character['experienced']),
                      HistoryList(historyData: character['known']),
                    ],
                  )
                : EmptyPlaceholder(engine.locale('empty')),
          ),
        ],
      ),
    );
  }
}
