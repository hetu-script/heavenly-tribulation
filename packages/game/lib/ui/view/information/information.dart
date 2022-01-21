import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart' show HTStruct;

import '../../../engine/engine.dart';
import 'game_entity_listview.dart';
import '../../../shared/extension.dart';

const _kInformationTabs = 4;

const _kNationTableColumns = [
  'name',
  'capital',
  'gridSize',
  'locationNumber',
  'organizationNumber',
];

const _kLocationTableColumns = [
  'name',
  'nation',
  'organization',
  'category',
  'development',
];

const _kOrganizationTableColumns = [
  'name',
  'leader',
  'headquartersLocation',
  'locationNumber',
  'memberNumber',
  'development',
];

const _kCharacterTableColumns = [
  'name',
  'residentLocation',
  'organization',
  'spiritRank',
  'fame',
  'evaluation',
];

class InformationPanel extends StatefulWidget {
  const InformationPanel({Key? key}) : super(key: key);

  @override
  _InformationPanelState createState() => _InformationPanelState();
}

class _InformationPanelState extends State<InformationPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  final List<List<String>> _nationsData = [],
      _locationsData = [],
      _organizationsData = [],
      _charactersData = [];

  @override
  void initState() {
    super.initState();

    updateData();
  }

  void updateData() {
    _nationsData.clear();
    _locationsData.clear();
    _organizationsData.clear();
    _charactersData.clear();

    final HTStruct nationsData = engine.hetu.invoke('getNations');
    for (final nation in nationsData.values) {
      final rowData = <String>[];
      // 国家名字
      rowData.add(nation['name']);
      // 首都名字
      final location = engine.hetu
          .invoke('getLocationById', positionalArgs: [nation['capitalId']]);
      rowData.add(location['name']);
      // 地块大小
      rowData.add(nation['territoryIndexes'].length.toString());
      // 据点数量
      rowData.add(nation['locationIds'].length.toString());
      rowData.add(nation['organizationIds'].length.toString());
      _nationsData.add(rowData);
    }

    final HTStruct locationsData = engine.hetu.invoke('getLocations');
    for (final loc in locationsData.values) {
      final rowData = <String>[];
      rowData.add(loc['name']);
      final nationId = loc['nationId'];
      if (nationId != null) {
        // 国家名字
        final nation =
            engine.hetu.invoke('getNationById', positionalArgs: [nationId]);
        rowData.add(nation['name']);
      } else {
        rowData.add(engine.locale['none']);
      }
      // 门派名字
      final orgId = loc['organizationId'];
      if (orgId != null) {
        final organization =
            engine.hetu.invoke('getOrganizationById', positionalArgs: [orgId]);
        rowData.add(organization['name']);
      } else {
        rowData.add(engine.locale['none']);
      }
      // 类型
      final category = loc['category'];
      switch (category) {
        case 'city':
          rowData.add(engine.locale['city']);
          break;
        case 'arcana':
          rowData.add(engine.locale['arcana']);
          break;
        case 'mirage':
          rowData.add(engine.locale['mirage']);
          break;
        default:
          rowData.add(engine.locale['unknown']);
      }
      // 发展度
      rowData.add(loc['development'].toString());
      _locationsData.add(rowData);
    }

    final HTStruct organizationsData = engine.hetu.invoke('getOrganizations');
    for (final org in organizationsData.values) {
      final rowData = <String>[];
      rowData.add(org['name']);
      // 掌门
      final leader = engine.hetu
          .invoke('getCharacterById', positionalArgs: [org['leaderId']]);
      rowData.add(leader['name']);
      // 总堂
      final headquarters = engine.hetu.invoke('getLocationById',
          positionalArgs: [org['headquartersLocationId']]);
      rowData.add(headquarters['name']);
      // 据点数量
      rowData.add(org['locationIds'].length.toString());
      // 成员数量
      rowData.add(org['characterIds'].length.toString());
      // 发展度
      rowData.add(org['development'].toString());
      _organizationsData.add(rowData);
    }

    final HTStruct charactersData = engine.hetu.invoke('getCharacters');
    for (final char in charactersData.values) {
      final rowData = <String>[];
      rowData.add(char['name']);
      // 住所
      final residentLocation = engine.hetu.invoke('getLocationById',
          positionalArgs: [char['residentLocationId']]);
      rowData.add(residentLocation['name']);
      // 门派名字
      final orgId = char['organizationId'];
      if (orgId != null) {
        final organization =
            engine.hetu.invoke('getOrganizationById', positionalArgs: [orgId]);
        rowData.add(organization['name']);
      } else {
        rowData.add(engine.locale['none']);
      }
      // 境界
      final spiritRank = char['spiritRank'];
      rowData.add(engine.locale['spiritRank$spiritRank']);
      // 名声
      rowData.add(char['fame'].toString());
      // 评价
      final int praised = char['praised'];
      final int reprimanded = char['reprimanded'];
      final percentage = praised + reprimanded > 0
          ? (praised / (praised + reprimanded)).toPercentageString(2)
          : '0%';
      rowData.add(percentage);

      _charactersData.add(rowData);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return DefaultTabController(
      length: _kInformationTabs,
      child: Scaffold(
        appBar: AppBar(
          title: Text(engine.locale['info']),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.public),
                text: '${engine.locale['nation']}(${_nationsData.length})',
              ),
              Tab(
                icon: const Icon(Icons.location_city),
                text: '${engine.locale['location']}(${_locationsData.length})',
              ),
              Tab(
                icon: const Icon(Icons.groups),
                text:
                    '${engine.locale['organization']}(${_organizationsData.length})',
              ),
              Tab(
                icon: const Icon(Icons.person),
                text:
                    '${engine.locale['character']}(${_charactersData.length})',
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            GameEntityListView(
              columns: _kNationTableColumns,
              data: _nationsData,
            ),
            GameEntityListView(
              columns: _kLocationTableColumns,
              data: _locationsData,
            ),
            GameEntityListView(
              columns: _kOrganizationTableColumns,
              data: _organizationsData,
            ),
            GameEntityListView(
              columns: _kCharacterTableColumns,
              data: _charactersData,
            )
          ],
        ),
      ),
    );
  }
}
