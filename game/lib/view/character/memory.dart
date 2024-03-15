import 'package:flutter/material.dart';

import '../../config.dart';
import 'relationship/bonds.dart';
import 'relationship/memory.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';

class MemoryView extends StatefulWidget {
  const MemoryView({
    super.key,
    this.characterId,
    this.characterData,
    this.tabIndex = 0,
    this.showConfirmButton = false,
  });

  final String? characterId;

  final dynamic characterData;

  final int tabIndex;

  final bool showConfirmButton;

  @override
  State<MemoryView> createState() => _MemoryViewState();
}

class _MemoryViewState extends State<MemoryView>
    with SingleTickerProviderStateMixin {
  static final List<Tab> _tabs = <Tab>[
    Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.sync_alt),
          ),
          Text(engine.locale('bonds')),
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
            child: Icon(Icons.history),
          ),
          Text(engine.locale('history')),
        ],
      ),
    ),
  ];

  late TabController _tabController;

  // String _title = engine.locale('information'];

  late final dynamic _characterData;

  @override
  void initState() {
    super.initState();

    if (widget.characterData != null) {
      _characterData = widget.characterData!;
    } else {
      final charId = widget.characterId ??
          ModalRoute.of(context)!.settings.arguments as String;
      _characterData =
          engine.hetu.invoke('getCharacterById', positionalArgs: [charId]);
    }

    _tabController = TabController(vsync: this, length: _tabs.length);
    // _tabController.addListener(() {
    //   setState(() {
    //     if (_tabController.index == 0) {
    //       _title = engine.locale('information'];
    //     } else if (_tabController.index == 1) {
    //       _title = engine.locale('bonds'];
    //     } else if (_tabController.index == 1) {
    //       _title = engine.locale('history'];
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
      alignment: AlignmentDirectional.center,
      size: Size(400.0, widget.showConfirmButton ? 460.0 : 420.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            engine.locale('information'),
          ),
          actions: const [CloseButton2()],
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
                  CharacterBondsView(bondsData: _characterData['bonds']),
                  CharacterMemory(memoryData: _characterData['memory']),
                ],
              ),
            ),
            if (widget.showConfirmButton)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(_characterData['id']);
                  },
                  child: Text(engine.locale('confirm')),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
