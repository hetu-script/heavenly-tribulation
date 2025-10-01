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
import '../game/logic/logic.dart';
import 'ui/close_button2.dart';
import 'common.dart';

enum EntityListViewMode {
  all,
  character,
  location,
  organization,
  selectCharacter,
  selectLocation,
  selectOrganization,
}

enum EntityListViewCharacterPopUpMenuItems {
  selectCharacter,
  checkProfile,
  checkStatsAndEquipments,
  checkMemory,
}

enum EntityListViewLocationPopUpMenuItems {
  selectLocation,
  checkInformation,
}

enum EntityListViewOrganizationPopUpMenuItems {
  selectOrganization,
  checkInformation,
}

class EntityListView extends StatefulWidget {
  const EntityListView({
    super.key,
    this.showCloseButton = true,
    this.mode = EntityListViewMode.all,
    this.characterIds,
    this.characters,
    this.locationIds,
    this.locations,
    this.organizationIds,
    this.organizations,
  });

  final bool showCloseButton;

  final EntityListViewMode mode;

  final Iterable? characterIds;
  final Iterable? characters;

  final Iterable? locationIds;
  final Iterable? locations;

  final Iterable? organizationIds;
  final Iterable? organizations;

  @override
  State<EntityListView> createState() => _EntityListViewState();
}

class _EntityListViewState extends State<EntityListView>
    with AutomaticKeepAliveClientMixin {
  static late List<Widget> tabs;

  @override
  bool get wantKeepAlive => true;

  late final Iterable _locations, _organizations, _characters;

  final List<List<String>> _locationsTable = [],
      _organizationsTable = [],
      _charactersTable = [];

  @override
  void initState() {
    super.initState();

    // TODO:只显示认识的人物和发现的据点

    if (widget.characters != null) {
      _characters = widget.characters!;
    } else {
      _characters = engine.hetu
          .invoke('getCharacters', positionalArgs: [widget.characterIds]);
    }
    for (final character in _characters) {
      final row = GameLogic.getCharacterInformationRow(character);
      _charactersTable.add(row);
    }

    if (widget.locations != null) {
      _locations = widget.locations!;
    } else {
      _locations = engine.hetu
          .invoke('getLocations', positionalArgs: [widget.locationIds]);
    }
    for (final location in _locations) {
      if (location['category'] != 'city') continue;
      final row = GameLogic.getLocationInformationRow(location);
      _locationsTable.add(row);
    }

    if (widget.organizations != null) {
      _organizations = widget.organizations!;
    } else {
      _organizations = engine.hetu
          .invoke('getOrganizations', positionalArgs: [widget.organizationIds]);
    }
    for (final organization in _organizations) {
      final row = GameLogic.getOrganizationInformationRow(organization);
      _organizationsTable.add(row);
    }

    tabs = [
      Tab(text: '${engine.locale('character')}(${_charactersTable.length})'),
      Tab(text: '${engine.locale('city')}(${_locationsTable.length})'),
      Tab(
          text:
              '${engine.locale('organization')}(${_organizationsTable.length})'),
    ];
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final characterListView = GameEntityListView(
      columns: kEntityListViewCharacterColumns,
      tableData: _charactersTable,
      onItemPressed: (position, dataId) {
        if (widget.mode == EntityListViewMode.selectCharacter) {
          Navigator.of(context).pop(dataId);
        } else {
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
        }
      },
      onItemSecondaryPressed: (position, dataId) {
        showFluentMenu(
          position: position,
          items: {
            if (widget.mode == EntityListViewMode.selectCharacter) ...{
              engine.locale('selectCharacter'):
                  EntityListViewCharacterPopUpMenuItems.selectCharacter,
              '___': null,
            },
            engine.locale('checkInformation'):
                EntityListViewCharacterPopUpMenuItems.checkProfile,
            engine.locale('checkStatsAndEquipments'):
                EntityListViewCharacterPopUpMenuItems.checkStatsAndEquipments,
            engine.locale('checkMemory'):
                EntityListViewCharacterPopUpMenuItems.checkMemory,
          },
          onSelectedItem: (EntityListViewCharacterPopUpMenuItems item) async {
            switch (item) {
              case EntityListViewCharacterPopUpMenuItems.selectCharacter:
                Navigator.of(context).pop(dataId);
              case EntityListViewCharacterPopUpMenuItems.checkProfile:
                final result = await showDialog(
                  context: context,
                  builder: (context) => CharacterProfileView(
                    characterId: dataId,
                    mode: InformationViewMode.select,
                    showIntimacy: true,
                    showPersonality: false,
                    showPosition: true,
                    showRelationships: true,
                  ),
                );
                if (result == dataId) {
                  Navigator.of(context).pop(dataId);
                }
              case EntityListViewCharacterPopUpMenuItems
                    .checkStatsAndEquipments:
                showDialog(
                  context: context,
                  builder: (context) =>
                      CharacterDetailsView(characterId: dataId),
                );
              case EntityListViewCharacterPopUpMenuItems.checkMemory:
                showDialog(
                  context: context,
                  builder: (context) =>
                      CharacterMemoryView(characterId: dataId),
                );
            }
          },
        );
      },
    );

    final locationListView = GameEntityListView(
      columns: kEntityListViewLocationColumns,
      tableData: _locationsTable,
      onItemPressed: (position, dataId) {
        if (widget.mode == EntityListViewMode.selectLocation) {
          Navigator.of(context).pop(dataId);
        } else {
          showDialog(
            context: context,
            builder: (context) => LocationView(locationId: dataId),
          );
        }
      },
      onItemSecondaryPressed: (position, dataId) {
        showFluentMenu(
          position: position,
          items: {
            if (widget.mode == EntityListViewMode.selectLocation) ...{
              engine.locale('selectLocation'):
                  EntityListViewLocationPopUpMenuItems.selectLocation,
              '___': null,
            },
            engine.locale('checkInformation'):
                EntityListViewLocationPopUpMenuItems.checkInformation,
          },
          onSelectedItem: (EntityListViewLocationPopUpMenuItems item) {
            switch (item) {
              case EntityListViewLocationPopUpMenuItems.selectLocation:
                Navigator.of(context).pop(dataId);
              case EntityListViewLocationPopUpMenuItems.checkInformation:
                showDialog(
                  context: context,
                  builder: (context) => LocationView(locationId: dataId),
                );
            }
          },
        );
      },
    );

    final organizationListView = GameEntityListView(
      columns: kEntityListViewOrganizationColumns,
      tableData: _organizationsTable,
      onItemPressed: (position, dataId) {
        if (widget.mode == EntityListViewMode.selectLocation) {
          Navigator.of(context).pop(dataId);
        } else {
          showDialog(
            context: context,
            builder: (context) => OrganizationView(organizationId: dataId),
          );
        }
      },
      onItemSecondaryPressed: (position, dataId) {
        showFluentMenu(
          position: position,
          items: {
            if (widget.mode == EntityListViewMode.selectOrganization) ...{
              engine.locale('selectOrganization'):
                  EntityListViewOrganizationPopUpMenuItems.selectOrganization,
              '___': null,
            },
            engine.locale('checkInformation'):
                EntityListViewOrganizationPopUpMenuItems.checkInformation,
          },
          onSelectedItem: (EntityListViewOrganizationPopUpMenuItems item) {
            switch (item) {
              case EntityListViewOrganizationPopUpMenuItems.selectOrganization:
                Navigator.of(context).pop(dataId);
              case EntityListViewOrganizationPopUpMenuItems.checkInformation:
                showDialog(
                  context: context,
                  builder: (context) =>
                      OrganizationView(organizationId: dataId),
                );
            }
          },
        );
      },
    );

    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.bottomCenter,
      child: widget.mode == EntityListViewMode.all
          ? DefaultTabController(
              length: tabs.length,
              child: Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(engine.locale('info')),
                  actions: [
                    if (widget.showCloseButton) CloseButton2(),
                  ],
                  bottom: TabBar(tabs: tabs),
                ),
                body: TabBarView(
                  children: [
                    characterListView,
                    locationListView,
                    organizationListView,
                  ],
                ),
              ),
            )
          : switch (widget.mode) {
              EntityListViewMode.character ||
              EntityListViewMode.selectCharacter =>
                characterListView,
              EntityListViewMode.location ||
              EntityListViewMode.selectLocation =>
                locationListView,
              EntityListViewMode.organization ||
              EntityListViewMode.selectOrganization =>
                organizationListView,
              _ => const SizedBox.shrink(),
            },
    );
  }
}
