import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/ui/responsive_view.dart';

import '../../engine.dart';
import '../../ui.dart';
// import '../../util.dart';
import '../common.dart';
import 'edit_organization_basic.dart';
import '../../game/game.dart';
import '../game_entity_listview.dart';
import '../character/profile.dart';
import '../ui/close_button2.dart';

class OrganizationView extends StatefulWidget {
  final String? organizationId;
  final HTStruct? organization;
  final InformationViewMode mode;

  const OrganizationView({
    super.key,
    this.organizationId,
    this.organization,
    this.mode = InformationViewMode.view,
  });

  @override
  State<OrganizationView> createState() => _OrganizationViewState();
}

class _OrganizationViewState extends State<OrganizationView> {
  static late List<Tab> tabs;
  late final HTStruct _organization;

  final List<List<String>> _charactersTable = [], _locationsTable = [];

  late final dynamic _headquartersLocation, _head;

  @override
  void initState() {
    super.initState();

    assert(widget.organizationId != null || widget.organization != null,
        'OrganizationView must have either organizationId or organization data.');
    if (widget.organization != null) {
      _organization = widget.organization!;
    } else if (widget.organizationId != null) {
      _organization = GameData.getOrganization(widget.organizationId);
    }

    final headquartersLocationId = _organization['headquartersLocationId'];
    _headquartersLocation = GameData.getLocation(headquartersLocationId);

    final headId = _organization['headId'];
    _head = GameData.getCharacter(headId);

    final Iterable members = (_organization['membersData'].values as Iterable)
        .map((member) => member['id'])
        .map((id) => GameData.getCharacter(id));

    for (final character in members) {
      final row = GameData.getMemberInformationRow(character);
      _charactersTable.add(row);
    }

    final Iterable locations = (_organization['locationIds'] as Iterable)
        .map((id) => GameData.getLocation(id));

    for (final location in locations) {
      if (location['category'] != 'city') continue;
      final row = GameData.getCityInformationRow(location);
      _locationsTable.add(row);
    }

    tabs = [
      Tab(text: engine.locale('information')),
      Tab(text: '${engine.locale('character')}(${_charactersTable.length})'),
      Tab(text: '${engine.locale('city')}(${_locationsTable.length})'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // final headTitle = _organizationData['rankTitles'][6];

    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 800.0,
      height: widget.mode != InformationViewMode.view ? 650.0 : 600.0,
      child: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(_organization['name']),
            actions: const [CloseButton2()],
            bottom: TabBar(
              tabs: tabs,
            ),
          ),
          body: TabBarView(
            children: [
              Container(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${engine.locale('head')}: ${_head['name']}'),
                    Text(
                        '${engine.locale('headquarters')}: ${_headquartersLocation['name']}'),
                    Text(
                        '${engine.locale('genre')}: ${engine.locale(_organization['genre'])}'),
                    Text(
                        '${engine.locale('ideology')}: ${engine.locale(_organization['category'])}'),
                    Text(
                        '${engine.locale('locationNumber')}: ${_organization['locationIds'].length}'),
                    Text(
                        '${engine.locale('memberNumber')}: ${_organization['membersData'].length}'),
                    Text(
                        '${engine.locale('recruitMonth')}: ${_organization['recruitMonth']}${engine.locale('dateMonth')}'),
                    const Spacer(),
                    if (widget.mode == InformationViewMode.edit)
                      Padding(
                        padding: const EdgeInsets.only(top: 10.0),
                        child: Row(
                          children: [
                            fluent.FilledButton(
                              onPressed: () async {
                                final value = await showDialog(
                                  context: context,
                                  builder: (context) => EditOrganizationBasics(
                                    id: _organization['id'],
                                    name: _organization['name'],
                                    category: _organization['category'],
                                    genre: _organization['genre'],
                                    headId: _organization['headId'],
                                    headquartersData: GameData.getLocation(
                                        _organization[
                                            'headquartersLocationId']),
                                  ),
                                );
                                if (value == null) return;

                                final (id, name, category, genre, headId) =
                                    value;
                                _organization['name'] = name;
                                _organization['category'] = category;
                                _organization['genre'] = genre;

                                if (headId != null &&
                                    headId != _organization['headId']) {
                                  _organization['headId'] = headId;
                                }

                                if (id != null && id != _organization['id']) {
                                  GameData.data['organizations']
                                      .remove(_organization['id']);
                                  _organization['id'] = id;
                                  GameData.data['organizations'][id] =
                                      _organization;
                                }
                              },
                              child: Text(engine.locale('editIdAndImage')),
                            ),
                          ],
                        ),
                      )
                  ],
                ),
              ),
              GameEntityListView(
                columns: kEntityListViewMemberColumns,
                tableData: _charactersTable,
                onItemPressed: (position, dataId) {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        CharacterProfileView(characterId: dataId),
                  );
                },
              ),
              GameEntityListView(
                columns: kEntityListViewLocationColumns,
                tableData: _locationsTable,
                onItemPressed: (position, dataId) {},
              ),
            ],
          ),
        ),
      ),
    );
  }
}
