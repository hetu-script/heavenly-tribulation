import 'package:flutter/material.dart';

import '../../../../ui/shared/close_button.dart';
import '../../../../global.dart';
import 'inventory.dart';
import 'skills.dart';
import 'item_info.dart';
import '../../../shared/responsive_route.dart';

class BuildView extends StatefulWidget {
  const BuildView({
    Key? key,
    this.characterId,
    this.tabIndex = 0,
  }) : super(key: key);

  final String? characterId;

  final int tabIndex;

  @override
  State<BuildView> createState() => _BuildViewState();
}

class _BuildViewState extends State<BuildView>
    with SingleTickerProviderStateMixin {
  static final List<Tab> _tabs = <Tab>[
    Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.inventory),
          ),
          Text(engine.locale['items']),
        ],
      ),
    ),
    Tab(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.library_books),
          ),
          Text(engine.locale['skills']),
        ],
      ),
    ),
  ];

  late TabController _tabController;

  String _title = engine.locale['items'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(vsync: this, length: _tabs.length);
    _tabController.addListener(() {
      setState(() {
        if (_tabController.index == 0) {
          _title = engine.locale['items'];
        } else if (_tabController.index == 1) {
          _title = engine.locale['skills'];
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

    final data = engine.hetu.interpreter
        .invoke('getCharacterById', positionalArgs: [charId]);

    final layout = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text('${data['name']} - $_title'),
        actions: const [ButtonClose()],
        bottom: TabBar(
          controller: _tabController,
          tabs: _tabs,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: <Widget>[
          InventoryView(
            data: data['items'],
            onSelect: (item, screenPosition) {
              setState(() {
                showDialog(
                    context: context,
                    barrierColor: Colors.transparent,
                    builder: (context) {
                      return ItemInfo(
                        data: item,
                        left: screenPosition.dx,
                        top: screenPosition.dy - 100.0,
                      );
                    });
              });
            },
          ),
          SkillsView(
            data: data['skills'],
            onSelect: (item, screenPosition) {
              setState(() {});
            },
          ),
        ],
      ),
    );

    return ResponsiveRoute(
      child: layout,
      alignment: AlignmentDirectional.topEnd,
      size: const Size(400.0, 400.0),
    );
  }
}
