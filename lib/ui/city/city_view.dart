import 'package:flutter/material.dart';
import '../../engine/game.dart';

class CityView extends StatefulWidget {
  final SamsaraGame game;

  const CityView({required this.game, Key? key}) : super(key: key);

  @override
  _CityViewState createState() => _CityViewState();
}

class _CityViewState extends State<CityView>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  SamsaraGame get game => widget.game;

  //int _currentTab = 0;

  static const _tabs = <Tab>[
    Tab(text: '动态'),
    Tab(text: '场地'),
    Tab(text: '人物'),
  ];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: _tabs.length);

    _pages = <Widget>[
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                primary: Colors.white,
                backgroundColor: Colors.lightBlue,
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text(
                'Roguelike Game Test',
              ),
              onPressed: () {
                widget.game.createScene('RogueGame');
                // GameDialog.show(context, [
                //   const Saying('Hello, world!'),
                //   const Saying('Alef out...'),
                // ]);
              },
            ),
          ],
        ),
      ),
      const Align(
        alignment: Alignment.center,
        child: Text('场景'),
      ),
      const Align(
        alignment: Alignment.center,
        child: Text('人物'),
      ),
    ];
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  late final List<Widget> _pages;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _pages,
      ),
    );
  }
}
