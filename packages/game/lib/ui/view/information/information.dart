import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart' show HTStruct;

import '../../../engine/engine.dart';
import 'game_entity_listview.dart';

const _kInformationTabs = 4;

const _kNationTableColumns = [
  'name',
  'capital',
  'gridSize',
  'cityNumber',
];

const _kLocationTableColumns = [
  'name',
];

const _kOrganizationTableColumns = [
  'name',
];

const _kCharacterTableColumns = [
  'name',
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
      _nationsData.add(rowData);
    }

    final HTStruct locationsData = engine.hetu.invoke('getLocations');
    for (final loc in locationsData.values) {
      final rowData = <String>[];
      rowData.add(loc['name']);
      _locationsData.add(rowData);
    }

    final HTStruct organizationsData = engine.hetu.invoke('getOrganizations');
    for (final org in organizationsData.values) {
      final rowData = <String>[];
      rowData.add(org['name']);
      _organizationsData.add(rowData);
    }

    final HTStruct charactersData = engine.hetu.invoke('getCharacters');
    for (final char in charactersData.values) {
      final rowData = <String>[];
      rowData.add(char['name']);
      _charactersData.add(rowData);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            const BorderRadius.only(bottomRight: Radius.circular(5.0)),
        border: Border.all(
          width: 2,
          color: Colors.lightBlue,
        ),
      ),
      child: DefaultTabController(
        length: _kInformationTabs,
        child: Scaffold(
          appBar: AppBar(
            bottom: TabBar(
              tabs: [
                Tab(
                  icon: const Icon(Icons.public),
                  text: engine.locale['nations'],
                ),
                Tab(
                  icon: const Icon(Icons.location_city),
                  text: engine.locale['location'],
                ),
                Tab(
                  icon: const Icon(Icons.groups),
                  text: engine.locale['organization'],
                ),
                Tab(
                  icon: const Icon(Icons.person),
                  text: engine.locale['character'],
                ),
              ],
            ),
            title: Text(engine.locale['info']),
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
      ),
    );
  }
}
