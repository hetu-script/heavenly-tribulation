import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/widgets/location/edit_location_basics.dart';
import 'package:json5/json5.dart';
import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/responsive_view.dart';

import '../../../engine.dart';
import '../../../game/ui.dart';
import '../../../widgets/game_entity_listview.dart';
import '../../../widgets/character/memory.dart';
import '../../../widgets/location/location.dart';
import '../../../widgets/organization/organization.dart';
import '../../../widgets/menu_item_builder.dart';
import '../../../widgets/character/details.dart';
import '../../../widgets/character/profile.dart';
import '../../../widgets/dialog/input_world_position.dart';
import '../../../widgets/common.dart';
import '../../../widgets/dialog/input_string.dart';
import '../../../widgets/dialog/confirm.dart';
import '../../../widgets/character/edit_character_event_flags.dart';
import '../../../widgets/organization/edit_organization_basic.dart';
// import 'edit_map_object.dart';
import '../../../widgets/dialog/input_description.dart';
import '../../../state/selected_tile.dart';
// import '../../../game/data.dart';
import '../../../game/logic.dart';
import '../../game_dialog/game_dialog_content.dart';
import '../../../widgets/character/edit_character_basics.dart';

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
  useCustomLogic: true,
  blockMove: true,
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
  worldId: 'main',
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
  isDiscovered: true,
  // isHidden: false,
  // overlaySprite: {
  //   sprite: 'sprite.png',
  //   animation: {
  //     path: "object/animation/fishZone.png",
  //   },
  // },
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
  items: [
    {
      category: 'material',
      kind: 'money',
      amount: 100,
    },
    {
      category: 'prototype',
      kind: 'shard',
    },
    {
      category: 'equipment',
      kind: 'sword',
      rarity: 'basic',
      rank: 0,
      level: 0,
    },
    {
      category: 'cardpack',
      kind: 'punch',
      genre: null,
      rank: 0,
    },
  ]
}
''';

enum CharacterPopUpMenuItems {
  setAsHero,
  setWorldMap,
  setWorldMapPosition,
  clearWorldMapPosition,
  clearLocation,
  setLocation,
  clearHome,
  setHome,
  checkProfile,
  checkEventFlags,
  checkEquipments,
  checkMemory,
  delete,
}

List<PopupMenuEntry<CharacterPopUpMenuItems>> buildCharacterPopUpMenuItems(
    {void Function(CharacterPopUpMenuItems item)? onSelectedItem}) {
  return <PopupMenuEntry<CharacterPopUpMenuItems>>[
    buildMenuItem(
      item: CharacterPopUpMenuItems.checkProfile,
      name: engine.locale('checkProfile'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.checkEventFlags,
      name: engine.locale('checkEventFlags'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.checkEquipments,
      name: engine.locale('checkEquipments'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.checkMemory,
      name: engine.locale('checkMemory'),
      onSelectedItem: onSelectedItem,
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: CharacterPopUpMenuItems.setAsHero,
      name: engine.locale('setAsHero'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.clearWorldMapPosition,
      name: engine.locale('clearWorldMapPosition'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.setWorldMap,
      name: engine.locale('setWorldMap'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.setWorldMapPosition,
      name: engine.locale('setWorldMapPosition'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.clearHome,
      name: engine.locale('clearHome'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.setHome,
      name: engine.locale('setHome'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.clearLocation,
      name: engine.locale('clearLocation'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CharacterPopUpMenuItems.setLocation,
      name: engine.locale('setLocation'),
      onSelectedItem: onSelectedItem,
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: CharacterPopUpMenuItems.delete,
      name: engine.locale('delete'),
      onSelectedItem: onSelectedItem,
    ),
  ];
}

enum CreateLocationPopUpMenuItems {
  cityInland,
  cityHarbor,
  cityIsland,
  cityMountain,

  siteArena,
  siteLibrary,
  siteTradingHouse,
  siteAuctionHouse,

  siteMine,
  siteTimberland,
  siteFarmland,
  siteHuntingground,
  siteFishery,
  siteNursery,
  siteZoo,

  siteWorkshop,
  siteArraylab,
  siteRuneLab,
  siteAlchemyLab,
  siteIllusionAltar,
  sitePsychicAltar,
  siteDivinationAltar,
  siteTheurgyAltar,
}

List<PopupMenuEntry<CreateLocationPopUpMenuItems>>
    buildCreateLocationPopUpMenuItems(
        {void Function(CreateLocationPopUpMenuItems item)? onSelectedItem}) {
  return <PopupMenuEntry<CreateLocationPopUpMenuItems>>[
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.cityInland,
      name: engine.locale('inland'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.cityHarbor,
      name: engine.locale('harbor'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.cityIsland,
      name: engine.locale('island'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.cityMountain,
      name: engine.locale('mountain'),
      onSelectedItem: onSelectedItem,
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteArena,
      name: engine.locale('arena'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteLibrary,
      name: engine.locale('library'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteTradingHouse,
      name: engine.locale('tradinghouse'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteAuctionHouse,
      name: engine.locale('auctionhouse'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteWorkshop,
      name: engine.locale('workshop'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteMine,
      name: engine.locale('mine'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteTimberland,
      name: engine.locale('timberland'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteFarmland,
      name: engine.locale('farmland'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteHuntingground,
      name: engine.locale('huntingground'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteFishery,
      name: engine.locale('fishery'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteNursery,
      name: engine.locale('nursery'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteZoo,
      name: engine.locale('zoo'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteArraylab,
      name: engine.locale('arraylab'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteRuneLab,
      name: engine.locale('scrolllab'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteAlchemyLab,
      name: engine.locale('alchemylab'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteIllusionAltar,
      name: engine.locale('illusionaltar'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.sitePsychicAltar,
      name: engine.locale('psychicaltar'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteDivinationAltar,
      name: engine.locale('divinationaltar'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: CreateLocationPopUpMenuItems.siteTheurgyAltar,
      name: engine.locale('theurgyaltar'),
      onSelectedItem: onSelectedItem,
    ),
  ];
}

enum LocationPopUpMenuItems {
  checkInformation,
  delete,
}

List<PopupMenuEntry<LocationPopUpMenuItems>> buildLocationPopUpMenuItems(
    {void Function(LocationPopUpMenuItems item)? onSelectedItem}) {
  return <PopupMenuEntry<LocationPopUpMenuItems>>[
    buildMenuItem(
      item: LocationPopUpMenuItems.checkInformation,
      name: engine.locale('checkInformation'),
      onSelectedItem: onSelectedItem,
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: LocationPopUpMenuItems.delete,
      name: engine.locale('delete'),
      onSelectedItem: onSelectedItem,
    ),
  ];
}

enum CreateObjectPopUpMenuItems {
  custom,
  portal,
  worldPortal,
  character,
  treasureBox,
}

List<PopupMenuEntry<CreateObjectPopUpMenuItems>>
    buildCreateObjectPopUpMenuItems(
        {void Function(CreateObjectPopUpMenuItems item)? onSelectedItem}) {
  return <PopupMenuEntry<CreateObjectPopUpMenuItems>>[
    buildSubMenuItem(
      items: {
        engine.locale('portal'): CreateObjectPopUpMenuItems.portal,
        engine.locale('worldPortal'): CreateObjectPopUpMenuItems.worldPortal,
        engine.locale('character'): CreateObjectPopUpMenuItems.character,
        engine.locale('treasureBox'): CreateObjectPopUpMenuItems.treasureBox,
      },
      name: engine.locale('preset'),
      onSelectedItem: onSelectedItem,
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: CreateObjectPopUpMenuItems.custom,
      name: engine.locale('custom'),
      onSelectedItem: onSelectedItem,
    ),
  ];
}

enum ObjectPopUpMenuItems {
  edit,
  delete,
}

List<PopupMenuEntry<ObjectPopUpMenuItems>> buildObjectPopUpMenuItems(
    {void Function(ObjectPopUpMenuItems item)? onSelectedItem}) {
  return <PopupMenuEntry<ObjectPopUpMenuItems>>[
    buildMenuItem(
      item: ObjectPopUpMenuItems.edit,
      name: engine.locale('edit'),
      onSelectedItem: onSelectedItem,
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: ObjectPopUpMenuItems.delete,
      name: engine.locale('delete'),
      onSelectedItem: onSelectedItem,
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
  });

  final Size size;

  final void Function()? onUpdateCharacters;
  final void Function()? onUpdateLocations;

  @override
  State<EntityListPanel> createState() => _EntityListPanelState();
}

class _EntityListPanelState extends State<EntityListPanel>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Scene? _scene;

  late List<Widget> _tabs;

  final GlobalKey _createLocationButtonKey = GlobalKey(),
      _createObjectButtonKey = GlobalKey();

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
    _tabs = [
      Tab(
        icon: const Icon(Icons.person),
        text: engine.locale('character'),
      ),
      Tab(
        icon: const Icon(Icons.groups),
        text: engine.locale('organization'),
      ),
      Tab(
        icon: const Icon(Icons.location_city),
        text: engine.locale('location'),
      ),
      Tab(
        icon: const Icon(Icons.public),
        text: engine.locale('zone'),
      ),
      Tab(
        icon: const Icon(Icons.place),
        text: engine.locale('mapObject'),
      ),
    ];

    // final worldSizeData = engine.hetu.invoke('getWorldSize');
    // _worldWidth = worldSizeData['width'];
    // _worldHeight = worldSizeData['height'];

    _updateCharacters();
    _updateOrganizations();
    _updateLocations();
    _updateZones();
    _updateObjects();
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
    final data =
        engine.hetu.invoke('getCharacterById', positionalArgs: [dataId]);

    final result = await showDialog(
      context: context,
      builder: (context) => CharacterProfileView(
        characterData: data,
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
      rowData.add(org['characterIds'].length.toString());
      // 多存一个隐藏的 id 信息，用于点击事件
      rowData.add(org['id']);
      _organizationsTableData.add(rowData);
    }
    setState(() {});
  }

  void _editOrganization(String dataId) {
    showDialog(
      context: context,
      builder: (context) => OrganizationView(
        organizationId: dataId,
        mode: InformationViewMode.edit,
      ),
    ).then((value) {
      if (value == true) {
        _updateOrganizations();
      }
    });
  }

  void _updateLocations() {
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
    setState(() {});
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
    final obj = engine.hetu.invoke('getObjectById', positionalArgs: [dataId]);
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
        length: _tabs.length,
        child: Scaffold(
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
                      onPressed: () async {
                        final value = await showDialog(
                            context: context,
                            builder: (context) {
                              return EditCharacterBasics();
                            });
                        if (value == null) return;
                        final (
                          id,
                          name,
                          surName,
                          isFemale,
                          skin,
                          icon,
                          illustration
                        ) = value;
                        final characterData =
                            engine.hetu.invoke('Character', namedArgs: {
                          'id': id,
                          'name': name,
                          'surName': surName,
                          'isFemale': isFemale,
                          'skin': skin,
                          'icon': icon,
                          'illustration': illustration,
                        });
                        if (!context.mounted) return;
                        await showDialog(
                            context: context,
                            builder: (context) {
                              return CharacterProfileView(
                                mode: InformationViewMode.edit,
                                characterData: characterData,
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
                  //   child: ElevatedButton(
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
                      onItemPressed: (buttons, position, dataId) {
                        _editCharacter(dataId);
                      },
                      onItemSecondaryPressed: (buttons, position, characterId) {
                        final menuPosition = RelativeRect.fromLTRB(
                            position.dx, position.dy, position.dx, 0.0);
                        final items = buildCharacterPopUpMenuItems(
                            onSelectedItem: (item) async {
                          switch (item) {
                            case CharacterPopUpMenuItems.checkProfile:
                              _editCharacter(characterId);
                            case CharacterPopUpMenuItems.checkEventFlags:
                              final charData = engine.hetu.invoke(
                                  'getCharacterById',
                                  positionalArgs: [characterId]);
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
                                    CharacterDetails(characterId: characterId),
                              );
                            case CharacterPopUpMenuItems.checkMemory:
                              showDialog(
                                context: context,
                                builder: (context) => CharacterMemoryView(
                                  characterId: characterId,
                                  mode: InformationViewMode.edit,
                                ),
                              );
                            case CharacterPopUpMenuItems.setAsHero:
                              engine.hetu.invoke('setHeroId',
                                  positionalArgs: [characterId]);
                            case CharacterPopUpMenuItems.clearWorldMapPosition:
                              final charData = engine.hetu.invoke(
                                  'getCharacterById',
                                  positionalArgs: [characterId]);
                              charData.remove('worldPosition');
                              charData.remove('worldId');
                              widget.onUpdateCharacters?.call();
                            case CharacterPopUpMenuItems.setWorldMap:
                              final worldId = await GameLogic.selectWorldId();
                              if (worldId != null) {
                                final charData = engine.hetu.invoke(
                                    'getCharacterById',
                                    positionalArgs: [characterId]);
                                if (charData['worldId'] != worldId) {
                                  charData['worldId'] = worldId;
                                  widget.onUpdateCharacters?.call();
                                }
                              }
                            case CharacterPopUpMenuItems.setWorldMapPosition:
                              final charData = engine.hetu.invoke(
                                  'getCharacterById',
                                  positionalArgs: [characterId]);
                              final charPosData = charData['worldPosition'];
                              final selectedTile = context
                                  .read<SelectedTileState>()
                                  .currentTerrain;
                              final currentMapId =
                                  context.read<SamsaraEngine>().scene?.id;
                              int? left =
                                  charPosData?['left'] ?? selectedTile?.left;
                              int? top =
                                  charPosData?['top'] ?? selectedTile?.top;
                              final value = await InputWorldPositionDialog.show(
                                context: context,
                                // maxX: _worldWidth,
                                // maxY: _worldHeight,
                                defaultX: left,
                                defaultY: top,
                                worldId: currentMapId,
                              );
                              if (value == null) return;
                              if (value.$1 != charPosData?['left'] ||
                                  value.$2 != charPosData?['top'] ||
                                  value.$3 != charData?['worldId']) {
                                engine.hetu.invoke('setCharacterWorldPosition',
                                    positionalArgs: [
                                      charData,
                                      value.$1,
                                      value.$2,
                                    ],
                                    namedArgs: {
                                      'worldId': value.$3,
                                    });
                                widget.onUpdateCharacters?.call();
                              }
                            case CharacterPopUpMenuItems.clearHome:
                              final charData = engine.hetu.invoke(
                                  'getCharacterById',
                                  positionalArgs: [characterId]);
                              engine.hetu.invoke('clearCharacterHomeLocations',
                                  positionalArgs: [charData]);
                            case CharacterPopUpMenuItems.setHome:
                              InputStringDialog.show(context: context)
                                  .then((locationId) {
                                if (locationId != null) {
                                  final locData = engine.hetu.invoke(
                                      'getLocationById',
                                      positionalArgs: [locationId]);
                                  if (locData == null) {
                                    if (context.mounted) {
                                      GameDialogContent.show(context,
                                          '输入的据点 id [$locationId] 不存在！');
                                    }
                                  } else {
                                    final charData = engine.hetu.invoke(
                                        'getCharacterById',
                                        positionalArgs: [characterId]);
                                    engine.hetu.invoke(
                                        'setCharacterHomeLocation',
                                        positionalArgs: [
                                          charData,
                                          locData
                                        ],
                                        namedArgs: {
                                          'incurIncident': false,
                                        });
                                  }
                                }
                              });
                            case CharacterPopUpMenuItems.clearLocation:
                              final charData = engine.hetu.invoke(
                                  'getCharacterById',
                                  positionalArgs: [characterId]);
                              charData.remove('locationId');
                            case CharacterPopUpMenuItems.setLocation:
                              InputStringDialog.show(context: context)
                                  .then((value) {
                                if (value != null) {
                                  final charData = engine.hetu.invoke(
                                      'getCharacterById',
                                      positionalArgs: [characterId]);
                                  engine.hetu.invoke('setCharacterLocationId',
                                      positionalArgs: [charData, value]);
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
                              showDialog<bool>(
                                context: context,
                                builder: (context) => ConfirmDialog(
                                    description:
                                        engine.locale('dangerOperationPrompt')),
                              ).then((bool? value) {
                                if (value == true) {
                                  engine.hetu.invoke('removeCharacterById',
                                      positionalArgs: [characterId]);
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
                        showDialog(
                            context: context,
                            builder: (context) {
                              return const EditOrganizationBasics();
                            });
                      },
                      child: Text(engine.locale('createOrganization')),
                    ),
                  ),
                  SizedBox(
                    height: widget.size.height - 175,
                    child: GameEntityListView(
                        columns: _kOrganizationColumns,
                        tableData: _organizationsTableData,
                        onItemSecondaryPressed: (buttons, position, dataId) {}),
                  ),
                ],
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 5.0, right: 10.0),
                    child: ElevatedButton(
                      key: _createLocationButtonKey,
                      onPressed: () async {
                        final value = await showDialog(
                            context: context,
                            builder: (context) {
                              return EditLocationBasics();
                            });
                        if (value == null) return;
                        if (!context.mounted) return;
                        final selectedTile =
                            context.read<SelectedTileState>().currentTerrain;
                        if (selectedTile == null) {
                          GameDialogContent.show(
                              context, engine.locale('selectedTilePrompt'));
                          return;
                        }
                        dynamic atTerrain = selectedTile.data;
                        dynamic atLocation;
                        if (selectedTile.locationId != null) {
                          atLocation = engine.hetu.invoke('getLocationById',
                              positionalArgs: [selectedTile.locationId]);
                        }
                        final (category, kind, id, name, image, background) =
                            value;
                        final locationData = engine.hetu.invoke(
                          'Location',
                          namedArgs: {
                            'category': category,
                            'kind': kind,
                            'id': id,
                            'name': name,
                            'image': image,
                            'background': background,
                            'atTerrain': atTerrain,
                            if (category == 'site') 'atLocation': atLocation,
                          },
                        );
                        if (!context.mounted) return;
                        await showDialog(
                            context: context,
                            builder: (context) {
                              return LocationView(
                                mode: InformationViewMode.edit,
                                locationData: locationData,
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
                      onItemPressed: (buttons, position, dataId) {
                        _editLocation(dataId);
                      },
                      onItemSecondaryPressed: (buttons, position, dataId) {
                        final menuPosition = RelativeRect.fromLTRB(
                            position.dx, position.dy, position.dx, 0.0);
                        final items =
                            buildLocationPopUpMenuItems(onSelectedItem: (item) {
                          switch (item) {
                            case LocationPopUpMenuItems.checkInformation:
                              _editLocation(dataId);
                            case LocationPopUpMenuItems.delete:
                              showDialog<bool>(
                                context: context,
                                builder: (context) => ConfirmDialog(
                                    description:
                                        engine.locale('dangerOperationPrompt')),
                              ).then((bool? value) {
                                engine.hetu.invoke('removeLocationById',
                                    positionalArgs: [dataId]);
                                _updateLocations();
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
                      onPressed: () {},
                      child: Text(engine.locale('createZone')),
                    ),
                  ),
                  SizedBox(
                    height: widget.size.height - 175,
                    child: GameEntityListView(
                      columns: _kZoneColumns,
                      tableData: _zonesTableData,
                      onItemSecondaryPressed: (buttons, position, dataId) {
                        // showDialog(
                        //   context: context,
                        //   builder: (context) => ZoneView(zoneId: dataId),
                        // );
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
                      key: _createObjectButtonKey,
                      onPressed: () {
                        final renderRect = getRenderRect(
                            _createObjectButtonKey.currentContext!);
                        final menuPosition = RelativeRect.fromLTRB(
                            renderRect.right,
                            renderRect.top,
                            renderRect.right,
                            0.0);
                        final items = buildCreateObjectPopUpMenuItems(
                            onSelectedItem: (item) async {
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
                        });
                        showMenu(
                          context: context,
                          position: menuPosition,
                          items: items,
                        );
                      },
                      child: Text(engine.locale('createObject')),
                    ),
                  ),
                  SizedBox(
                    height: widget.size.height - 175,
                    child: GameEntityListView(
                      columns: _kObjectColumns,
                      tableData: _mapObjectsTableData,
                      onItemPressed: (buttons, position, dataId) {
                        _editObject(dataId);
                      },
                      onItemSecondaryPressed: (buttons, position, dataId) {
                        final menuPosition = RelativeRect.fromLTRB(
                            position.dx, position.dy, position.dx, 0.0);
                        final items =
                            buildObjectPopUpMenuItems(onSelectedItem: (item) {
                          switch (item) {
                            case ObjectPopUpMenuItems.edit:
                              _editObject(dataId);
                            case ObjectPopUpMenuItems.delete:
                              showDialog<bool>(
                                context: context,
                                builder: (context) => ConfirmDialog(
                                    description:
                                        engine.locale('dangerOperationPrompt')),
                              ).then((bool? value) {
                                engine.hetu.invoke('removeObjectById',
                                    positionalArgs: [dataId]);
                                _updateObjects();
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
            ],
          ),
        ),
      ),
    );
  }
}
