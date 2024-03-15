import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'package:samsara/ui/responsive_window.dart';

// import '../../../../ui/game_entity_listview.dart';
import '../../config.dart';
import '../../view/game_entity_listview.dart';
import '../../view/character/memory.dart';
import '../../view/location/location.dart';
import '../../view/organization/organization.dart';
import '../../scene/menu_item_builder.dart';
import '../../view/character/equipments.dart';
import '../../view/character/profile.dart';
import '../../dialog/input_world_location.dart';
// import '../../view/zone/zone.dart';
import '../../view/common.dart';
// import '../../state/game_data.dart';
import '../../events.dart';
import '../../dialog/input_string.dart';
import '../../dialog/confirm_dialog.dart';
import '../../view/character/edit_character_event_flags.dart';

enum CharacterPopUpMenuItems {
  setAsHero,
  clearWorldMapPosition,
  setWorldMapPosition,
  clearLocation,
  setLocation,
  clearLocationSite,
  setLocationSite,
  checkProfile,
  checkEventFlags,
  checkEquipments,
  checkHistory,
  delete,
}

List<PopupMenuEntry<CharacterPopUpMenuItems>> buildCharacterPopUpMenuItems(
    {void Function(CharacterPopUpMenuItems item)? onItemPressed}) {
  return <PopupMenuEntry<CharacterPopUpMenuItems>>[
    buildMenuItem(
      item: CharacterPopUpMenuItems.setAsHero,
      name: engine.locale('setAsHero'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.clearWorldMapPosition,
      name: engine.locale('clearWorldMapPosition'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.setWorldMapPosition,
      name: engine.locale('setWorldMapPosition'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.clearLocation,
      name: engine.locale('clearLocation'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.setLocation,
      name: engine.locale('setLocation'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.clearLocationSite,
      name: engine.locale('clearLocationSite'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.setLocationSite,
      name: engine.locale('setLocationSite'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.checkProfile,
      name: engine.locale('checkProfile'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.checkEventFlags,
      name: engine.locale('checkEventFlags'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.checkEquipments,
      name: engine.locale('checkEquipments'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.checkHistory,
      name: engine.locale('checkHistory'),
      onItemPressed: onItemPressed,
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: CharacterPopUpMenuItems.delete,
      name: engine.locale('delete'),
      onItemPressed: onItemPressed,
    ),
  ];
}

const _kCharacterColumns = [
  'name',
  'age',
];

const _kLocationColumns = [
  'name',
  'development',
];

const _kOrganizationColumns = [
  'name',
  'population',
];

const _kZoneColumns = [
  'name',
  'size',
];

class EntityListPanel extends StatefulWidget {
  const EntityListPanel({
    super.key,
    required this.size,
  });

  final Size size;

  @override
  State<EntityListPanel> createState() => _EntityListPanelState();
}

class _EntityListPanelState extends State<EntityListPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late List<Widget> _tabs;

  late String? _heroId;
  late int _worldWidth, _worldHeight;
  late Iterable<dynamic> _characters, _locations, _organizations, _zones;

  final List<List<String>> _charactersTableData = [],
      _locationsTableData = [],
      _organizationsTableData = [],
      _zonesTableData = [];

  @override
  void initState() {
    super.initState();
    _tabs = [
      Tab(
        icon: const Icon(Icons.person),
        text: engine.locale('character'),
      ),
      Tab(
        icon: const Icon(Icons.location_city),
        text: engine.locale('location'),
      ),
      Tab(
        icon: const Icon(Icons.groups),
        text: engine.locale('organization'),
      ),
      Tab(
        icon: const Icon(Icons.groups),
        text: engine.locale('zone'),
      ),
    ];

    final worldSizeData = engine.hetu.invoke('getWorldSize');
    _worldWidth = worldSizeData['width'];
    _worldHeight = worldSizeData['height'];

    updateCharacters();
    updateLocations();
    updateOrganizations();
    updateZones();
  }

  void updateCharacters() {
    _heroId = engine.hetu.invoke('getHeroId');

    _charactersTableData.clear();

    _characters = engine.hetu.invoke('getCharacters');
    for (final char in _characters) {
      final rowData = <String>[];
      rowData.add(char['name']);
      final age = engine.hetu.invoke('getCharacterAge', positionalArgs: [char]);
      rowData.add(age.toString());
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(char['id']);
      if (char['id'] == _heroId) {
        rowData.first = '${char['name']}★';
        _charactersTableData.insert(0, rowData);
      } else {
        _charactersTableData.add(rowData);
      }
    }
    setState(() {});
  }

  void updateLocations() {
    _locationsTableData.clear();
    _locations = engine.hetu.invoke('getLocations');
    for (final loc in _locations) {
      final rowData = <String>[];
      rowData.add(loc['name']);
      rowData.add(loc['development'].toString());
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(loc['id']);
      _locationsTableData.add(rowData);
    }
    setState(() {});
  }

  void updateOrganizations() {
    _organizationsTableData.clear();
    _organizations = engine.hetu.invoke('getOrganizations');
    for (final org in _organizations) {
      final rowData = <String>[];
      rowData.add(org['name']);
      rowData.add(org['characterIds'].length.toString());
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(org['id']);
      _organizationsTableData.add(rowData);
    }
    setState(() {});
  }

  void updateZones() {
    _zonesTableData.clear();
    _zones = engine.hetu.invoke('getZones');
    for (final zone in _zones) {
      final rowData = <String>[];
      rowData.add(zone['name']);
      rowData.add(zone['terrainIndexes'].length.toString());
      // 多存一个隐藏的 index 信息，用于点击事件
      rowData.add(zone['id']);
      _zonesTableData.add(rowData);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ResponsiveWindow(
      color: kBackgroundColor,
      size: widget.size,
      alignment: AlignmentDirectional.bottomCenter,
      child: DefaultTabController(
        length: _tabs.length,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(engine.locale('gameEntity')),
            bottom: TabBar(
              tabs: _tabs,
            ),
          ),
          body: TabBarView(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                            context: context,
                            builder: (context) {
                              return const ProfileView(
                                mode: ViewPanelMode.create,
                              );
                            }).then((value) {
                          if (value != null) {
                            engine.hetu.invoke('addCharacter',
                                positionalArgs: [value]);
                            updateCharacters();

                            if (value['worldPosition'] != null) {
                              engine.emit(GameEvents.worldmapCharactersUpdated);
                            }
                          }
                        });
                      },
                      child: Text(engine.locale('createCharacter')),
                    ),
                  ),
                  SizedBox(
                    height: widget.size.height - 175,
                    child: GameEntityListView(
                      columns: _kCharacterColumns,
                      tableData: _charactersTableData,
                      onItemPressed: (buttons, position, dataId) {
                        final menuPosition = RelativeRect.fromLTRB(
                            position.dx, position.dy, position.dx, 0.0);
                        final items =
                            buildCharacterPopUpMenuItems(onItemPressed: (item) {
                          switch (item) {
                            case CharacterPopUpMenuItems.setAsHero:
                              engine.hetu.invoke('setHeroId',
                                  positionalArgs: [dataId]);
                            case CharacterPopUpMenuItems.clearWorldMapPosition:
                              final charData = engine.hetu.invoke(
                                  'getCharacterById',
                                  positionalArgs: [dataId]);
                              if (charData['worldPosition'] != null) {
                                charData.remove('worldPosition');
                                engine
                                    .emit(GameEvents.worldmapCharactersUpdated);
                              }
                            case CharacterPopUpMenuItems.setWorldMapPosition:
                              final charData = engine.hetu.invoke(
                                  'getCharacterById',
                                  positionalArgs: [dataId]);
                              final charPosData = engine.hetu.invoke(
                                  'getCharacterWorldPosition',
                                  positionalArgs: [charData]);
                              InputWorldLocationDialog.show(
                                context: context,
                                maxX: _worldWidth,
                                maxY: _worldHeight,
                                defaultX: charPosData?['left'],
                                defaultY: charPosData?['top'],
                              ).then(((int, int)? value) {
                                if (value == null) return;
                                if (value.$1 != charPosData?['left'] ||
                                    value.$2 != charPosData?['top']) {
                                  engine.hetu.invoke(
                                      'setCharacterWorldPosition',
                                      positionalArgs: [
                                        charData,
                                        value.$1,
                                        value.$2
                                      ]);
                                  engine.emit(
                                      GameEvents.worldmapCharactersUpdated);
                                }
                              });
                            case CharacterPopUpMenuItems.clearLocation:
                              final charData = engine.hetu.invoke(
                                  'getCharacterById',
                                  positionalArgs: [dataId]);
                              charData.remove('locationId');
                            case CharacterPopUpMenuItems.setLocation:
                              InputStringDialog.show(context: context)
                                  .then((value) {
                                if (value != null) {
                                  final charData = engine.hetu.invoke(
                                      'getCharacterById',
                                      positionalArgs: [dataId]);
                                  engine.hetu.invoke('setCharacterLocationId',
                                      positionalArgs: [charData, value]);
                                }
                              });
                            case CharacterPopUpMenuItems.clearLocationSite:
                              final charData = engine.hetu.invoke(
                                  'getCharacterById',
                                  positionalArgs: [dataId]);
                              charData.remove('siteId');
                            case CharacterPopUpMenuItems.setLocationSite:
                              InputStringDialog.show(context: context)
                                  .then((value) {
                                if (value != null) {
                                  final charData = engine.hetu.invoke(
                                      'getCharacterById',
                                      positionalArgs: [dataId]);
                                  engine.hetu.invoke('setCharacterSiteId',
                                      positionalArgs: [charData, value]);
                                }
                              });
                            case CharacterPopUpMenuItems.checkProfile:
                              showDialog(
                                context: context,
                                builder: (context) => ProfileView(
                                  characterId: dataId,
                                  mode: ViewPanelMode.edit,
                                ),
                              ).then((value) {
                                if (value == true) {
                                  updateCharacters();
                                }
                              });
                            case CharacterPopUpMenuItems.checkEventFlags:
                              final charData = engine.hetu.invoke(
                                  'getCharacterById',
                                  positionalArgs: [dataId]);
                              showDialog<Map<String, bool>>(
                                context: context,
                                builder: (context) => EditCharacterEventFlags(
                                  flagsData: charData['flags'],
                                ),
                              ).then((value) {
                                if (value != null) {
                                  for (final key in value.keys) {
                                    charData['flags'][key] = value[key];
                                  }
                                }
                              });
                            case CharacterPopUpMenuItems.checkEquipments:
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    EquipmentsView(characterId: dataId),
                              );
                            case CharacterPopUpMenuItems.checkHistory:
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    MemoryView(characterId: dataId),
                              );
                            case CharacterPopUpMenuItems.delete:
                              showDialog<bool>(
                                context: context,
                                builder: (context) => ConfirmDialog(
                                    description:
                                        engine.locale('dangerOperationPrompt')),
                              ).then((bool? value) {
                                if (value == true) {
                                  engine.hetu.invoke('removeCharacterById',
                                      positionalArgs: [dataId]);
                                }
                              });
                          }
                        });
                        showMenu(
                          context: context,
                          position: menuPosition,
                          items: items,
                        );
                      },
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: ElevatedButton(
                      onPressed: () {
                        InputWorldLocationDialog.show(
                          context: context,
                          maxX: _worldWidth,
                          maxY: _worldHeight,
                          title: engine.locale('createLocation'),
                        ).then(((int, int)? value) {
                          if (value == null) return;
                          showDialog(
                              context: context,
                              builder: (context) {
                                return LocationView(
                                  mode: ViewPanelMode.create,
                                  left: value.$1,
                                  top: value.$2,
                                );
                              }).then((value) {
                            if (value == null) return;
                            engine.hetu
                                .invoke('addLocation', positionalArgs: [value]);
                            updateLocations();
                          });
                        });
                      },
                      child: Text(engine.locale('createLocation')),
                    ),
                  ),
                  SizedBox(
                    height: widget.size.height - 175,
                    child: GameEntityListView(
                        columns: _kLocationColumns,
                        tableData: _locationsTableData,
                        onItemPressed: (buttons, position, dataId) {
                          showDialog(
                            context: context,
                            builder: (context) => LocationView(
                              locationId: dataId,
                              mode: ViewPanelMode.edit,
                            ),
                          ).then((value) {
                            if (value == true) {
                              updateLocations();
                            }
                          });
                        }),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text(engine.locale('createOrganization')),
                    ),
                  ),
                  SizedBox(
                    height: widget.size.height - 175,
                    child: GameEntityListView(
                      columns: _kOrganizationColumns,
                      tableData: _organizationsTableData,
                      onItemPressed: (buttons, position, dataId) => showDialog(
                        context: context,
                        builder: (context) => OrganizationView(
                          organizationId: dataId,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text(engine.locale('createZone')),
                    ),
                  ),
                  SizedBox(
                    height: widget.size.height - 175,
                    child: GameEntityListView(
                      columns: _kZoneColumns,
                      tableData: _zonesTableData,
                      onItemPressed: (buttons, position, dataId) {
                        // showDialog(
                        //   context: context,
                        //   builder: (context) => ZoneView(zoneId: dataId),
                        // );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
