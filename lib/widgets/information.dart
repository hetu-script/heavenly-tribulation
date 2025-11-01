import 'package:flutter/material.dart';

import 'character/memory_and_bond.dart';
import '../global.dart';
import 'entity_table.dart';
import 'location/city.dart';
import 'location/site.dart';
import 'sect/sect.dart';
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
  selectCharacter,
  city,
  selectCity,
  selectSite,
  sect,
  selectSect,
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

enum _SectPopUpMenuItems {
  selectSect,
  checkInformation,
}

class InformationView extends StatefulWidget {
  const InformationView({
    super.key,
    this.title,
    this.width,
    this.height,
    this.showCloseButton = true,
    this.confirmationOnSelect = false,
    this.mode = InformationMode.all,
    this.characterIds,
    this.characters,
    this.locationIds,
    this.locations,
    this.sectIds,
    this.sects,
  });

  final String? title;
  final double? width;
  final double? height;
  final bool showCloseButton;
  final bool confirmationOnSelect;
  final InformationMode mode;
  final Iterable? characterIds;
  final Iterable? characters;
  final Iterable? locationIds;
  final Iterable? locations;
  final Iterable? sectIds;
  final Iterable? sects;

  @override
  State<InformationView> createState() => _InformationViewState();
}

class _InformationViewState extends State<InformationView>
    with AutomaticKeepAliveClientMixin {
  static late List<Widget> tabs;

  @override
  bool get wantKeepAlive => true;

  late final Iterable _locations, _sects, _characters;

  final List<List<String>> _locationsTable = [],
      _sectsTable = [],
      _charactersTable = [];

  late final String title;

  @override
  void initState() {
    super.initState();

    // TODO:只显示认识的人物和发现的城市

    if (widget.mode == InformationMode.selectCharacter) {
      assert(
        (widget.characterIds != null || widget.characters != null),
      );
    }
    if (widget.mode == InformationMode.selectCity ||
        widget.mode == InformationMode.selectSite) {
      assert(
        (widget.locationIds != null || widget.locations != null),
      );
    }
    if (widget.mode == InformationMode.selectSect) {
      assert(
        (widget.sectIds != null || widget.sects != null),
      );
    }

    if (widget.mode == InformationMode.all ||
        widget.mode == InformationMode.character ||
        widget.mode == InformationMode.selectCharacter) {
      if (widget.characters != null) {
        _characters = widget.characters!;
      } else if (widget.characterIds != null) {
        _characters = GameData.game['characters'].values.where(
            (character) => widget.characterIds!.contains(character['id']));
      } else {
        _characters = GameData.game['characters'].values;
      }
      for (final character in _characters) {
        final row = GameData.getCharacterInformationRow(character);
        _charactersTable.add(row);
      }
    }
    if (widget.mode == InformationMode.all ||
        widget.mode == InformationMode.city ||
        widget.mode == InformationMode.selectCity ||
        widget.mode == InformationMode.selectSite) {
      if (widget.locations != null) {
        _locations = widget.locations!;
      } else if (widget.locationIds != null) {
        _locations = GameData.game['locations'].values
            .where((location) => widget.locationIds!.contains(location['id']));
      } else {
        _locations = GameData.game['locations'].values
            .where((location) => location['category'] == 'city');
      }
      for (final location in _locations) {
        List<String> row;
        if (widget.mode == InformationMode.selectSite) {
          row = GameData.getSiteInformationRow(location);
        } else {
          row = GameData.getCityInformationRow(location);
        }
        _locationsTable.add(row);
      }
    }

    if (widget.mode == InformationMode.all ||
        widget.mode == InformationMode.sect ||
        widget.mode == InformationMode.selectSect) {
      if (widget.sects != null) {
        _sects = widget.sects!;
      } else if (widget.sectIds != null) {
        _sects = GameData.game['sects'].values
            .where((sect) => widget.sectIds!.contains(sect['id']));
      } else {
        _sects = GameData.game['sects'].values;
      }
      for (final sect in _sects) {
        final row = GameData.getSectInformationRow(sect);
        _sectsTable.add(row);
      }
    }

    tabs = [
      Tab(text: '${engine.locale('character')}(${_charactersTable.length})'),
      Tab(text: '${engine.locale('city')}(${_locationsTable.length})'),
      Tab(text: '${engine.locale('sect')}(${_sectsTable.length})'),
    ];

    if (widget.title != null) {
      title = widget.title!;
    } else {
      title = switch (widget.mode) {
        InformationMode.character => engine.locale('characterInformation'),
        InformationMode.selectCharacter => engine.locale('selectCharacter'),
        InformationMode.city => engine.locale('cityInformation'),
        InformationMode.selectCity => engine.locale('selectCity'),
        InformationMode.selectSite => engine.locale('selectSite'),
        InformationMode.sect => engine.locale('sectInformation'),
        InformationMode.selectSect => engine.locale('selectSect'),
        _ => engine.locale('info'),
      };
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    Widget? characterListView, locationListView, sectListView;

    if (_charactersTable.isNotEmpty) {
      characterListView = EntityTable(
        columns: kEntityTableCharacterColumns,
        tableData: _charactersTable,
        onItemPressed: (position, dataId) async {
          if (widget.mode == InformationMode.selectCharacter &&
              !widget.confirmationOnSelect) {
            Navigator.of(context).pop(dataId);
          } else {
            final bool? selected = await showDialog(
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
            if (selected == true) {
              Navigator.of(context).pop(dataId);
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
                  final bool? selected = await showDialog(
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
                  if (selected == true) {
                    Navigator.of(context).pop(dataId);
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
    }

    if (_locationsTable.isNotEmpty) {
      locationListView = EntityTable(
        columns: widget.mode == InformationMode.selectSite
            ? kEntityTableSiteColumns
            : kEntityTableLocationColumns,
        tableData: _locationsTable,
        onItemPressed: (position, dataId) async {
          if (widget.mode == InformationMode.selectCity ||
              widget.mode == InformationMode.selectSite &&
                  !widget.confirmationOnSelect) {
            Navigator.of(context).pop(dataId);
          } else {
            final bool? selected = await showDialog(
              context: context,
              builder: (context) => widget.mode == InformationMode.selectSite
                  ? SiteView(
                      siteId: dataId,
                      mode: widget.mode == InformationMode.selectSite
                          ? InformationViewMode.select
                          : InformationViewMode.view,
                    )
                  : CityView(
                      cityId: dataId,
                      mode: widget.mode == InformationMode.selectCity
                          ? InformationViewMode.select
                          : InformationViewMode.view,
                    ),
            );
            if (selected == true) {
              Navigator.of(context).pop(dataId);
            }
          }
        },
        onItemSecondaryPressed: (position, dataId) {
          showFluentMenu(
            position: position,
            items: {
              if (widget.mode == InformationMode.selectCity ||
                  widget.mode == InformationMode.selectSite) ...{
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
                  final bool? selected = await showDialog(
                    context: context,
                    builder: (context) =>
                        widget.mode == InformationMode.selectSite
                            ? SiteView(
                                siteId: dataId,
                                mode: widget.mode == InformationMode.selectSite
                                    ? InformationViewMode.select
                                    : InformationViewMode.view,
                              )
                            : CityView(
                                cityId: dataId,
                                mode: widget.mode == InformationMode.selectCity
                                    ? InformationViewMode.select
                                    : InformationViewMode.view,
                              ),
                  );
                  if (selected == true) {
                    Navigator.of(context).pop(dataId);
                  }
              }
            },
          );
        },
      );
    }

    if (_sectsTable.isNotEmpty) {
      sectListView = EntityTable(
        columns: kEntityTableSectColumns,
        tableData: _sectsTable,
        onItemPressed: (position, dataId) async {
          if (widget.mode == InformationMode.selectCity &&
              !widget.confirmationOnSelect) {
            Navigator.of(context).pop(dataId);
          } else {
            final bool? selected = await showDialog(
              context: context,
              builder: (context) => SectView(
                sectId: dataId,
                mode: widget.mode == InformationMode.selectSect
                    ? InformationViewMode.select
                    : InformationViewMode.view,
              ),
            );
            if (selected == true) {
              Navigator.of(context).pop(dataId);
            }
          }
        },
        onItemSecondaryPressed: (position, dataId) {
          showFluentMenu(
            position: position,
            items: {
              if (widget.mode == InformationMode.selectSect) ...{
                engine.locale('selectSect'): _SectPopUpMenuItems.selectSect,
                '___': null,
              },
              engine.locale('checkInformation'):
                  _SectPopUpMenuItems.checkInformation,
            },
            onSelectedItem: (_SectPopUpMenuItems item) async {
              switch (item) {
                case _SectPopUpMenuItems.selectSect:
                  Navigator.of(context).pop(dataId);
                case _SectPopUpMenuItems.checkInformation:
                  final bool? selected = await showDialog(
                    context: context,
                    builder: (context) => SectView(
                      sectId: dataId,
                      mode: widget.mode == InformationMode.selectSect
                          ? InformationViewMode.select
                          : InformationViewMode.view,
                    ),
                  );
                  if (selected == true) {
                    Navigator.of(context).pop(dataId);
                  }
              }
            },
          );
        },
      );
    }

    return ResponsiveView(
      width: widget.width,
      height: widget.height,
      barrierDismissible: widget.showCloseButton,
      child: widget.mode == InformationMode.all
          ? DefaultTabController(
              length: tabs.length,
              child: Scaffold(
                appBar: AppBar(
                  automaticallyImplyLeading: false,
                  title: Text(title),
                  actions: [
                    if (widget.showCloseButton) CloseButton2(),
                  ],
                  bottom: TabBar(tabs: tabs),
                ),
                body: TabBarView(
                  children: [
                    characterListView!,
                    locationListView!,
                    sectListView!,
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
                InformationMode.city ||
                InformationMode.selectCity ||
                InformationMode.selectSite =>
                  locationListView,
                InformationMode.sect ||
                InformationMode.selectSect =>
                  sectListView,
                _ => const SizedBox.shrink(),
              },
            ),
    );
  }
}
