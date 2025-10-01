import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/ui/responsive_view.dart';

import '../../engine.dart';
import '../../game/ui.dart';
// import '../../util.dart';
import '../common.dart';
import 'edit_organization_basic.dart';
import '../../game/data.dart';
import '../../game/logic/logic.dart';
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

  late final dynamic _headquarters, _head;

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

    final headquartersId = _organization['headquartersId'];
    _headquarters = GameData.getLocation(headquartersId);

    final headId = _organization['headId'];
    _head = GameData.getCharacter(headId);

    final Iterable memberIds = (_organization['members'].values as Iterable)
        .map((member) => member['id']);
    final Iterable members =
        (GameData.game['characters'].values as Iterable).where(
      (char) => memberIds.contains(char['id']),
    );

    for (final character in members) {
      final row = GameLogic.getCharacterInformationRow(character);
      _charactersTable.add(row);
    }

    final List locationIds = _organization['locationIds'];
    final Iterable locations =
        (GameData.game['locations'].values as Iterable).where(
      (loc) => locationIds.contains(loc['id']),
    );

    for (final location in locations) {
      if (location['category'] != 'city') continue;
      final row = GameLogic.getLocationInformationRow(location);
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
                        '${engine.locale('headquarters')}: ${_headquarters['name']}'),
                    Text(
                        '${engine.locale('genre')}: ${engine.locale(_organization['genre'])}'),
                    Text(
                        '${engine.locale('ideology')}: ${engine.locale(_organization['category'])}'),
                    Text(
                        '${engine.locale('territorySize')}: ${_organization['territoryIndexes'].length}'),
                    Text(
                        '${engine.locale('recruitMonth')}: ${_organization['recruitMonth']}'),
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
                                        _organization['headquartersId']),
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
                                  GameData.game['organizations']
                                      .remove(_organization['id']);
                                  _organization['id'] = id;
                                  GameData.game['organizations'][id] =
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
                columns: kEntityListViewCharacterColumns,
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
