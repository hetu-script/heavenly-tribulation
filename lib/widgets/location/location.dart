import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../ui.dart';
import '../../data/game.dart';
import 'site_card.dart';
import 'edit_location_basics.dart';
import 'edit_npc_basics.dart';
import '../common.dart';
import '../../data/common.dart';
import '../entity_table.dart';
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

  late final dynamic _location;
  dynamic _owner;
  dynamic _atLocation;

  late final bool isCity;
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
      _location = widget.location!;
    } else if (widget.locationId != null) {
      _location = GameData.getLocation(widget.locationId);
    }
    assert(_location != null);
    isCity = _location['category'] == 'city';

    final ownerId = _location['ownerId'];
    // 这里的 owner 可能是 null
    _owner = GameData.game['characters'][ownerId];

    Iterable residents = [];

    if (isCity) {
      residents = (_location['residents'] as Iterable)
          .map((id) => GameData.getCharacter(id));

      for (final character in residents) {
        final row = GameData.getCharacterInformationRow(character);
        _charactersTableData.add(row);
      }
    } else {
      _atLocation = GameData.game['locations'][_location['atLocationId']];
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
    for (final siteId in _location['sites']) {
      final siteData = GameData.getLocation(siteId);
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
                    final siteData = GameData.getLocation(siteId);
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
    if (_location['npcId'] == null) {
      final npcData = await showDialog(
        context: context,
        builder: (context) {
          return EditNpcBasics(
            atLocation: _location,
            id: _location['id'] + '_npc',
            nameId: 'servant',
            icon: 'illustration/npc/servant_head.png',
            illustration: 'illustration/npc/servant.png',
          );
        },
      );
      if (npcData == null) return;
      _location['npcId'] = npcData['id'];
    } else {
      final npcData = GameData.game['npcs'][_location['npcId']];
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
            atLocation: _location,
          );
        },
      );
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final Set<String> buildableSites = {};
    String organizationName = engine.locale('none');
    if (isCity) {
      final organizationId = _location['organizationId'];
      if (organizationId != null) {
        final organizationData = GameData.getOrganization(organizationId);
        organizationName = organizationData['name'];
      }

      if (isManageMode) {
        final Set<String> existedSites = {};
        for (final siteId in _location['sites']) {
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
    }

    final mainPanel = Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Column(
        children: [
          Container(
            width: 1000.0,
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
                        Text('${_owner?['name'] ?? engine.locale('none')}'),
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
                        Text('${_location['development']}'),
                      ],
                    ),
                    if (isCity) ...[
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
                                '${_location['worldPosition']['left']}, ${_location['worldPosition']['top']}'),
                          ),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120.0,
                            height: 35.0,
                            child: Text('${engine.locale('organization')}:'),
                          ),
                          SizedBox(
                            width: 120.0,
                            height: 35.0,
                            child: Text(organizationName),
                          ),
                        ],
                      ),
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
                                checked: _location['isDiscovered'] ?? false,
                                // activeColor: Colors.white,
                                onChanged: (bool? value) {
                                  if (value != null) {
                                    setState(() {
                                      _location['isDiscovered'] = value;
                                    });
                                  }
                                },
                              ),
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
                              child: Text(_location['npcId'] ??
                                  engine.locale('setNpc')),
                            ),
                          ],
                        ),
                      ),
                    const Spacer(),
                    Container(
                      width: 970,
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
                          id: _location['id'],
                          category: _location['category'],
                          kind: _location['kind'],
                          name: _location['name'],
                          image: _location['image'],
                          background: _location['background'],
                          atLocation: _atLocation,
                          npcId: _location['npcId'],
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
                        npcId,
                      ) = value;
                      _location['category'] = category;
                      _location['kind'] = kind;
                      _location['name'] = name;
                      _location['image'] = image;
                      _location['background'] = background;
                      _location['npcId'] = npcId;

                      if (id != null && id != _location['id']) {
                        final oldId = _location['id'];
                        GameData.game['locations'].remove(oldId);
                        GameData.game['locations'][id] = _location;

                        if (_location['category'] == 'site') {
                          final atLocation =
                              GameData.getLocation(_location['atLocationId']);
                          atLocation['sites'].remove(oldId);
                          atLocation['sites'].add(id);
                        }

                        _location['id'] = id;
                      }

                      // if (createNpc) {
                      //   if (_location['npcId'] == null) {
                      //     final npcData = engine.hetu.invoke(
                      //       'Npc',
                      //       namedArgs: {
                      //         'id': _location['id'] + '_npc',
                      //         'nameId': 'servant',
                      //         'icon': 'illustration/npc/servant_head.png',
                      //         'illustration': 'illustration/npc/servant.png',
                      //         'atLocationId': _location['id'],
                      //       },
                      //     );
                      //     _location['npcId'] = npcData['id'];
                      //   }
                      // } else {
                      //   if (_location['npcId'] != null) {
                      //     _location['npcId'] = null;
                      //   }
                      // }
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
                            kind: isCity ? null : 'custom',
                            atLocation: _location,
                            allowEditCategory: false,
                            allowEditKind: isCity,
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
                        npcId,
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
                          'atLocation': _location,
                          'npcId': npcId,
                          'organizationId': _location['organizationId'],
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
      cursor: GameUI.cursor,
      backgroundColor: GameUI.backgroundColor,
      alignment: AlignmentDirectional.center,
      width: 1000.0,
      height: 600.0,
      // height: widget.mode != InformationViewMode.view ? 650.0 : 600.0,
      child: isCity
          ? Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: Text(_location['name']),
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
                  EntityTable(
                    columns: kEntityTableCharacterColumns,
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
                title: Text(_location['name']),
                actions: const [CloseButton2()],
              ),
              body: mainPanel,
            ),
    );
  }
}
