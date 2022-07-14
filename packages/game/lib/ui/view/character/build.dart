import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../ui/shared/close_button.dart';
import '../../../global.dart';
import 'equipments.dart';
import 'inventory.dart';
import '../../shared/responsive_window.dart';

const _kBuildTabNames = [
  'inventory',
  'skill',
  'companion',
];

class BuildView extends StatefulWidget {
  const BuildView({
    super.key,
    required this.characterData,
    this.tabIndex = 0,
  });

  final HTStruct characterData;

  final int tabIndex;

  @override
  State<BuildView> createState() => _BuildViewState();
}

class _BuildViewState extends State<BuildView> {
  // with SingleTickerProviderStateMixin {
  static final List<Tab> _tabs = _kBuildTabNames
      .map(
        (title) => Tab(
          iconMargin: const EdgeInsets.all(5.0),
          height: 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Icon(Icons.inventory),
              ),
              Text(engine.locale[title]),
            ],
          ),
        ),
      )
      .toList();

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
    // final charId = widget.characterId ??
    //     ModalRoute.of(context)!.settings.arguments as String;

    // final characterData =
    //     engine.invoke('getCharacterById', positionalArgs: [charId]);

    return ResponsiveWindow(
      size: const Size(720.0, 420.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.characterData['name']),
          actions: const [ButtonClose()],
        ),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            SizedBox(
              width: 300.0,
              height: 390.0,
              child: EquipmentsView(
                characterData: widget.characterData,
              ),
            ),
            const VerticalDivider(),
            SizedBox(
              width: 350.0,
              height: 390.0,
              child: DefaultTabController(
                length: _tabs.length, // 物品栏通过tabs过滤不同种类的物品
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
                            inventoryData: widget.characterData['inventory'],
                          ),
                          InventoryView(
                            inventoryData: widget.characterData['skills'],
                          ),
                          InventoryView(
                            inventoryData: widget.characterData['companions'],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
