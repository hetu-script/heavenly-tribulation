import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:provider/provider.dart';

import '../../engine.dart';
import '../../ui.dart';
import '../common.dart';
import 'edit_sect_basic.dart';
import '../../data/game.dart';
import '../entity_table.dart';
import '../character/profile.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';
import '../../state/view_panels.dart';

class SectView extends StatefulWidget {
  final String? sectId;
  final HTStruct? sect;
  final InformationViewMode mode;

  const SectView({
    super.key,
    this.sectId,
    this.sect,
    this.mode = InformationViewMode.view,
  });

  @override
  State<SectView> createState() => _SectViewState();
}

class _SectViewState extends State<SectView> {
  static late List<Tab> tabs;
  late final HTStruct _sect;

  final List<List<String>> _charactersTable = [], _locationsTable = [];

  late final dynamic _headquartersLocation, _head;

  late final Iterable<dynamic> members;

  @override
  void initState() {
    super.initState();

    assert(widget.sectId != null || widget.sect != null,
        'SectView must have either sectId or sect data.');
    if (widget.sect != null) {
      _sect = widget.sect!;
    } else if (widget.sectId != null) {
      _sect = GameData.getSect(widget.sectId);
    }

    final headquartersLocationId = _sect['headquartersLocationId'];
    _headquartersLocation = GameData.getLocation(headquartersLocationId);

    final headId = _sect['headId'];
    _head = GameData.getCharacter(headId);

    members = (_sect['membersData'].values as Iterable)
        .where((memberData) => memberData['isAbsent'] == false)
        .map((memberData) => GameData.getCharacter(memberData['id']));

    for (final character in members) {
      final row = GameData.getMemberInformationRow(character);
      _charactersTable.add(row);
    }

    final Iterable locations = (_sect['locationIds'] as Iterable)
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

  void _saveData() {}

  void close() {
    if (widget.mode == InformationViewMode.edit) {
      Navigator.of(context).pop();
    } else {
      engine.context.read<ViewPanelState>().toogle(ViewPanels.sectInformation);
    }
  }

  @override
  Widget build(BuildContext context) {
    // final headTitle = _sectData['rankTitles'][6];

    final mainPanel = Container(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${engine.locale('head')}: ${_head['name']}',
            style: TextStyles.bodyLarge,
          ),
          Text(
            '${engine.locale('headquarters')}: ${_headquartersLocation['name']}',
            style: TextStyles.bodyLarge,
          ),
          Text(
            '${engine.locale('genre')}: ${engine.locale(_sect['genre'])}',
            style: TextStyles.bodyLarge,
          ),
          Text(
            '${engine.locale('ideology')}: ${engine.locale(_sect['category'])}',
            style: TextStyles.bodyLarge,
          ),
          Text(
            '${engine.locale('cityNumber')}: ${_sect['locationIds'].length}',
            style: TextStyles.bodyLarge,
          ),
          Text(
            '${engine.locale('memberNumber')}: ${members.length}',
            style: TextStyles.bodyLarge,
          ),
          Text(
            '${engine.locale('recruitMonth')}: ${_sect['recruitMonth']}${engine.locale('dateMonth')}',
            style: TextStyles.bodyLarge,
          ),
          const Spacer(),
          if (widget.mode == InformationViewMode.edit)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: Row(
                children: [
                  fluent.Button(
                    onPressed: () async {
                      final value = await showDialog(
                        context: context,
                        builder: (context) => EditSectBasics(
                          id: _sect['id'],
                          name: _sect['name'],
                          category: _sect['category'],
                          genre: _sect['genre'],
                          headId: _sect['headId'],
                          headquartersData: GameData.getLocation(
                              _sect['headquartersLocationId']),
                        ),
                      );
                      if (value == null) return;

                      final (id, name, category, genre, headId) = value;
                      _sect['name'] = name;
                      _sect['category'] = category;
                      _sect['genre'] = genre;

                      if (headId != null && headId != _sect['headId']) {
                        _sect['headId'] = headId;
                      }

                      if (id != null && id != _sect['id']) {
                        GameData.game['sects'].remove(_sect['id']);
                        _sect['id'] = id;
                        GameData.game['sects'][id] = _sect;
                      }
                    },
                    child: Text(engine.locale('editIdAndImage')),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                    child: fluent.Button(
                      onPressed: () {
                        if (widget.mode == InformationViewMode.edit) {
                          _saveData();
                        }
                        Navigator.of(context).pop(true);
                      },
                      child: Text(engine.locale('confirm')),
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );

    return ResponsiveView(
      width: 1000.0,
      height: widget.mode != InformationViewMode.view ? 650.0 : 600.0,
      onBarrierDismissed: close,
      child: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(_sect['name']),
            actions: [
              CloseButton2(onPressed: close),
            ],
            bottom: TabBar(tabs: tabs),
          ),
          body: TabBarView(
            children: [
              mainPanel,
              EntityTable(
                columns: kEntityTableMemberColumns,
                tableData: _charactersTable,
                onItemPressed: (position, dataId) {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        CharacterProfileView(characterId: dataId),
                  );
                },
              ),
              EntityTable(
                columns: kEntityTableLocationColumns,
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
