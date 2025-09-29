import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';

import 'character/memory.dart';
import '../engine.dart';
import 'game_entity_listview.dart';
import 'location/location.dart';
import 'organization/organization.dart';
import 'ui/menu_builder.dart';
import 'character/profile.dart';
import 'character/details.dart';
import '../game/ui.dart';
import '../game/data.dart';
import '../game/common.dart';
import '../game/logic.dart';
import 'ui/close_button2.dart';

enum WorldInformationCharacterPopUpMenuItems {
  checkProfile,
  checkStatsAndEquipments,
  checkMemory,
}

class WorldInformationPanel extends StatefulWidget {
  const WorldInformationPanel({super.key});

  @override
  State<WorldInformationPanel> createState() => _WorldInformationPanelState();
}

class _WorldInformationPanelState extends State<WorldInformationPanel>
    with AutomaticKeepAliveClientMixin {
  static late List<Widget> tabs;

  @override
  bool get wantKeepAlive => true;

  late final dynamic _locationsData, _organizationsData, _characters;

  final List<List<String>> _locationsTableData = [],
      _organizationsTableData = [],
      _charactersTableData = [];

  @override
  void initState() {
    super.initState();

    // TODO:只显示认识的人物和发现的据点

    _characters = GameData.game['characters'];
    for (final character in _characters.values) {
      final row = GameLogic.getCharacterInformationRow(character);
      _charactersTableData.add(row);
    }

    _locationsData = GameData.game['locations'];
    for (final location in _locationsData.values) {
      if (location['category'] != 'city') continue;
      final row = GameLogic.getLocationInformationRow(location);
      _locationsTableData.add(row);
    }

    _organizationsData = GameData.game['organizations'];
    for (final organization in _organizationsData.values) {
      final row = GameLogic.getOrganizationInformationRow(organization);
      _organizationsTableData.add(row);
    }

    tabs = [
      Tab(
          text:
              '${engine.locale('character')}(${_charactersTableData.length})'),
      Tab(text: '${engine.locale('city')}(${_locationsTableData.length})'),
      Tab(
          text:
              '${engine.locale('organization')}(${_organizationsTableData.length})'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.bottomCenter,
      child: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(engine.locale('info')),
            actions: const [CloseButton2()],
            bottom: TabBar(tabs: tabs),
          ),
          body: TabBarView(
            children: [
              GameEntityListView(
                columns: kInformationViewCharacterColumns,
                tableData: _charactersTableData,
                onItemPressed: (position, dataId) {
                  showDialog(
                    context: context,
                    builder: (context) => CharacterProfileView(
                      characterId: dataId,
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
                            builder: (context) =>
                                CharacterProfileView(characterId: dataId),
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
                columns: kInformationViewLocationColumns,
                tableData: _locationsTableData,
                onItemPressed: (position, dataId) {
                  showDialog(
                    context: context,
                    builder: (context) => LocationView(locationId: dataId),
                  );
                },
              ),
              GameEntityListView(
                columns: kInformationViewOrganizationColumns,
                tableData: _organizationsTableData,
                onItemPressed: (position, dataId) {
                  showDialog(
                    context: context,
                    builder: (context) =>
                        OrganizationView(organizationId: dataId),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
