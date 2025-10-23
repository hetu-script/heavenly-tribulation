import 'package:flutter/material.dart';

import 'character/memory.dart';
import '../engine.dart';
import 'entity_table.dart';
import 'location/location.dart';
import 'organization/organization.dart';
import 'ui/menu_builder.dart';
import 'character/profile.dart';
import 'character/details.dart';
import '../data/game.dart';
import 'ui/close_button2.dart';
import 'common.dart';
import '../widgets/ui/responsive_view.dart';

enum InformationMode {
  all,
  character,
  location,
  organization,
  selectCharacter,
  selectLocation,
  selectOrganization,
}

enum _CharacterPopUpMenuItems {
  selectCharacter,
  checkProfile,
  checkStatsAndEquipments,
  checkMemory,
}

enum _LocationPopUpMenuItems {
  selectLocation,
  checkInformation,
}

enum _OrganizationPopUpMenuItems {
  selectOrganization,
  checkInformation,
}

class InformationView extends StatefulWidget {
  const InformationView({
    super.key,
    this.showCloseButton = true,
    this.mode = InformationMode.all,
    this.characterIds,
    this.characters,
    this.locationIds,
    this.locations,
    this.organizationIds,
    this.organizations,
  });

  final bool showCloseButton;

  final InformationMode mode;

  final Iterable? characterIds;
  final Iterable? characters;

  final Iterable? locationIds;
  final Iterable? locations;

  final Iterable? organizationIds;
  final Iterable? organizations;

  @override
  State<InformationView> createState() => _InformationViewState();
}

class _InformationViewState extends State<InformationView>
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
      final row = GameData.getCharacterInformationRow(character);
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
      final row = GameData.getCityInformationRow(location);
      _locationsTable.add(row);
    }

    if (widget.organizations != null) {
      _organizations = widget.organizations!;
    } else {
      _organizations = engine.hetu
          .invoke('getOrganizations', positionalArgs: [widget.organizationIds]);
    }
    for (final organization in _organizations) {
      final row = GameData.getOrganizationInformationRow(organization);
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

    final characterListView = EntityTable(
      columns: kEntityTableCharacterColumns,
      tableData: _charactersTable,
      onItemPressed: (position, dataId) {
        if (widget.mode == InformationMode.selectCharacter) {
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
            if (widget.mode == InformationMode.selectCharacter) ...{
              engine.locale('selectCharacter'):
                  _CharacterPopUpMenuItems.selectCharacter,
              '___': null,
            },
            engine.locale('checkInformation'):
                _CharacterPopUpMenuItems.checkProfile,
            engine.locale('checkStatsAndEquipments'):
                _CharacterPopUpMenuItems.checkStatsAndEquipments,
            engine.locale('checkMemory'): _CharacterPopUpMenuItems.checkMemory,
          },
          onSelectedItem: (_CharacterPopUpMenuItems item) async {
            switch (item) {
              case _CharacterPopUpMenuItems.selectCharacter:
                Navigator.of(context).pop(dataId);
              case _CharacterPopUpMenuItems.checkProfile:
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
              case _CharacterPopUpMenuItems.checkStatsAndEquipments:
                showDialog(
                  context: context,
                  builder: (context) =>
                      CharacterDetailsView(characterId: dataId),
                );
              case _CharacterPopUpMenuItems.checkMemory:
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

    final locationListView = EntityTable(
      columns: kEntityTableLocationColumns,
      tableData: _locationsTable,
      onItemPressed: (position, dataId) {
        if (widget.mode == InformationMode.selectLocation) {
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
            if (widget.mode == InformationMode.selectLocation) ...{
              engine.locale('selectLocation'):
                  _LocationPopUpMenuItems.selectLocation,
              '___': null,
            },
            engine.locale('checkInformation'):
                _LocationPopUpMenuItems.checkInformation,
          },
          onSelectedItem: (_LocationPopUpMenuItems item) {
            switch (item) {
              case _LocationPopUpMenuItems.selectLocation:
                Navigator.of(context).pop(dataId);
              case _LocationPopUpMenuItems.checkInformation:
                showDialog(
                  context: context,
                  builder: (context) => LocationView(locationId: dataId),
                );
            }
          },
        );
      },
    );

    final organizationListView = EntityTable(
      columns: kEntityTableOrganizationColumns,
      tableData: _organizationsTable,
      onItemPressed: (position, dataId) {
        if (widget.mode == InformationMode.selectLocation) {
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
            if (widget.mode == InformationMode.selectOrganization) ...{
              engine.locale('selectOrganization'):
                  _OrganizationPopUpMenuItems.selectOrganization,
              '___': null,
            },
            engine.locale('checkInformation'):
                _OrganizationPopUpMenuItems.checkInformation,
          },
          onSelectedItem: (_OrganizationPopUpMenuItems item) {
            switch (item) {
              case _OrganizationPopUpMenuItems.selectOrganization:
                Navigator.of(context).pop(dataId);
              case _OrganizationPopUpMenuItems.checkInformation:
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
      alignment: AlignmentDirectional.bottomCenter,
      child: widget.mode == InformationMode.all
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
              InformationMode.character ||
              InformationMode.selectCharacter =>
                characterListView,
              InformationMode.location ||
              InformationMode.selectLocation =>
                locationListView,
              InformationMode.organization ||
              InformationMode.selectOrganization =>
                organizationListView,
              _ => const SizedBox.shrink(),
            },
    );
  }
}
