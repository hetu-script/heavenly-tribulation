import 'package:flutter/material.dart';

import '../../../../ui/shared/close_button.dart';
import '../../../../global.dart';
import 'equipments.dart';
import 'inventory.dart';
import '../../../shared/responsive_route.dart';

class BuildView extends StatefulWidget {
  const BuildView({
    super.key,
    this.characterId,
    this.tabIndex = 0,
  });

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
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.inventory),
          ),
          Text(engine.locale['talisman']),
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
            child: Icon(Icons.library_books),
          ),
          Text(engine.locale['skills']),
        ],
      ),
    ),
  ];

  // late TabController _tabController;

  // String _title = engine.locale['items'];

  @override
  void initState() {
    super.initState();
    // _tabController = TabController(vsync: this, length: _tabs.length);
    // _tabController.addListener(() {
    //   setState(() {
    //     if (_tabController.index == 0) {
    //       _title = engine.locale['items'];
    //     } else if (_tabController.index == 1) {
    //       _title = engine.locale['skills'];
    //     }
    //   });
    // });
    // _tabController.index = widget.tabIndex;
  }

  @override
  void dispose() {
    // _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final charId = widget.characterId ??
        ModalRoute.of(context)!.settings.arguments as String;

    final data = engine.invoke('getCharacterById', positionalArgs: [charId]);

    return ResponsiveRoute(
      alignment: AlignmentDirectional.topEnd,
      size: const Size(400.0, 400.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(data['name']),
          actions: const [ButtonClose()],
          bottom: PreferredSize(
            preferredSize: const Size(450.0, 120.0),
            child: EquipmentsView(
              data: data['equipments'],
            ),
          ),
        ),
        body: DefaultTabController(
          length: _tabs.length,
          child: Column(
            children: [
              TabBar(
                // controller: _tabController,
                tabs: _tabs,
              ),
              Expanded(
                child: TabBarView(
                  // controller: _tabController,
                  children: [
                    InventoryView(
                      data: data['talismans'],
                    ),
                    InventoryView(
                      data: data['talismans'],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
