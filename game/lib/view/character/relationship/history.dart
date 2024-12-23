import 'package:flutter/material.dart';
import 'package:samsara/ui/empty_placeholder.dart';

import '../../../config.dart';
import '../../history.dart';
import '../../common.dart';

class CharacterHistoryView extends StatelessWidget {
  const CharacterHistoryView({
    super.key,
    required this.characterData,
  });

  final dynamic characterData;

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
                      HistoryView(historyData: characterData!['experienced']),
                      HistoryView(historyData: characterData!['known']),
                    ],
                  )
                : EmptyPlaceholder(engine.locale('empty')),
          ),
        ],
      ),
    );
  }
}
