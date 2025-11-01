import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/empty_placeholder.dart';

import '../../global.dart';
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

  static List<Tab> tabs = <Tab>[
    Tab(text: engine.locale('experienced')),
    Tab(text: engine.locale('known')),
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: tabs.length,
      child: Column(
        children: [
          PreferredSize(
            preferredSize: const Size.fromHeight(kNestedTabBarHeight),
            child: TabBar.secondary(tabs: tabs),
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
