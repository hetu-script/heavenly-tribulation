import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/util.dart';

import '../../../../global.dart';
import 'bonds.dart';
import 'memory.dart';
import '../../../shared/responsive_window.dart';
import '../../../shared/close_button.dart';
import 'profile.dart';

class CharacterView extends StatefulWidget {
  const CharacterView({
    super.key,
    this.characterId,
    this.characterData,
    this.tabIndex = 0,
    this.showConfirmButton = false,
  });

  final String? characterId;

  final HTStruct? characterData;

  final int tabIndex;

  final bool showConfirmButton;

  @override
  State<CharacterView> createState() => _CharacterViewState();
}

class _CharacterViewState extends State<CharacterView>
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
          Text(engine.locale['information']),
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
          Text(engine.locale['bonds']),
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
          Text(engine.locale['history']),
        ],
      ),
    ),
  ];

  late TabController _tabController;

  // String _title = engine.locale['information'];

  late final HTStruct _characterData;

  @override
  void initState() {
    super.initState();

    if (widget.characterData != null) {
      _characterData = widget.characterData!;
    } else {
      final charId = widget.characterId ??
          ModalRoute.of(context)!.settings.arguments as String;
      _characterData =
          engine.invoke('getCharacterById', positionalArgs: [charId]);
    }

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
      size: Size(400.0, widget.showConfirmButton ? 460.0 : 420.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            _characterData['name'],
            style: TextStyle(
              color: HexColor.fromHex(_characterData['color']),
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
                  ProfileView(characterData: _characterData),
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
                  child: Text(engine.locale['confirm']),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
