import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';

import '../../config.dart';
import 'equipments/stats.dart';
import 'equipments/build.dart';
// import 'status_effects.dart';
import 'equipments/inventory.dart';

const Set<String> kMaterials = {
  // 'money',
  // 'spiritStone',
  'food',
  'drinkWater',
  'stone',
  'ore',
  'plank',
  'paper',
  'herb',
  'yinqi',
  'shaqi',
  'yuanqi',
};

class EquipmentsView extends StatefulWidget {
  const EquipmentsView({
    super.key,
    this.characterId,
    this.characterData,
    this.tabIndex = 0,
    this.type = InventoryType.player,
  });

  final String? characterId;

  final dynamic characterData;

  final int tabIndex;

  final InventoryType type;

  @override
  State<EquipmentsView> createState() => _EquipmentsViewState();
}

class _EquipmentsViewState extends State<EquipmentsView>
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
          Text(engine.locale('build')),
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
            child: Icon(Icons.summarize),
          ),
          Text(engine.locale('stats')),
        ],
      ),
    ),
  ];

  late TabController _tabController;

  late final dynamic _characterData;

  @override
  void initState() {
    super.initState();

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

    if (widget.characterData != null) {
      _characterData = widget.characterData!;
    } else {
      final charId = widget.characterId ??
          ModalRoute.of(context)!.settings.arguments as String;
      _characterData =
          engine.hetu.invoke('getCharacterById', positionalArgs: [charId]);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget? _buildMaterial(String name, dynamic data, {bool ignoreZero = false}) {
    final value = data[name];
    if (value > 0 || ignoreZero) {
      return Container(
          width: 100.0,
          padding: const EdgeInsets.only(right: 5.0),
          child: Row(
            children: [
              Text('${engine.locale(name)}:'),
              Expanded(
                child: Text(
                  '$value',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ));
    }
    return null;
  }

  List<Widget> _buildMaterials() {
    final data = _characterData['materials'];
    final List<Widget> materials = [];
    materials.add(_buildMaterial('money', data, ignoreZero: true)!);
    materials.add(_buildMaterial('spiritStone', data, ignoreZero: true)!);
    for (final name in kMaterials) {
      final widget = _buildMaterial(name, data);
      if (widget != null) {
        materials.add(widget);
      }
    }
    return materials;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      size: const Size(640.0, 400.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            engine.locale('build'),
          ),
          actions: const [CloseButton2()],
        ),
        body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5.0),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 360,
                    height: 320,
                    child: Column(
                      children: [
                        BuildView(characterData: _characterData),
                        InventoryView(
                          height: 260,
                          inventoryData: _characterData['inventory'],
                          type: widget.type,
                          onEquipChanged: () => setState(() {}),
                          minSlotCount: 36,
                        ),
                      ],
                    ),
                  ),
                  StatsView(
                    characterData: _characterData,
                    useColumn: true,
                  ),
                ],
              ),
              Container(
                alignment: Alignment.topLeft,
                padding:
                    const EdgeInsets.only(top: 5.0, left: 10.0, right: 10.0),
                child: Wrap(
                  children: _buildMaterials(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
