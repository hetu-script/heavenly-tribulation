import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../game/ui.dart';
import '../../game/data.dart';
import 'site_card.dart';
import 'edit_location_basics.dart';
import 'edit_npc_basics.dart';
import '../common.dart';
import '../../game/logic.dart';
import '../../game/common.dart';
import '../game_entity_listview.dart';
import '../character/profile.dart';
import '../ui/menu_builder.dart';
import '../ui/close_button2.dart';

enum NpcOperation {
  create,
  delete,
  edit,
}

enum SiteOperation {
  edit,
  delete,
}

class LocationView extends StatefulWidget {
  const LocationView({
    super.key,
    this.locationId,
    this.location,
    this.mode = InformationViewMode.view,
  });

  final String? locationId;
  final dynamic location;
  final InformationViewMode mode;

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView>
    with SingleTickerProviderStateMixin {
  final List<Widget> _siteCards = [];

  static late List<Tab> tabs;
  final List<List<String>> _charactersTableData = [];
  late final TabController _tabController;
  final fluent.FlyoutController _siteMenuController = fluent.FlyoutController();

  late final dynamic _locationData;
  dynamic _ownerData;
  dynamic _atLocation;

  bool get isCity => _locationData['category'] == 'city';
  bool get isSite => _locationData['category'] == 'site';
  bool get isEditMode => widget.mode == InformationViewMode.edit;
  bool get isManageMode => widget.mode == InformationViewMode.manage;

  @override
  void dispose() {
    super.dispose();

    _tabController.dispose();
    _siteMenuController.dispose();
  }

  @override
  void initState() {
    super.initState();

    assert(widget.location != null || widget.locationId != null,
        'LocationView must have either organizationId or organization data.');
    if (widget.location != null) {
      _locationData = widget.location!;
    } else if (widget.locationId != null) {
      _locationData = GameData.game['locations'][widget.locationId];
    }
    assert(_locationData != null);

    final ownerId = _locationData['ownerId'];
    _ownerData = GameData.game['characters'][ownerId];

    Iterable residents = [];

    if (_locationData['category'] == 'site') {
      _atLocation = GameData.game['locations'][_locationData['atLocationId']];
    } else if (_locationData['category'] == 'city') {
      residents = (_locationData['residents'] as Iterable)
          .map((id) => GameData.game['characters'][id]);

      for (final character in residents) {
        final row = GameLogic.getCharacterInformationRow(character);
        _charactersTableData.add(row);
      }
    }

    tabs = [
      Tab(text: engine.locale('information')),
      Tab(text: '${engine.locale('residents')}(${residents.length})'),
    ];

    _tabController = TabController(length: 2, vsync: this);

    _updateSitesData();
  }

  void _saveData() {}

  void _updateSitesData() {
    _siteCards.clear();
    for (final siteId in _locationData['sites']) {
      final siteData = GameData.game['locations'][siteId];
      final siteCard = SiteCard(
        siteData: siteData,
        imagePath: siteData['image'],
        onTap: (siteId) {
          showDialog(
            context: context,
            builder: (context) {
              return LocationView(
                locationId: siteId,
                mode: widget.mode,
              );
            },
          );
        },
        onSecondaryTap: (siteId, details) {
          showFluentMenu(
              position: details.globalPosition,
              items: {
                engine.locale('edit'): SiteOperation.edit,
                engine.locale('delete'): SiteOperation.delete,
              },
              onSelectedItem: (SiteOperation item) {
                switch (item) {
                  case SiteOperation.edit:
                    showDialog(
                      context: context,
                      builder: (context) {
                        return LocationView(
                          locationId: siteId,
                          mode: widget.mode,
                        );
                      },
                    );
                    break;
                  case SiteOperation.delete:
                    final siteData = GameData.game['locations'][siteId];
                    assert(siteData != null, 'location not found, id: $siteId');
                    engine.hetu.invoke(
                      'removeLocation',
                      positionalArgs: [siteData],
                    );
                    _updateSitesData();
                    break;
                }
              });
        },
      );
      _siteCards.add(siteCard);
    }
    _siteCards.sort((a, b) {
      final aData = (a as SiteCard).siteData;
      final bData = (b as SiteCard).siteData;
      return bData['priority'].compareTo(aData['priority']);
    });
    setState(() {});
  }

  void setNpc() async {
    if (_locationData['npcId'] == null) {
      final npcData = await showDialog(
        context: context,
        builder: (context) {
          return EditNpcBasics(
            atLocation: _locationData,
            id: _locationData['id'] + '_npc',
            nameId: 'servant',
            icon: 'illustration/npc/servant_head.png',
            illustration: 'illustration/npc/servant.png',
          );
        },
      );
      if (npcData == null) return;
      _locationData['npcId'] = npcData['id'];
    } else {
      final npcData = GameData.game['npcs'][_locationData['npcId']];
      assert(npcData != null);
      await showDialog(
        context: context,
        builder: (context) {
          return EditNpcBasics(
            id: npcData['id'],
            nameId: npcData['nameId'],
            icon: npcData['icon'],
            illustration: npcData['illustration'],
            useCustomLogic: npcData['useCustomLogic'] ?? false,
            atLocation: _locationData,
          );
        },
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Set<String> buildableSites = {};
    if (isCity && isManageMode) {
      final Set<String> existedSites = {};
      for (final siteId in _locationData['sites']) {
        final siteData = GameData.game['locations'][siteId];
        if (siteData != null) {
          existedSites.add(siteData['kind']);
        }
      }
      for (final siteKind in kSiteKindsBuildable) {
        if (existedSites.contains(siteKind)) {
          continue;
        }
        buildableSites.add(siteKind);
      }
    }

    final mainPanel = Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        children: [
          Container(
            width: 800.0,
            height: isCity ? 440.0 : 488.0,
            alignment: Alignment.topLeft,
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120.0,
                          height: 35.0,
                          child: Text('${engine.locale('manager')}:'),
                        ),
                        Text('${_ownerData?['name'] ?? engine.locale('none')}'),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120.0,
                          height: 35.0,
                          child: Text('${engine.locale('development')}:'),
                        ),
                        Text('${_locationData['development']}'),
                      ],
                    ),
                    if (isCity) ...[
                      if (isEditMode)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 120.0,
                              height: 35.0,
                              child: Text('${engine.locale('isDiscovered')}: '),
                            ),
                            Container(
                              width: 20.0,
                              height: 22.0,
                              padding: const EdgeInsets.only(top: 2),
                              child: fluent.Checkbox(
                                checked: _locationData['isDiscovered'] ?? false,
                                // activeColor: Colors.white,
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    setState(() {
                                      _locationData['isDiscovered'] = value;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120.0,
                            height: 35.0,
                            child: Text('${engine.locale('worldPosition')}:'),
                          ),
                          SizedBox(
                            width: 120.0,
                            height: 35.0,
                            child: Text(
                                '${_locationData['worldPosition']['left']}, ${_locationData['worldPosition']['top']}'),
                          ),
                        ],
                      ),
                    ],
                    if (isEditMode)
                      SizedBox(
                        height: 35.0,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120.0,
                              child: Text('NPC:'),
                            ),
                            fluent.FilledButton(
                              onPressed: () {
                                setNpc();
                              },
                              child: Text(_locationData['npcId'] ??
                                  engine.locale('setNpc')),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Container(
                      width: 770,
                      height: 140,
                      margin: const EdgeInsets.only(top: 10.0, bottom: 10.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: GameUI.outlineColor,
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Wrap(
                            // spacing: 4.0, // gap between adjacent chips
                            runSpacing: 4.0, // gap between lines
                            children: _siteCards,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isEditMode)
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: fluent.FilledButton(
                    onPressed: () async {
                      final value = await showDialog(
                        context: context,
                        builder: (context) => EditLocationBasics(
                          id: _locationData['id'],
                          category: _locationData['category'],
                          kind: _locationData['kind'],
                          name: _locationData['name'],
                          image: _locationData['image'],
                          background: _locationData['background'],
                          atLocation: _atLocation,
                          createNpc: _locationData['npcId'] != null,
                          allowEditCategory: false,
                        ),
                      );
                      if (value == null) return;
                      final (
                        id,
                        category,
                        kind,
                        name,
                        image,
                        background,
                        createNpc,
                      ) = value;
                      _locationData['category'] = category;
                      _locationData['kind'] = kind;
                      _locationData['name'] = name;
                      _locationData['image'] = image;
                      _locationData['background'] = background;

                      if (id != null && id != _locationData['id']) {
                        final oldId = _locationData['id'];
                        GameData.game['locations'].remove(oldId);
                        GameData.game['locations'][id] = _locationData;

                        if (_locationData['category'] == 'site') {
                          final atLocation = GameData.game['locations']
                              [_locationData['atLocationId']];
                          assert(atLocation != null);
                          atLocation['sites'].remove(oldId);
                          atLocation['sites'].add(id);
                        }

                        _locationData['id'] = id;
                      }

                      if (createNpc) {
                        if (_locationData['npcId'] == null) {
                          final npcData = engine.hetu.invoke(
                            'Npc',
                            namedArgs: {
                              'id': _locationData['id'] + '_npc',
                              'nameId': 'servant',
                              'icon': 'illustration/npc/servant_head.png',
                              'illustration': 'illustration/npc/servant.png',
                              'atLocationId': _locationData['id'],
                            },
                          );
                          _locationData['npcId'] = npcData['id'];
                        }
                      } else {
                        if (_locationData['npcId'] != null) {
                          _locationData['npcId'] = null;
                        }
                      }
                      setState(() {});
                    },
                    child: Text(engine.locale('editIdAndImage')),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: fluent.FilledButton(
                    onPressed: () async {
                      final value = await showDialog(
                        context: context,
                        builder: (context) {
                          return EditLocationBasics(
                            category: 'site',
                            kind: _locationData['category'] == 'site'
                                ? 'custom'
                                : null,
                            atLocation: _locationData,
                            allowEditCategory: false,
                            allowEditKind: _locationData['category'] == 'city',
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
                        createNpc,
                      ) = value;
                      final location = engine.hetu.invoke(
                        'Location',
                        namedArgs: {
                          'category': 'site',
                          'kind': kind,
                          'id': id,
                          'name': name,
                          'image': image,
                          'background': background,
                          'atLocation': _locationData,
                          'createNpc': createNpc,
                          'organizationId': _locationData['organizationId'],
                        },
                      );
                      await showDialog(
                          context: context,
                          builder: (context) {
                            return LocationView(
                              location: location,
                            );
                          });
                      _updateSitesData();
                    },
                    child: Text(engine.locale('addSite')),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                  child: fluent.FilledButton(
                    onPressed: () {
                      _saveData();
                      Navigator.of(context).pop(true);
                    },
                    child: Text(engine.locale('confirm')),
                  ),
                ),
              ],
            ),
          if (isCity && isManageMode)
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: fluent.FlyoutTarget(
                    controller: _siteMenuController,
                    child: fluent.FilledButton(
                      onPressed: () async {
                        showFluentMenu(
                          controller: _siteMenuController,
                          placementMode: fluent.FlyoutPlacementMode.topLeft,
                          items: {
                            for (final siteKind in buildableSites)
                              engine.locale(siteKind): siteKind
                          },
                          onSelectedItem: (siteKind) {},
                        );
                      },
                      child: Text(engine.locale('buildSite')),
                    ),
                  ),
                ),
              ],
            )
        ],
      ),
    );

    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 800.0,
      height: 600.0,
      // height: widget.mode != InformationViewMode.view ? 650.0 : 600.0,
      child: _locationData['category'] == 'city'
          ? Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text(_locationData['name']),
                actions: const [CloseButton2()],
                bottom: TabBar(
                  controller: _tabController,
                  tabs: tabs,
                ),
              ),
              body: TabBarView(
                controller: _tabController,
                children: [
                  mainPanel,
                  GameEntityListView(
                    columns: kInformationViewCharacterColumns,
                    tableData: _charactersTableData,
                    onItemPressed: (position, dataId) {
                      showDialog(
                        context: context,
                        builder: (context) =>
                            CharacterProfileView(characterId: dataId),
                      );
                    },
                  ),
                ],
              ),
            )
          : Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text(_locationData['name']),
                actions: const [CloseButton2()],
              ),
              body: mainPanel,
            ),
    );
  }
}
