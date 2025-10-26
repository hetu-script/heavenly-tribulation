import 'package:flutter/material.dart';

import 'character/memory_and_bond.dart';
import '../engine.dart';
import 'entity_table.dart';
import 'location/location.dart';
import 'organization/organization.dart';
import 'ui/menu_builder.dart';
import 'character/profile.dart';
import 'character/stats_and_item.dart';
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
  checkStatsAndItem,
  checkMemoryAndBond,
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
    this.title,
    this.width,
    this.height,
    this.barrierDismissible = true,
    this.showCloseButton = true,
    this.confirmationOnSelect = false,
    this.mode = InformationMode.all,
    this.characterIds,
    this.characters,
    this.locationIds,
    this.locations,
    this.organizationIds,
    this.organizations,
  });

  final String? title;
  final double? width;
  final double? height;
  final bool barrierDismissible;
  final bool showCloseButton;
  final bool confirmationOnSelect;
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
      onItemPressed: (position, dataId) async {
        if (widget.mode == InformationMode.selectCharacter &&
            !widget.confirmationOnSelect) {
          Navigator.of(context).pop(dataId);
        } else {
          final charId = await showDialog(
            context: context,
            builder: (context) => CharacterProfileView(
              characterId: dataId,
              showIntimacy: false,
              showPersonality: false,
              mode: widget.mode == InformationMode.selectCharacter
                  ? InformationViewMode.select
                  : InformationViewMode.view,
            ),
          );
          if (charId != null) {
            Navigator.of(context).pop(charId);
          }
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
            engine.locale('checkStatsAndItem'):
                _CharacterPopUpMenuItems.checkStatsAndItem,
            engine.locale('checkMemoryAndBond'):
                _CharacterPopUpMenuItems.checkMemoryAndBond,
          },
          onSelectedItem: (_CharacterPopUpMenuItems item) async {
            switch (item) {
              case _CharacterPopUpMenuItems.selectCharacter:
                Navigator.of(context).pop(dataId);
              case _CharacterPopUpMenuItems.checkProfile:
                final charId = await showDialog(
                  context: context,
                  builder: (context) => CharacterProfileView(
                    characterId: dataId,
                    showIntimacy: false,
                    showPersonality: false,
                    mode: widget.mode == InformationMode.selectCharacter
                        ? InformationViewMode.select
                        : InformationViewMode.view,
                  ),
                );
                if (charId != null) {
                  Navigator.of(context).pop(charId);
                }
              case _CharacterPopUpMenuItems.checkStatsAndItem:
                showDialog(
                  context: context,
                  builder: (context) =>
                      CharacterStatsAndItemView(characterId: dataId),
                );
              case _CharacterPopUpMenuItems.checkMemoryAndBond:
                showDialog(
                  context: context,
                  builder: (context) =>
                      CharacterMemoryAndBondView(characterId: dataId),
                );
            }
          },
        );
      },
    );

    final locationListView = EntityTable(
      columns: kEntityTableLocationColumns,
      tableData: _locationsTable,
      onItemPressed: (position, dataId) async {
        if (widget.mode == InformationMode.selectLocation &&
            !widget.confirmationOnSelect) {
          Navigator.of(context).pop(dataId);
        } else {
          final locId = await showDialog(
            context: context,
            builder: (context) => LocationView(
              locationId: dataId,
              mode: widget.mode == InformationMode.selectLocation
                  ? InformationViewMode.select
                  : InformationViewMode.view,
            ),
          );
          if (locId != null) {
            Navigator.of(context).pop(locId);
          }
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
          onSelectedItem: (_LocationPopUpMenuItems item) async {
            switch (item) {
              case _LocationPopUpMenuItems.selectLocation:
                Navigator.of(context).pop(dataId);
              case _LocationPopUpMenuItems.checkInformation:
                final locId = await showDialog(
                  context: context,
                  builder: (context) => LocationView(
                    locationId: dataId,
                    mode: widget.mode == InformationMode.selectLocation
                        ? InformationViewMode.select
                        : InformationViewMode.view,
                  ),
                );
                if (locId != null) {
                  Navigator.of(context).pop(locId);
                }
            }
          },
        );
      },
    );

    final organizationListView = EntityTable(
      columns: kEntityTableOrganizationColumns,
      tableData: _organizationsTable,
      onItemPressed: (position, dataId) async {
        if (widget.mode == InformationMode.selectLocation &&
            !widget.confirmationOnSelect) {
          Navigator.of(context).pop(dataId);
        } else {
          final orgId = await showDialog(
            context: context,
            builder: (context) => OrganizationView(
              organizationId: dataId,
              mode: widget.mode == InformationMode.selectOrganization
                  ? InformationViewMode.select
                  : InformationViewMode.view,
            ),
          );
          if (orgId != null) {
            Navigator.of(context).pop(orgId);
          }
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
          onSelectedItem: (_OrganizationPopUpMenuItems item) async {
            switch (item) {
              case _OrganizationPopUpMenuItems.selectOrganization:
                Navigator.of(context).pop(dataId);
              case _OrganizationPopUpMenuItems.checkInformation:
                final orgId = await showDialog(
                  context: context,
                  builder: (context) => OrganizationView(
                    organizationId: dataId,
                    mode: widget.mode == InformationMode.selectOrganization
                        ? InformationViewMode.select
                        : InformationViewMode.view,
                  ),
                );
                if (orgId != null) {
                  Navigator.of(context).pop(orgId);
                }
            }
          },
        );
      },
    );

    return ResponsiveView(
      width: widget.width,
      height: widget.height,
      barrierDismissible: widget.barrierDismissible,
      child: widget.mode == InformationMode.all
          ? DefaultTabController(
              length: tabs.length,
              child: Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(widget.title ?? engine.locale('info')),
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
          : Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text(widget.title ?? engine.locale('info')),
                actions: [
                  if (widget.showCloseButton) CloseButton2(),
                ],
              ),
              body: switch (widget.mode) {
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
            ),
    );
  }
}
