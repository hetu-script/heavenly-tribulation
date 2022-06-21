import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/ui/view/character/memory.dart';

import '../../../global.dart';
import 'bonds.dart';
import '../../shared/responsive_route.dart';
import '../../shared/close_button.dart';
import 'attributes.dart';

class CharacterView extends StatefulWidget {
  const CharacterView({
    super.key,
    this.characterId,
    this.tabIndex = 0,
  });

  final String? characterId;

  final int tabIndex;

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

  String _title = engine.locale['information'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: _tabs.length);
    _tabController.addListener(() {
      setState(() {
        if (_tabController.index == 0) {
          _title = engine.locale['information'];
        } else if (_tabController.index == 1) {
          _title = engine.locale['bonds'];
        } else if (_tabController.index == 1) {
          _title = engine.locale['history'];
        }
      });
    });
    _tabController.index = widget.tabIndex;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charId = widget.characterId ??
        ModalRoute.of(context)!.settings.arguments as String;
    final data =
        engine.hetu.invoke('getCharacterById', positionalArgs: [charId]);

    final layout = DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('${data['name']} - $_title'),
          actions: const [ButtonClose()],
          bottom: TabBar(
            tabs: _tabs,
          ),
        ),
        body: TabBarView(
          children: [
            CharacterAttributesView(data: data),
            CharacterBondsView(data: data['bonds']),
            CharacterMemory(data: data['memory']),
          ],
        ),
      ),
    );

    return ResponsiveRoute(
      alignment: AlignmentDirectional.topCenter,
      size: const Size(400.0, 400.0),
      child: layout,
    );
  }
}
