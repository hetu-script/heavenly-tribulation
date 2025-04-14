import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';

import 'character/memory.dart';
import '../engine.dart';
import 'game_entity_listview.dart';
import '../util.dart';
import 'location/edit_location.dart';
import 'organization/organization.dart';
import 'ui/menu_builder.dart';
import 'character/profile.dart';
import 'character/details.dart';
import '../game/ui.dart';

enum WorldInformationCharacterPopUpMenuItems {
  checkProfile,
  checkStatsAndEquipments,
  checkMemory,
}

const _kInformationViewCharacterColumns = [
  'name',
  'currentLocation',
  'organization',
  'fame',
];

const _kInformationViewOrganizationColumns = [
  'name',
  'organizationHead',
  'genre',
  'headquarters',
  'locationNumber',
  'memberNumber',
];

const _kInformationViewLocationColumns = [
  'name',
  'organization',
  'category',
  'memberCount',
];

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

  late final dynamic _locationsData, _organizationsData, _charactersData;

  final List<List<String>> _locationsTableData = [],
      _organizationsTableData = [],
      _charactersTableData = [];

  @override
  void initState() {
    super.initState();

    // TODO:只显示认识的人物和发现的据点

    _charactersData = engine.hetu.fetch('characters', namespace: 'game');
    for (final char in _charactersData.values) {
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

    _locationsData = engine.hetu.fetch('locations', namespace: 'game');
    for (final loc in _locationsData.values) {
      if (loc['category'] != 'city') continue;
      final rowData = <String>[];
      rowData.add(loc['name']);
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

    _organizationsData = engine.hetu.fetch('organizations', namespace: 'game');
    for (final org in _organizationsData.values) {
      final rowData = <String>[];
      rowData.add(org['name']);
      // 掌门
      rowData.add(org['headId']);
      // 类型
      rowData.add(engine.locale(org['genre']));
      // 总堂
      final headquarters = _locationsData[org['headquartersId']];
      rowData.add(headquarters['name']);
      // 据点数量
      rowData.add(org['locationIds'].length.toString());
      // 成员数量
      rowData.add(org['members'].length.toString());
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(org['id']);
      _organizationsTableData.add(rowData);
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
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColorOpaque,
      alignment: AlignmentDirectional.bottomCenter,
      child: DefaultTabController(
        length: _tabs.length,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(engine.locale('info')),
            actions: const [CloseButton2()],
            bottom: TabBar(tabs: _tabs),
          ),
          body: TabBarView(
            children: [
              GameEntityListView(
                columns: _kInformationViewCharacterColumns,
                tableData: _charactersTableData,
                onItemPressed: (position, dataId) {
                  showDialog(
                    context: context,
                    builder: (context) => CharacterProfileView(
                      characterId: dataId,
                      height: 600,
                      showIntimacy: true,
                      showPosition: true,
                      showPersonality: true,
                      showRelationships: true,
                    ),
                  );
                },
                onItemSecondaryPressed: (position, dataId) {
                  showFluentMenu(
                    position: position,
                    items: {
                      engine.locale('checkInformation'):
                          WorldInformationCharacterPopUpMenuItems.checkProfile,
                      engine.locale('checkStatsAndEquipments'):
                          WorldInformationCharacterPopUpMenuItems
                              .checkStatsAndEquipments,
                      engine.locale('checkMemory'):
                          WorldInformationCharacterPopUpMenuItems.checkMemory,
                    },
                    onSelectedItem: (item) {
                      switch (item) {
                        case WorldInformationCharacterPopUpMenuItems
                              .checkProfile:
                          showDialog(
                            context: context,
                            builder: (context) => ResponsiveView(
                              alignment: AlignmentDirectional.center,
                              width: GameUI.profileWindowSize.x,
                              height: 400.0,
                              child: CharacterProfile(characterId: dataId),
                            ),
                          );
                        case WorldInformationCharacterPopUpMenuItems
                              .checkStatsAndEquipments:
                          showDialog(
                            context: context,
                            builder: (context) =>
                                CharacterDetails(characterId: dataId),
                          );
                        case WorldInformationCharacterPopUpMenuItems
                              .checkMemory:
                          showDialog(
                            context: context,
                            builder: (context) =>
                                CharacterMemory(characterId: dataId),
                          );
                      }
                    },
                  );
                },
              ),
              GameEntityListView(
                columns: _kInformationViewOrganizationColumns,
                tableData: _organizationsTableData,
                onItemPressed: (position, dataId) {
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
                onItemPressed: (position, dataId) {
                  showDialog(
                    context: context,
                    builder: (context) => EditLocation(locationId: dataId),
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
