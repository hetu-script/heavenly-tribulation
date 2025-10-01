import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/widgets/location/edit_location_basics.dart';
import 'package:json5/json5.dart';
import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/tilemap.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../../engine.dart';
import '../../../game/ui.dart';
import '../../../widgets/game_entity_listview.dart';
import '../../../widgets/character/memory.dart';
import '../../../widgets/location/location.dart';
import '../../../widgets/organization/organization.dart';
import '../../../widgets/ui/menu_builder.dart';
import '../../../widgets/character/details.dart';
import '../../../widgets/character/profile.dart';
import '../../../widgets/dialog/input_world_position.dart';
import '../../../widgets/common.dart';
import '../../../widgets/dialog/input_string.dart';
import '../../../widgets/dialog/confirm.dart';
import '../../../widgets/organization/edit_organization_basic.dart';
import '../../../widgets/dialog/input_description.dart';
import '../../../state/selected_tile.dart';
import '../../../game/logic/logic.dart';
import '../../game_dialog/game_dialog_content.dart';
import '../../../widgets/character/edit_character_basics.dart';
import '../../common.dart';
import '../../../game/data.dart';
import '../../../widgets/character/edit_rank_level.dart';

const kMapObjectSourceTemplate = '''{
  id: 'object1',
  name: 'object_name',
  entityType: 'object',
  category: 'custom',
  isDiscovered: true,
  // isHidden: false,
  // overlaySprite: {
  //   sprite: 'sprite.png',
  //   animation: {
  //     path: "object/animation/fishZone.png",
  //   },
  // },
  // hoverContent: 'object1',
  useCustomLogic: true,
  blockMove: false,
}
''';

const kMapObjectPortalSourceTemplate = '''{
  id: 'portal1',
  name: 'object_name',
  entityType: 'object',
  category: 'portal',
  isDiscovered: true,
  // isHidden: false,
  // overlaySprite: {
  //   sprite: 'sprite.png',
  //   animation: {
  //     path: "object/animation/fishZone.png",
  //   },
  // },
  useCustomLogic: false,
  blockMove: false,
  hoverContent: 'portal1',
  darkenBeforeMove: false,
  targetTilePosition: {
    left: 1,
    top: 1,
  },
}
''';

const kMapObjectWorldPortalSourceTemplate = '''{
  id: 'worldPortal1',
  name: 'object_name',
  entityType: 'object',
  category: 'worldPortal',
  isDiscovered: false,
  // isHidden: false,
  // overlaySprite: {
  //   sprite: 'sprite.png',
  //   animation: {
  //     path: "object/animation/fishZone.png",
  //   },
  // },
  useCustomLogic: false,
  blockMove: false,
  worldId: 'main',
  hoverContent: 'worldPortal1',
  targetTilePosition: {
    left: 1,
    top: 1,
  },
}
''';

const kMapObjectCharacterSourceTemplate = '''{
  id: 'characterObject1',
  name: 'object_name',
  entityType: 'object',
  category: 'character',
  isDiscovered: false,
  // isHidden: false,
  // overlaySprite: {
  //   sprite: 'sprite.png',
  //   animation: {
  //     path: "object/animation/fishZone.png",
  //   },
  // },
  hoverContent: 'characterObject1',
  useCustomLogic: false,
  blockMove: true,
  characterId: 'character_id',
}
''';

const kMapObjectTreasureBoxSourceTemplate = '''{
  id: 'treasureBox1',
  name: 'object_name',
  entityType: 'object',
  category: 'treasureBox',
  isDiscovered: false,
  // isHidden: false,
  // overlaySprite: {
  //   sprite: 'sprite.png',
  //   animation: {
  //     path: "object/animation/fishZone.png",
  //   },
  // },
  useCustomLogic: false,
  blockMove: false,
  hoverContent: 'treasureBox1',
  items: [
    {
      type: 'material',
      kind: 'money',
      amount: 100,
    },
    {
      type: 'prototype',
      kind: 'shard',
    },
    {
      type: 'equipment',
      kind: 'sword',
      rarity: 'common',
      rank: 0,
      level: 0,
    },
    {
      type: 'cardpack',
      kind: 'punch',
      genre: null,
      rank: 0,
    },
  ]
}
''';

enum CharacterPopUpMenuItems {
  checkProfile,
  checkStatsAndEquipments,
  checkMemory,
  checkCultivation,
  setRankLevel,
  allocatePassives,
  setAsHero,
  clearWorldPosition,
  setWorldPosition,
  clearLocation,
  setLocation,
  clearHome,
  setHome,
  delete,
}

enum LocationPopUpMenuItems {
  checkInformation,
  setWorldId,
  setWorldPosition,
  delete,
}

enum CreateObjectPopUpMenuItems {
  custom,
  portal,
  worldPortal,
  character,
  treasureBox,
}

enum ObjectPopUpMenuItems {
  edit,
  delete,
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

const _kObjectColumns = [
  'id',
  'type',
];

class EntityListPanel extends StatefulWidget {
  const EntityListPanel({
    super.key,
    required this.size,
    this.onUpdateCharacters,
    this.onUpdateLocations,
    this.onCreatedOrganization,
  });

  final Size size;

  final void Function()? onUpdateCharacters;
  final void Function()? onUpdateLocations;
  final void Function(dynamic, TileMapTerrain)? onCreatedOrganization;

  @override
  State<EntityListPanel> createState() => _EntityListPanelState();
}

class _EntityListPanelState extends State<EntityListPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Scene? _scene;

  static List<Widget> tabs = [
    Tab(text: engine.locale('character')),
    Tab(text: engine.locale('organization')),
    Tab(text: engine.locale('location')),
    Tab(text: engine.locale('mapObject')),
    Tab(text: engine.locale('zone')),
  ];

  final _createObjectFlyoutController = fluent.FlyoutController();

  late String? _heroId;
  // late int _worldWidth, _worldHeight;
  late Iterable<dynamic> _characters,
      _locations,
      _organizations,
      _zones,
      _mapObjects;

  final List<List<String>> _charactersTableData = [],
      _locationsTableData = [],
      _organizationsTableData = [],
      _zonesTableData = [],
      _mapObjectsTableData = [];

  @override
  void initState() {
    super.initState();

    // final worldSizeData = engine.hetu.invoke('getWorldSize');
    // _worldWidth = worldSizeData['width'];
    // _worldHeight = worldSizeData['height'];

    _updateCharacters();
    _updateOrganizations();
    _updateLocations();
    _updateZones();
    _updateObjects();
  }

  @override
  void dispose() {
    super.dispose();

    _createObjectFlyoutController.dispose();
  }

  void _updateCharacters() {
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
        rowData.first = '${char['name']}';
        _charactersTableData.insert(0, rowData);
      } else {
        _charactersTableData.add(rowData);
      }
    }
    setState(() {});
  }

  void _editCharacter(String dataId) async {
    final data = GameData.getCharacter(dataId);

    final result = await showDialog(
      context: context,
      builder: (context) => CharacterProfileView(
        character: data,
        mode: InformationViewMode.edit,
      ),
    );

    if (result == true) {
      _updateCharacters();
    }
  }

  void _updateOrganizations() {
    _organizationsTableData.clear();
    _organizations = engine.hetu.invoke('getOrganizations');
    for (final org in _organizations) {
      final rowData = <String>[];
      rowData.add(org['name']);
      rowData.add(org['members'].length.toString());
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(org['id']);
      _organizationsTableData.add(rowData);
    }
    setState(() {});
  }

  void _editOrganization(String dataId) async {
    final value = await showDialog(
      context: context,
      builder: (context) => OrganizationView(
        organizationId: dataId,
        mode: InformationViewMode.edit,
      ),
    );
    if (value == true) return;

    _updateOrganizations();
  }

  void _updateLocations() {
    _locationsTableData.clear();
    _locations = engine.hetu.fetch('locations', namespace: 'game').values;
    for (final loc in _locations) {
      if (loc['category'] != 'city') continue;
      final rowData = <String>[];
      rowData.add(loc['name']);
      rowData.add(loc['development'].toString());
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(loc['id']);
      _locationsTableData.add(rowData);
    }
    setState(() {});
  }

  void _editLocation(String dataId) async {
    final value = await showDialog(
      context: context,
      builder: (context) => LocationView(
        locationId: dataId,
        mode: InformationViewMode.edit,
      ),
    );
    if (value != true) return;

    _updateLocations();
    widget.onUpdateLocations?.call();
  }

  void _updateObjects() {
    _mapObjectsTableData.clear();
    _mapObjects = engine.hetu.invoke('getObjects');
    for (final obj in _mapObjects) {
      final rowData = <String>[];
      rowData.add(obj['id']);
      rowData.add(engine.locale(obj['category']));
      // 多存一个隐藏的 index 信息，用于点击事件
      rowData.add(obj['id']);
      _mapObjectsTableData.add(rowData);
    }
    setState(() {});
  }

  void _editObject(String dataId) async {
    final objectsData = engine.hetu.fetch('objects', namespace: 'world');
    final obj = objectsData['dataId'];
    final originObjId = obj['id'];
    assert(obj != null);
    final objString = engine.hetu.stringify(obj);
    final result = await showDialog(
      context: context,
      builder: (context) => InputDescriptionDialog(
        title: engine.locale('inputObjectSource'),
        description: objString,
      ),
    );
    if (result == null) return;
    final jsonData = json5Decode(result);
    if (jsonData != null && jsonData.isNotEmpty) {
      if (jsonData['originObjId'] != originObjId) {
        engine.hetu.invoke('removeObjectById', positionalArgs: [originObjId]);
      }
      final mapObject = engine.hetu.interpreter.createStructfromJSON(jsonData);
      engine.hetu.invoke('addObject', positionalArgs: [mapObject]);
      _updateObjects();
    }
  }

  void _updateZones() {
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
    _zonesTableData.sort(
      (a, b) {
        final sizeOfA = int.parse(a[1]);
        final sizeOfB = int.parse(b[1]);
        return sizeOfB.compareTo(sizeOfA);
      },
    );
    setState(() {});
  }

  void _editZone(String dataId) async {
    final zonesData = engine.hetu.fetch('zones', namespace: 'world');
    final zone = zonesData[dataId];
    final newName = await showDialog(
      context: context,
      builder: (context) => InputStringDialog(
        title: engine.locale('inputName'),
        value: zone['name'],
      ),
    );
    if (newName == null) return;
    zone['name'] = newName;
    _updateZones();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final scene = context.watch<SamsaraEngine>().scene;
    if (_scene?.id != scene?.id) {
      _scene = scene;
      _updateLocations();
      _updateZones();
      _updateObjects();
    }

    return ResponsiveView(
      alignment: Alignment.centerLeft,
      backgroundColor: GameUI.backgroundColor2,
      width: widget.size.width,
      height: widget.size.height,
      child: DefaultTabController(
        length: tabs.length,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(engine.locale('gameEntity')),
            bottom: TabBar(
              tabs: tabs,
            ),
          ),
          body: TabBarView(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0),
                    child: fluent.FilledButton(
                      onPressed: () async {
                        final value = await showDialog(
                          context: context,
                          builder: (context) {
                            return EditCharacterBasics();
                          },
                        );
                        if (value == null) return;
                        final (
                          id,
                          surName,
                          name,
                          isFemale,
                          race,
                          icon,
                          illustration,
                          skin,
                        ) = value;
                        final character =
                            engine.hetu.invoke('Character', namedArgs: {
                          'id': id,
                          'name':
                              name != null ? ((surName ?? '') + name) : name,
                          'surName': surName,
                          'isFemale': isFemale,
                          'race': race,
                          'icon': icon,
                          'illustration': illustration,
                          'skin': skin,
                        });
                        await showDialog(
                            context: context,
                            builder: (context) {
                              return CharacterProfileView(
                                mode: InformationViewMode.edit,
                                character: character,
                              );
                            });
                        _updateCharacters();
                        widget.onUpdateCharacters?.call();
                      },
                      child: Text(engine.locale('createCharacter')),
                    ),
                  ),
                  // Padding(
                  //   padding: const EdgeInsets.only(top: 5.0),
                  //   child: fluent.FilledButton(
                  //     onPressed: () async {
                  //       final result = await showDialog(
                  //           context: context,
                  //           builder: (context) => InputDescriptionDialog(
                  //                 title: engine.locale('createObject'),
                  //                 description: kLocationObjectSourceTemplate,
                  //               ));
                  //       if (result == null) return;
                  //       final jsonData = json5Decode(result);
                  //       if (jsonData != null && jsonData.isNotEmpty) {
                  //         engine.hetu.invoke('LocationObject', namedArgs: {
                  //           'id': jsonData['id'],
                  //           'icon': jsonData['icon'],
                  //           'locationId': jsonData['locationId'],
                  //           'name': jsonData['name'],
                  //         });
                  //       }
                  //     },
                  //     child: Text(engine.locale('createLocationObject')),
                  //   ),
                  // ),
                  SizedBox(
                    height: widget.size.height - 175,
                    child: GameEntityListView(
                      columns: _kCharacterColumns,
                      tableData: _charactersTableData,
                      onItemPressed: (position, dataId) {
                        _editCharacter(dataId);
                      },
                      onItemSecondaryPressed: (position, characterId) {
                        showFluentMenu(
                          position: position,
                          items: {
                            engine.locale('checkProfile'):
                                CharacterPopUpMenuItems.checkProfile,
                            engine.locale('checkStatsAndEquipments'):
                                CharacterPopUpMenuItems.checkStatsAndEquipments,
                            engine.locale('checkMemory'):
                                CharacterPopUpMenuItems.checkMemory,
                            engine.locale('checkCultivation'):
                                CharacterPopUpMenuItems.checkCultivation,
                            '___1': null,
                            engine.locale('setAsHero'):
                                CharacterPopUpMenuItems.setAsHero,
                            engine.locale('setRankLevel'):
                                CharacterPopUpMenuItems.setRankLevel,
                            engine.locale('allocatePassives'):
                                CharacterPopUpMenuItems.allocatePassives,
                            '___2': null,
                            engine.locale('setWorldPosition'):
                                CharacterPopUpMenuItems.setWorldPosition,
                            engine.locale('clearWorldPosition'):
                                CharacterPopUpMenuItems.clearWorldPosition,
                            engine.locale('setHome'):
                                CharacterPopUpMenuItems.setHome,
                            engine.locale('clearHome'):
                                CharacterPopUpMenuItems.clearHome,
                            engine.locale('setLocation'):
                                CharacterPopUpMenuItems.setLocation,
                            engine.locale('clearLocation'):
                                CharacterPopUpMenuItems.clearLocation,
                            '___3': null,
                            engine.locale('delete'):
                                CharacterPopUpMenuItems.delete,
                          },
                          onSelectedItem: (item) async {
                            final character =
                                GameData.getCharacter(characterId);
                            switch (item) {
                              case CharacterPopUpMenuItems.checkProfile:
                                _editCharacter(characterId);
                              // case CharacterPopUpMenuItems.checkEventFlags:
                              //   final value =
                              //       await showDialog<Map<String, bool>>(
                              //     context: context,
                              //     builder: (context) => EditCharacterFlags(
                              //         characterData: characterData),
                              //   );
                              //   if (value != null) {
                              //     for (final key in value.keys) {
                              //       characterData[key] = value[key];
                              //     }
                              //   }
                              case CharacterPopUpMenuItems
                                    .checkStatsAndEquipments:
                                showDialog(
                                  context: context,
                                  builder: (context) => CharacterDetailsView(
                                      character: character),
                                );
                              case CharacterPopUpMenuItems.checkMemory:
                                showDialog(
                                  context: context,
                                  builder: (context) => CharacterMemoryView(
                                    characterId: characterId,
                                    mode: InformationViewMode.edit,
                                  ),
                                );
                              case CharacterPopUpMenuItems.checkCultivation:
                                engine.pushScene(Scenes.cultivation,
                                    arguments: {'character': character});
                              case CharacterPopUpMenuItems.setRankLevel:
                                final int rank = character['rank'];
                                final int level = character['level'];
                                final value =
                                    await EditRankLevelSliderDialog.show(
                                  context: context,
                                  rank: rank,
                                  level: level,
                                );
                                if (value == null) return;
                                final (newRank, newLevel) = value;
                                character['rank'] = newRank;
                                character['level'] = newLevel;
                              case CharacterPopUpMenuItems.allocatePassives:
                                GameLogic.characterAllocateSkills(character);
                              case CharacterPopUpMenuItems.setAsHero:
                                engine.hetu.invoke('setHeroId',
                                    positionalArgs: [characterId]);
                              case CharacterPopUpMenuItems.clearWorldPosition:
                                character.remove('worldPosition');
                                character.remove('worldId');
                                widget.onUpdateCharacters?.call();
                              // case CharacterPopUpMenuItems.setWorldId:
                              //   final worldId = await GameLogic.selectWorldId();
                              //   if (worldId != null) {
                              //     if (characterData['worldId'] != worldId) {
                              //       characterData['worldId'] = worldId;
                              //       widget.onUpdateCharacters?.call();
                              //     }
                              //   }
                              case CharacterPopUpMenuItems.setWorldPosition:
                                final charPosData = character['worldPosition'];
                                final selectedTile = context
                                    .read<SelectedPositionState>()
                                    .currentTerrain;
                                final currentMapId =
                                    context.read<SamsaraEngine>().scene?.id;
                                int? left =
                                    charPosData?['left'] ?? selectedTile?.left;
                                int? top =
                                    charPosData?['top'] ?? selectedTile?.top;
                                final value =
                                    await InputWorldPositionDialog.show(
                                  context: context,
                                  defaultX: left,
                                  defaultY: top,
                                  worldId: currentMapId,
                                );
                                if (value == null) return;
                                if (value.$1 != charPosData?['left'] ||
                                    value.$2 != charPosData?['top'] ||
                                    value.$3 != character?['worldId']) {
                                  engine.hetu.invoke(
                                      'setCharacterWorldPosition',
                                      positionalArgs: [
                                        character,
                                        value.$1,
                                        value.$2,
                                      ],
                                      namedArgs: {
                                        'worldId': value.$3,
                                      });
                                  widget.onUpdateCharacters?.call();
                                }
                              case CharacterPopUpMenuItems.clearHome:
                                engine.hetu.invoke(
                                    'clearCharacterHomeLocations',
                                    positionalArgs: [character]);
                              case CharacterPopUpMenuItems.setHome:
                                InputStringDialog.show(context: context)
                                    .then((locationId) {
                                  if (locationId != null) {
                                    final location =
                                        GameData.game['locations'][locationId];
                                    if (location == null) {
                                      GameDialogContent.show(context,
                                          '输入的据点 id [$locationId] 不存在！');
                                    } else {
                                      engine.hetu.invoke(
                                        'setCharacterHome',
                                        positionalArgs: [
                                          character,
                                          location,
                                        ],
                                        namedArgs: {
                                          'incurIncident': false,
                                        },
                                      );
                                    }
                                  }
                                });
                              case CharacterPopUpMenuItems.clearLocation:
                                character.remove('locationId');
                              case CharacterPopUpMenuItems.setLocation:
                                InputStringDialog.show(context: context)
                                    .then((value) {
                                  if (value != null) {
                                    engine.hetu.invoke('setCharacterLocationId',
                                        positionalArgs: [character, value]);
                                  }
                                });
                              // case CharacterPopUpMenuItems.clearLocationSite:
                              //   final charData = engine.hetu.invoke(
                              //       'getCharacterById',
                              //       positionalArgs: [dataId]);
                              //   charData.remove('siteId');
                              // case CharacterPopUpMenuItems.setLocationSite:
                              //   InputStringDialog.show(context: context)
                              //       .then((value) {
                              //     if (value != null) {
                              //       final charData = engine.hetu.invoke(
                              //           'getCharacterById',
                              //           positionalArgs: [dataId]);
                              //       engine.hetu.invoke('setCharacterSiteId',
                              //           positionalArgs: [charData, value]);
                              //     }
                              //   });
                              case CharacterPopUpMenuItems.delete:
                                final value = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => ConfirmDialog(
                                      description: engine
                                          .locale('dangerOperationPrompt')),
                                );
                                if (value == true) {
                                  engine.hetu.invoke('removeCharacterById',
                                      positionalArgs: [characterId]);
                                  _updateCharacters();
                                }
                            }
                          },
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
                    child: fluent.FilledButton(
                      onPressed: () async {
                        final selectedTile = context
                            .read<SelectedPositionState>()
                            .currentTerrain;
                        if (selectedTile == null) {
                          GameDialogContent.show(
                              context, engine.locale('hint_selectTilePrompt'));
                          return;
                        }
                        if (selectedTile.nationId != null) {
                          GameDialogContent.show(context,
                              engine.locale('hint_selectedTileOccupied'));
                          return;
                        }
                        if (selectedTile.locationId == null) {
                          GameDialogContent.show(
                              context, engine.locale('hint_selectCityPrompt'));
                          return;
                        }
                        final location =
                            GameData.game['locations'][selectedTile.locationId];
                        if (location['category'] != 'city') {
                          GameDialogContent.show(
                              context, engine.locale('hint_selectCityPrompt'));
                          return;
                        }
                        final value = await showDialog(
                            context: context,
                            builder: (context) {
                              return EditOrganizationBasics(
                                headquartersData: location,
                              );
                            });
                        if (value == null) return;
                        final (id, name, category, genre, headId) = value;
                        final organization = engine.hetu.invoke(
                          'Organization',
                          namedArgs: {
                            'id': id,
                            'name': name,
                            'category': category,
                            'genre': genre,
                            'headquarters': location,
                            'headId': headId,
                          },
                        );
                        await showDialog(
                            context: context,
                            builder: (context) {
                              return OrganizationView(
                                mode: InformationViewMode.edit,
                                organization: organization,
                              );
                            });
                        _updateOrganizations();
                        widget.onCreatedOrganization
                            ?.call(organization, selectedTile);
                      },
                      child: Text(engine.locale('createOrganization')),
                    ),
                  ),
                  SizedBox(
                    height: widget.size.height - 175,
                    child: GameEntityListView(
                        columns: _kOrganizationColumns,
                        tableData: _organizationsTableData,
                        onItemPressed: (position, dataId) {
                          _editOrganization(dataId);
                        },
                        onItemSecondaryPressed: (position, dataId) {}),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, right: 10.0),
                    child: fluent.FilledButton(
                      onPressed: () async {
                        final selectedTile = context
                            .read<SelectedPositionState>()
                            .currentTerrain;
                        if (selectedTile == null) {
                          GameDialogContent.show(
                              context, engine.locale('hint_selectTilePrompt'));
                          return;
                        }
                        dynamic atTerrain = selectedTile.data;
                        dynamic atLocation;
                        if (selectedTile.locationId != null) {
                          atLocation = GameData.game['locations']
                              [selectedTile.locationId];
                        }
                        final value = await showDialog(
                          context: context,
                          builder: (context) {
                            return EditLocationBasics(
                              category: atLocation != null ? 'site' : 'city',
                              atLocation: atLocation,
                              allowEditCategory: atLocation == null,
                            );
                          },
                        );
                        if (value == null) return;
                        final (
                          id,
                          category,
                          kind,
                          name,
                          image,
                          background,
                          createNpc
                        ) = value;
                        final location = engine.hetu.invoke(
                          'Location',
                          namedArgs: {
                            'id': id,
                            'category': category,
                            'kind': kind,
                            'name': name,
                            'image': image,
                            'background': background,
                            'atTerrain': atTerrain,
                            if (category == 'site') 'atLocation': atLocation,
                            'createNpc': createNpc,
                          },
                        );
                        await showDialog(
                            context: context,
                            builder: (context) {
                              return LocationView(
                                location: location,
                                mode: InformationViewMode.edit,
                              );
                            });
                        _updateLocations();
                        widget.onUpdateLocations?.call();
                      },
                      child: Text(engine.locale('createLocation')),
                    ),
                  ),
                  SizedBox(
                    height: widget.size.height - 175,
                    child: GameEntityListView(
                      columns: _kLocationColumns,
                      tableData: _locationsTableData,
                      onItemPressed: (position, dataId) {
                        _editLocation(dataId);
                      },
                      onItemSecondaryPressed: (position, dataId) {
                        showFluentMenu(
                            position: position,
                            items: {
                              engine.locale('checkInformation'):
                                  LocationPopUpMenuItems.checkInformation,
                              engine.locale('setWorldId'):
                                  LocationPopUpMenuItems.setWorldId,
                              engine.locale('setWorldPosition'):
                                  LocationPopUpMenuItems.setWorldPosition,
                              '___': null,
                              engine.locale('delete'):
                                  LocationPopUpMenuItems.delete,
                            },
                            onSelectedItem: (item) async {
                              final location =
                                  GameData.game['locations'][dataId];
                              assert(location != null,
                                  'location not found, id: $dataId');
                              switch (item) {
                                case LocationPopUpMenuItems.checkInformation:
                                  _editLocation(dataId);
                                case LocationPopUpMenuItems.setWorldId:
                                  final worldId = await GameLogic.selectWorld();
                                  if (worldId != null) {
                                    if (location['worldId'] != worldId) {
                                      location['worldId'] = worldId;
                                      widget.onUpdateLocations?.call();
                                    }
                                  }
                                case LocationPopUpMenuItems.setWorldPosition:
                                  final locPosData = location['worldPosition'];
                                  final selectedTile = context
                                      .read<SelectedPositionState>()
                                      .currentTerrain;
                                  final currentMapId =
                                      context.read<SamsaraEngine>().scene?.id;
                                  int? left =
                                      locPosData?['left'] ?? selectedTile?.left;
                                  int? top =
                                      locPosData?['top'] ?? selectedTile?.top;
                                  final value =
                                      await InputWorldPositionDialog.show(
                                    context: context,
                                    defaultX: left,
                                    defaultY: top,
                                    worldId: currentMapId,
                                  );
                                  if (value == null) return;
                                  if (value.$1 != locPosData?['left'] ||
                                      value.$2 != locPosData?['top'] ||
                                      value.$3 != location?['worldId']) {
                                    engine.hetu.invoke(
                                        'setLocationWorldPosition',
                                        positionalArgs: [
                                          location,
                                          value.$1,
                                          value.$2,
                                        ],
                                        namedArgs: {
                                          'worldId': value.$3,
                                        });
                                    widget.onUpdateLocations?.call();
                                  }
                                case LocationPopUpMenuItems.delete:
                                  final value = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => ConfirmDialog(
                                        description: engine
                                            .locale('dangerOperationPrompt')),
                                  );
                                  if (value != true) return;
                                  final location =
                                      GameData.game['locations'][dataId];
                                  engine.hetu.invoke('removeLocation',
                                      positionalArgs: [location]);
                                  _updateLocations();
                              }
                            });
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
                    child: fluent.FlyoutTarget(
                      controller: _createObjectFlyoutController,
                      child: fluent.FilledButton(
                        onPressed: () {
                          showFluentMenu(
                            controller: _createObjectFlyoutController,
                            items: {
                              engine.locale('portal'):
                                  CreateObjectPopUpMenuItems.portal,
                              engine.locale('worldPortal'):
                                  CreateObjectPopUpMenuItems.worldPortal,
                              engine.locale('character'):
                                  CreateObjectPopUpMenuItems.character,
                              engine.locale('treasureBox'):
                                  CreateObjectPopUpMenuItems.treasureBox,
                              '___': null,
                              engine.locale('custom'):
                                  CreateObjectPopUpMenuItems.custom,
                            },
                            onSelectedItem:
                                (CreateObjectPopUpMenuItems item) async {
                              fluent.Flyout.of(context).close();
                              final source = switch (item) {
                                CreateObjectPopUpMenuItems.custom =>
                                  kMapObjectSourceTemplate,
                                CreateObjectPopUpMenuItems.portal =>
                                  kMapObjectPortalSourceTemplate,
                                CreateObjectPopUpMenuItems.worldPortal =>
                                  kMapObjectWorldPortalSourceTemplate,
                                CreateObjectPopUpMenuItems.character =>
                                  kMapObjectCharacterSourceTemplate,
                                CreateObjectPopUpMenuItems.treasureBox =>
                                  kMapObjectTreasureBoxSourceTemplate,
                              };
                              final result = await showDialog(
                                  context: context,
                                  builder: (context) => InputDescriptionDialog(
                                        title: engine.locale('createObject'),
                                        description: source,
                                      ));
                              if (result == null) return;
                              final jsonData = json5Decode(result);
                              if (jsonData != null && jsonData.isNotEmpty) {
                                final mapObject = engine.hetu.interpreter
                                    .createStructfromJSON(jsonData);
                                engine.hetu.invoke('addObject',
                                    positionalArgs: [mapObject]);
                                _updateObjects();
                              }
                            },
                          );
                        },
                        child: Text(engine.locale('createObject')),
                      ),
                    ),
                  ),
                  SizedBox(
                    height: widget.size.height - 175,
                    child: GameEntityListView(
                      columns: _kObjectColumns,
                      tableData: _mapObjectsTableData,
                      onItemPressed: (position, dataId) {
                        _editObject(dataId);
                      },
                      onItemSecondaryPressed: (position, dataId) {
                        showFluentMenu(
                          position: position,
                          items: {
                            engine.locale('edit'): ObjectPopUpMenuItems.edit,
                            '___': null,
                            engine.locale('delete'):
                                ObjectPopUpMenuItems.delete,
                          },
                          onSelectedItem: (item) async {
                            switch (item) {
                              case ObjectPopUpMenuItems.edit:
                                _editObject(dataId);
                              case ObjectPopUpMenuItems.delete:
                                final value = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => ConfirmDialog(
                                      description: engine
                                          .locale('dangerOperationPrompt')),
                                );
                                if (value == null) return;
                                engine.hetu.invoke('removeObjectById',
                                    positionalArgs: [dataId]);
                                _updateObjects();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Row(
                  //   mainAxisAlignment: MainAxisAlignment.center,
                  //   children: [
                  //     Padding(
                  //       padding: const EdgeInsets.only(top: 5.0, right: 5.0),
                  //       child: fluent.FilledButton(
                  //         onPressed: () {
                  //           final count = engine.hetu.invoke('generateZone',
                  //               positionalArgs: [worldData]);
                  //           engine.hetu.invoke('nameZones',
                  //               positionalArgs: [worldData]);
                  //           GameDialogContent.show(
                  //             context,
                  //             engine.locale(
                  //               'generatedZone',
                  //               interpolations: [count],
                  //             ),
                  //           );
                  //           loadZoneColors();
                  //         },
                  //         child: Text(engine.locale('generateZone')),
                  //       ),
                  //     ),
                  //     Padding(
                  //       padding: const EdgeInsets.only(top: 5.0),
                  //       child: fluent.FilledButton(
                  //         onPressed: () {},
                  //         child: Text(engine.locale('createZone')),
                  //       ),
                  //     ),
                  //   ],
                  // ),
                  SizedBox(
                    height: widget.size.height - 175,
                    child: GameEntityListView(
                      columns: _kZoneColumns,
                      tableData: _zonesTableData,
                      onItemPressed: (position, dataId) {
                        _editZone(dataId);
                      },
                      onItemSecondaryPressed: (position, dataId) {
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
