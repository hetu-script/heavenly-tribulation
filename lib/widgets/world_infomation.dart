import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';

import 'character/memory.dart';
import '../engine.dart';
import 'game_entity_listview.dart';
import '../util.dart';
import 'location/location.dart';
import 'organization/organization.dart';
import 'ui/menu_builder.dart';
import 'character/profile.dart';
import 'character/details.dart';
import '../game/ui.dart';

enum WorldInformationCharacterPopUpMenuItems {
  checkProfile,
  checkStats,
  checkMemory,
}

List<PopupMenuEntry<WorldInformationCharacterPopUpMenuItems>>
    buildWorldInformationCharacterPopUpMenuItems(
        {void Function(WorldInformationCharacterPopUpMenuItems item)?
            onSelectedItem}) {
  return <PopupMenuEntry<WorldInformationCharacterPopUpMenuItems>>[
    buildMenuItem(
      item: WorldInformationCharacterPopUpMenuItems.checkProfile,
      name: engine.locale('checkInformation'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: WorldInformationCharacterPopUpMenuItems.checkStats,
      name: engine.locale('checkStats'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: WorldInformationCharacterPopUpMenuItems.checkMemory,
      name: engine.locale('checkMemory'),
      onSelectedItem: onSelectedItem,
    ),
  ];
}

const _kInformationViewCharacterColumns = [
  'name',
  'currentLocation',
  'organization',
  'fame',
  // 'infamy',
];

const _kInformationViewOrganizationColumns = [
  'name',
  'head',
  'genre',
  'headquarters',
  'locationNumber',
  'memberNumber',
  'development',
];

const _kInformationViewLocationColumns = [
  'name',
  // 'nation',
  'organization',
  'category',
  'development',
];

// const _kInformationViewNationColumns = [
//   'name',
//   'capital',
//   'gridSize',
//   'locationNumber',
//   'organizationNumber',
// ];

class WorldInformationPanel extends StatefulWidget {
  const WorldInformationPanel({super.key});

  @override
  State<WorldInformationPanel> createState() => _WorldInformationPanelState();
}

class _WorldInformationPanelState extends State<WorldInformationPanel>
    with AutomaticKeepAliveClientMixin {
  static late List<Widget> _tabs;

  @override
  bool get wantKeepAlive => true;

  late final Iterable<dynamic> _locationsData,
      _organizationsData,
      _charactersData;

  final List<List<String>> _locationsTableData = [],
      _organizationsTableData = [],
      _charactersTableData = [];

  @override
  void initState() {
    super.initState();

    // TODO:只显示认识的人物和发现的据点

    // _nationsData = engine.hetu.invoke('getNations');
    // for (final nation in _nationsData.values) {
    //   final rowData = <String>[];
    //   // 国家名字
    //   rowData.add(nation['name']);
    //   // 首都名字
    //   rowData.add(getNameFromId(nation['capitalId']));
    //   // 地块大小
    //   rowData.add(nation['territoryIndexes'].length.toString());
    //   // 据点数量
    //   rowData.add(nation['locationIds'].length.toString());
    //   rowData.add(nation['organizationIds'].length.toString());
    //   // 多存一个隐藏的 id 信息，用于点击事件
    //   rowData.add(nation['id']);
    //   _nationsFieldRow.add(rowData);
    // }

    _locationsData = engine.hetu.fetch('locations', namespace: 'game').values;
    for (final loc in _locationsData) {
      if (loc['category'] != 'city') continue;
      final rowData = <String>[];
      rowData.add(loc['name']);
      // 国家名字
      // rowData.add(getNameFromId(loc['nationId']));
      // 门派名字
      rowData.add(getNameFromId(loc['organizationId'], 'none'));
      // 类型
      rowData.add(engine.locale(loc['kind']));
      // 发展度
      rowData.add(loc['development'].toString());
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(loc['id']);
      _locationsTableData.add(rowData);
    }

    _organizationsData = engine.hetu.invoke('getOrganizations');
    for (final org in _organizationsData) {
      final rowData = <String>[];
      rowData.add(org['name']);
      // 掌门
      rowData.add(getNameFromId(org['headId']));
      // 类型
      rowData.add(engine.locale(org['genre']));
      // 总堂
      rowData.add(getNameFromId(org['headquartersId']));
      // 据点数量
      rowData.add(org['locationIds'].length.toString());
      // 成员数量
      rowData.add(org['members'].length.toString());
      // 发展度
      rowData.add(org['development'].toString());
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(org['id']);
      _organizationsTableData.add(rowData);
    }

    _charactersData = engine.hetu.invoke('getCharacters');
    for (final char in _charactersData) {
      final rowData = <String>[];
      rowData.add(char['name']);
      // 当前所在地点
      rowData.add(getNameFromId(char['locationId']));
      // 门派名字
      rowData.add(getNameFromId(char['organizationId']));
      // 名声
      final fame =
          engine.hetu.invoke('getCharacterFameString', positionalArgs: [char]);
      rowData.add(fame);
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(char['id']);
      _charactersTableData.add(rowData);
    }

    _tabs = [
      Tab(
        icon: const Icon(Icons.person),
        text: '${engine.locale('character')}(${_charactersTableData.length})',
      ),
      Tab(
        icon: const Icon(Icons.groups),
        text:
            '${engine.locale('organization')}(${_organizationsTableData.length})',
      ),
      Tab(
        icon: const Icon(Icons.location_city),
        text: '${engine.locale('location')}(${_locationsTableData.length})',
      ),
      // Tab(
      //   icon: const Icon(Icons.public),
      //   text: '${engine.locale('nation')}(${_nationsFieldRow.length})',
      // ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ResponsiveView(
      alignment: AlignmentDirectional.bottomCenter,
      child: DefaultTabController(
        length: _tabs.length,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(engine.locale('info')),
            actions: const [CloseButton2()],
            bottom: TabBar(
              tabs: _tabs,
            ),
          ),
          body: TabBarView(
            children: [
              GameEntityListView(
                columns: _kInformationViewCharacterColumns,
                tableData: _charactersTableData,
                onItemPressed: (buttons, position, dataId) {
                  final menuPosition = RelativeRect.fromLTRB(
                      position.dx, position.dy, position.dx, 0.0);
                  final items = buildWorldInformationCharacterPopUpMenuItems(
                      onSelectedItem: (item) {
                    switch (item) {
                      case WorldInformationCharacterPopUpMenuItems.checkProfile:
                        showDialog(
                          context: context,
                          builder: (context) => ResponsiveView(
                            alignment: AlignmentDirectional.center,
                            width: GameUI.profileWindowSize.x,
                            height: 400.0,
                            child: CharacterProfile(characterId: dataId),
                          ),
                        );
                      case WorldInformationCharacterPopUpMenuItems.checkStats:
                        showDialog(
                          context: context,
                          builder: (context) =>
                              CharacterDetails(characterId: dataId),
                        );
                      case WorldInformationCharacterPopUpMenuItems.checkMemory:
                        showDialog(
                          context: context,
                          builder: (context) =>
                              CharacterMemory(characterId: dataId),
                        );
                    }
                  });
                  showMenu(
                    context: context,
                    position: menuPosition,
                    items: items,
                  );
                },
              ),
              GameEntityListView(
                columns: _kInformationViewOrganizationColumns,
                tableData: _organizationsTableData,
                onItemPressed: (buttons, position, dataId) {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        OrganizationView(organizationId: dataId),
                  );
                },
              ),
              GameEntityListView(
                columns: _kInformationViewLocationColumns,
                tableData: _locationsTableData,
                onItemPressed: (buttons, position, dataId) {
                  showDialog(
                    context: context,
                    builder: (context) => LocationView(locationId: dataId),
                  );
                },
              ),
              // GameEntityListView(
              //   columns: _kInformationViewNationColumns,
              //   tableData: _nationsFieldRow,
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
