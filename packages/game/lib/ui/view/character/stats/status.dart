import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/util.dart';

import '../../../../global.dart';
import 'stats.dart';
import '../../../shared/responsive_window.dart';
import '../../../shared/close_button.dart';
import 'status_effects.dart';

class StatusView extends StatefulWidget {
  const StatusView({
    super.key,
    required this.characterData,
    this.tabIndex = 0,
  });

  final HTStruct characterData;

  final int tabIndex;

  @override
  State<StatusView> createState() => _StatusViewState();
}

class _StatusViewState extends State<StatusView>
    with SingleTickerProviderStateMixin {
  static final List<Tab> _tabs = <Tab>[
    Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.summarize),
          ),
          Text(engine.locale['attributes']),
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
            child: Icon(Icons.sync_alt),
          ),
          Text(engine.locale['status']),
        ],
      ),
    ),
  ];

  late TabController _tabController;

  // String _title = engine.locale['information'];

  @override
  void initState() {
    super.initState();

    _tabController = TabController(vsync: this, length: _tabs.length);
    // _tabController.addListener(() {
    //   setState(() {
    //     if (_tabController.index == 0) {
    //       _title = engine.locale['information'];
    //     } else if (_tabController.index == 1) {
    //       _title = engine.locale['bonds'];
    //     } else if (_tabController.index == 1) {
    //       _title = engine.locale['history'];
    //     }
    //   });
    // });
    _tabController.index = widget.tabIndex;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWindow(
      alignment: AlignmentDirectional.topCenter,
      size: const Size(400.0, 400.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            widget.characterData['name'],
            style: TextStyle(
              color: HexColor.fromHex(widget.characterData['color']),
            ),
          ),
          actions: const [ButtonClose()],
          bottom: TabBar(
            controller: _tabController,
            tabs: _tabs,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  StatsView(characterData: widget.characterData),
                  Container(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
