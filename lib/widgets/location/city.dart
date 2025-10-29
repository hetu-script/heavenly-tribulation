import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/label.dart';
import 'package:samsara/widgets/ui/mouse_region2.dart';

import '../../engine.dart';
import '../../ui.dart';
import '../../data/game.dart';
import 'site_card.dart';
import 'edit_location_basics.dart';
import '../common.dart';
import '../../data/common.dart';
import '../entity_table.dart';
import '../character/profile.dart';
import '../ui/menu_builder.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';
import 'site.dart';
import '../character/inventory/material.dart';
import '../../state/view_panels.dart';
import '../../logic/logic.dart';
import '../../state/hover_content.dart';

enum SiteOperation {
  check,
  delete,
}

class CityView extends StatefulWidget {
  const CityView({
    super.key,
    this.cityId,
    this.city,
    this.mode = InformationViewMode.view,
  });

  final String? cityId;
  final dynamic city;
  final InformationViewMode mode;

  @override
  State<CityView> createState() => _CityViewState();
}

class _CityViewState extends State<CityView>
    with SingleTickerProviderStateMixin {
  bool get isEditorMode => widget.mode == InformationViewMode.edit;
  bool get isManageMode => widget.mode == InformationViewMode.manage;

  final List<List<String>> _charactersTableData = [];
  late final TabController _tabController;
  final fluent.FlyoutController _buildSiteMenuController =
      fluent.FlyoutController();
  final fluent.FlyoutController _depositMaterialMenuController =
      fluent.FlyoutController();

  late List<Tab> tabs;

  final List<Widget> citySiteCards = [];
  final List<Widget> worldMapSiteCards = [];

  bool _showWorldMapSites = false;

  late final dynamic _city;
  late final dynamic _cityhall;
  dynamic _manager;
  dynamic _atLocation;

  final Set<String> buildableSites = {};

  bool _isDeveloping = false;
  int _progress = 0, _max = 0;

  String _statusString = '';
  String? _costDescription;

  Map<String, int> _developmentCost = {};
  String? _developmentCostDescription;

  @override
  void dispose() {
    super.dispose();

    _tabController.dispose();
    _buildSiteMenuController.dispose();
    _depositMaterialMenuController.dispose();
  }

  @override
  void initState() {
    super.initState();

    assert(widget.city != null || widget.cityId != null,
        'LocationView must have either sectId or sect data.');
    if (widget.city != null) {
      _city = widget.city!;
    } else if (widget.cityId != null) {
      _city = GameData.getLocation(widget.cityId);
    }
    assert(_city != null && _city['category'] == 'city',
        'LocationView cityId must refer to a city location.');

    final managerId = _city['managerId'];
    // 这里的 manager 可能是 null
    _manager = GameData.game['characters'][managerId];

    final cityhallId =
        '${_city['id']}_${_city['id']}${engine.locale('cityhall')}';
    _cityhall = GameData.getLocation(cityhallId);
    assert(_cityhall != null,
        'City location must have a cityhall site, id: $cityhallId');

    Iterable residents = [];

    residents =
        (_city['residents'] as Iterable).map((id) => GameData.getCharacter(id));

    for (final character in residents) {
      final row = GameData.getCharacterInformationRow(character);
      _charactersTableData.add(row);
    }

    tabs = [
      Tab(text: engine.locale('information')),
      Tab(text: '${engine.locale('residents')}(${residents.length})'),
    ];

    _tabController = TabController(length: 2, vsync: this);

    _updateDevelopmentStatus();
    _updateSitesData();
  }

  SiteCard _createSiteCard(dynamic siteData) {
    final card = SiteCard(
      site: siteData,
      imagePath: siteData['image'],
      onTap: (siteId) {
        context.read<ViewPanelState>().toogle(
          ViewPanels.siteInformation,
          arguments: {
            'site': siteData,
            'isAdmin': isManageMode || isEditorMode,
          },
        );
      },
      onSecondaryTap: (site, details) {
        if (!isManageMode && !isEditorMode) return;
        showFluentMenu(
          position: details.globalPosition,
          items: {
            engine.locale('check'): SiteOperation.check,
            engine.locale('delete'): SiteOperation.delete,
          },
          onSelectedItem: (SiteOperation item) {
            switch (item) {
              case SiteOperation.check:
                showDialog(
                  context: context,
                  builder: (context) {
                    return SiteView(
                      site: site,
                      mode: widget.mode,
                    );
                  },
                );
                break;
              case SiteOperation.delete:
                if (isManageMode) {
                  // TODO: 删除时提示玩家
                }
                engine.hetu.invoke(
                  'removeLocation',
                  positionalArgs: [siteData],
                );
                _updateSitesData();
                break;
            }
          },
        );
      },
    );
    return card;
  }

  void _updateDevelopmentStatus() {
    final (isDeveloping, progress, max, statusString, costDescription) =
        GameData.getLocationDevelopmentStatus(_cityhall);
    _isDeveloping = isDeveloping;
    _progress = progress;
    _max = max;
    _statusString = statusString;
    _costDescription = costDescription;

    _developmentCost = GameLogic.calculateLocationDevelopmentCost(_cityhall);
    _developmentCostDescription =
        GameData.getLocationDevelopmentCostDescription(_developmentCost);
  }

  void _updateSitesData() {
    final Set<String> existedSites = {};
    citySiteCards.clear();
    for (final siteId in _city['siteIds']) {
      final siteData = GameData.getLocation(siteId);
      final siteKind = siteData['kind'];
      if (siteKind == kLocationKindHeadquarters ||
          siteKind == kLocationKindCityhall) {
        continue;
      }
      existedSites.add(siteKind);
      final siteCard = _createSiteCard(siteData);
      citySiteCards.add(siteCard);
    }
    citySiteCards.sort((a, b) {
      final aData = (a as SiteCard).site;
      final bData = (b as SiteCard).site;
      return bData['priority'].compareTo(aData['priority']);
    });
    for (final siteKind in kSiteKindsBuildable) {
      if (existedSites.contains(siteKind)) {
        continue;
      }
      buildableSites.add(siteKind);
    }

    worldMapSiteCards.clear();
    for (final terrainIndex in _city['territoryIndexes']) {
      final terrain = GameData.world['terrains'][terrainIndex];
      final locationId = terrain['locationId'];
      if (locationId == null || locationId == _city['id']) continue;
      final siteData = GameData.getLocation(locationId);
      final siteCard = _createSiteCard(siteData);
      worldMapSiteCards.add(siteCard);
    }

    setState(() {});
  }

  void _tryStartDevelopment() {
    context.read<HoverContentState>().hide();
    final result = GameLogic.tryStartLocationDevelopment(_cityhall,
        cost: _developmentCost);
    if (result) {
      _updateDevelopmentStatus();
      setState(() {});
    }
  }

  void _cancelDevelopment() async {
    context.read<HoverContentState>().hide();
    await GameLogic.cancelLocationDevelopment(_cityhall);
    _updateDevelopmentStatus();
    setState(() {});
  }

  void _saveData() {}

  void close() {
    if (widget.mode == InformationViewMode.edit) {
      Navigator.of(context).pop();
    } else {
      engine.context.read<ViewPanelState>().toogle(ViewPanels.cityInformation);
    }
  }

  @override
  Widget build(BuildContext context) {
    String sectName = engine.locale('none');
    final sectId = _city['sectId'];
    if (sectId != null) {
      final sectData = GameData.getSect(sectId);
      sectName = sectData['name'];
    }

    final mainPanel = Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 700.0,
                height: 474.0,
                // decoration: GameUI.boxDecoration,
                padding: const EdgeInsets.only(right: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120.0,
                          height: 30.0,
                          child: Text('${engine.locale('ownedBySect')}:'),
                        ),
                        Text(sectName),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120.0,
                          height: 30.0,
                          child: Text('${engine.locale('manager')}:'),
                        ),
                        Text('${_manager?['name'] ?? engine.locale('none')}'),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120.0,
                          height: 30.0,
                          child: Text('${engine.locale('development')}:'),
                        ),
                        Text('${_city['development']}'),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 120.0,
                          height: 30.0,
                          child: Text('${engine.locale('status')}:'),
                        ),
                        Label(
                          _statusString,
                          padding: const EdgeInsets.only(top: 2.0),
                          height: 30.0,
                          onMouseEnter: (rect) {
                            context
                                .read<HoverContentState>()
                                .show(_costDescription, rect);
                          },
                          onMouseExit: () {
                            context.read<HoverContentState>().hide();
                          },
                        ),
                      ],
                    ),
                    if (_isDeveloping)
                      MouseRegion2(
                        onEnter: (rect) {
                          context.read<HoverContentState>().show(
                                '${engine.locale('progress')}: $_progress/$_max ${engine.locale('timeDay')}',
                                rect,
                              );
                        },
                        onExit: () {
                          context.read<HoverContentState>().hide();
                        },
                        child: SizedBox(
                          width: 200.0,
                          height: 20.0,
                          child:
                              LinearProgressIndicator(value: _progress / _max),
                        ),
                      ),
                    if (isEditorMode) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120.0,
                            height: 30.0,
                            child: Text('${engine.locale('worldPosition')}:'),
                          ),
                          Text(
                              '${_city['worldPosition']['left']}, ${_city['worldPosition']['top']}'),
                        ],
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120.0,
                            height: 30.0,
                            child: Text('${engine.locale('isDiscovered')}: '),
                          ),
                          fluent.Checkbox(
                            checked: _city['isDiscovered'] == true,
                            content: Text(engine.locale(
                                _city['isDiscovered'] == true ? 'yes' : 'no')),
                            onChanged: (bool? value) {
                              if (value != null) {
                                setState(() {
                                  _city['isDiscovered'] = value;
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                    const Spacer(),
                    if (isManageMode)
                      Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: fluent.Button(
                              style: FluentButtonStyles.slim,
                              onPressed: _isDeveloping
                                  ? _cancelDevelopment
                                  : _tryStartDevelopment,
                              child: Label(
                                engine.locale(
                                  _isDeveloping
                                      ? 'cancelUpgrade'
                                      : 'upgradeSite',
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0, vertical: 8.0),
                                onMouseEnter: (rect) {
                                  if (_isDeveloping) return;
                                  if (_developmentCostDescription == null) {
                                    return;
                                  }
                                  context.read<HoverContentState>().show(
                                        _developmentCostDescription!,
                                        rect,
                                        direction:
                                            HoverContentDirection.topCenter,
                                      );
                                },
                                onMouseExit: () {
                                  context.read<HoverContentState>().hide();
                                },
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: fluent.Button(
                              onPressed: () async {},
                              child: Text(engine.locale('dispatchMaterials')),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10.0),
                            child: fluent.FlyoutTarget(
                              controller: _buildSiteMenuController,
                              child: fluent.Button(
                                onPressed: () {
                                  showFluentMenu(
                                    placementMode:
                                        fluent.FlyoutPlacementMode.topLeft,
                                    controller: _buildSiteMenuController,
                                    items: {
                                      for (final siteKind in buildableSites)
                                        engine.locale(siteKind): siteKind,
                                    },
                                    onSelectedItem: (item) {},
                                  );
                                },
                                child: Text(engine.locale('buildSite')),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: fluent.FlyoutTarget(
                              controller: _depositMaterialMenuController,
                              child: fluent.Button(
                                onPressed: () async {
                                  showFluentMenu(
                                    placementMode:
                                        fluent.FlyoutPlacementMode.topLeft,
                                    controller: _depositMaterialMenuController,
                                    items: {
                                      engine.locale(
                                              'depositMaterialsDevelopmentCost'):
                                          'depositMaterialsDevelopmentCost',
                                      engine.locale('depositMaterials30Days'):
                                          'depositMaterials30Days',
                                      engine.locale('depositMaterials90Days'):
                                          'depositMaterials90Days',
                                      engine.locale('depositMaterials180Days'):
                                          'depositMaterials180Days',
                                      engine.locale('depositMaterials360Days'):
                                          'depositMaterials360Days',
                                      engine.locale('depositAll'): 'depositAll',
                                    },
                                    onSelectedItem: (String item) {
                                      dynamic toDeposit = {};
                                      final currentCost =
                                          _cityhall['updateStatus']['cost'];
                                      switch (item) {
                                        case 'depositMaterialsDevelopmentCost':
                                          for (final materialId
                                              in _developmentCost.keys) {
                                            if (materialId == 'days') continue;
                                            toDeposit[materialId] =
                                                _developmentCost[materialId]!;
                                          }
                                        case 'depositMaterials30Days':
                                          if (currentCost != null) {
                                            for (final materialId
                                                in currentCost.keys) {
                                              toDeposit[materialId] =
                                                  currentCost[materialId]! * 30;
                                            }
                                          }
                                        case 'depositMaterials90Days':
                                          if (currentCost != null) {
                                            for (final materialId
                                                in currentCost.keys) {
                                              toDeposit[materialId] =
                                                  currentCost[materialId]! * 90;
                                            }
                                          }
                                        case 'depositMaterials180Days':
                                          if (currentCost != null) {
                                            for (final materialId
                                                in currentCost.keys) {
                                              toDeposit[materialId] =
                                                  currentCost[materialId]! *
                                                      180;
                                            }
                                          }
                                        case 'depositMaterials360Days':
                                          if (currentCost != null) {
                                            for (final materialId
                                                in currentCost.keys) {
                                              toDeposit[materialId] =
                                                  currentCost[materialId]! *
                                                      360;
                                            }
                                          }
                                        case 'depositAll':
                                          toDeposit =
                                              GameData.hero['materials'];
                                      }
                                      if (toDeposit.isEmpty) return;
                                      GameLogic.heroDepositToLocationStorage(
                                          _cityhall, toDeposit);
                                      setState(() {});
                                    },
                                  );
                                },
                                child: Text(engine.locale('depositMaterials')),
                              ),
                            ),
                          ),
                        ],
                      ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 90,
                            height: 145,
                            child: Column(
                              children: [
                                fluent.Button(
                                  style: _showWorldMapSites
                                      ? FluentButtonStyles.tabVL
                                      : FluentButtonStyles.tabVLSelected,
                                  onPressed: () {
                                    _showWorldMapSites = false;
                                    setState(() {});
                                  },
                                  child: Text(engine.locale('citySites')),
                                ),
                                fluent.Button(
                                  style: _showWorldMapSites
                                      ? FluentButtonStyles.tabVLSelected
                                      : FluentButtonStyles.tabVL,
                                  onPressed: () {
                                    _showWorldMapSites = true;
                                    setState(() {});
                                  },
                                  child: Text(engine.locale('worldMapSites')),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            width: 600,
                            height: 145,
                            decoration: GameUI.boxDecoration.copyWith(
                              color: GameUI.backgroundColor,
                              borderRadius: BorderRadius.only(
                                topRight: GameUI.radius,
                                bottomRight: GameUI.radius,
                              ),
                            ),
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: [
                                Wrap(
                                    children: _showWorldMapSites
                                        ? worldMapSiteCards
                                        : citySiteCards),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 474.0,
                child: Column(
                  children: [
                    Container(
                      width: 255.0,
                      padding: const EdgeInsets.only(bottom: 5.0),
                      child: Row(
                        children: [
                          Label(
                            '${engine.locale('storage')}:',
                            padding: const EdgeInsets.only(top: 5.0),
                            onMouseEnter: (rect) {
                              context.read<HoverContentState>().show(
                                    '<grey>${engine.locale('storage_description')}</>',
                                    rect,
                                  );
                            },
                            onMouseExit: () {
                              context.read<HoverContentState>().hide();
                            },
                          ),
                          const Spacer(),
                          fluent.Button(
                            onPressed: () async {
                              await engine.hetu.invoke('collectAll',
                                  namespace: 'Player',
                                  positionalArgs: [
                                    _cityhall['storage'],
                                  ]);
                              _cityhall['storage'].clear();
                              setState(() {});
                            },
                            child: Text(
                              engine.locale('takeAll'),
                              style: TextStyles.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    MaterialList(
                      entity: _cityhall,
                      height: 433.0,
                      showZeroAmount: true,
                      materialListType: MaterialListType.storage,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (isEditorMode)
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: fluent.Button(
                    onPressed: () async {
                      final value = await showDialog(
                        context: context,
                        builder: (context) => EditLocationBasics(
                          id: _city['id'],
                          category: _city['category'],
                          kind: _city['kind'],
                          name: _city['name'],
                          image: _city['image'],
                          background: _city['background'],
                          atLocation: _atLocation,
                          allowEditCategory: false,
                          showNpcIdField: false,
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
                        _,
                      ) = value;
                      _city['category'] = category;
                      _city['kind'] = kind;
                      _city['name'] = name;
                      _city['image'] = image;
                      _city['background'] = background;

                      if (id != null && id != _city['id']) {
                        final oldId = _city['id'];
                        GameData.game['locations'].remove(oldId);
                        GameData.game['locations'][id] = _city;

                        if (_city['category'] == 'site') {
                          final atLocation =
                              GameData.getLocation(_city['atLocationId']);
                          atLocation['siteIds'].remove(oldId);
                          atLocation['siteIds'].add(id);
                        }

                        _city['id'] = id;
                      }
                      setState(() {});
                    },
                    child: Text(engine.locale('editIdAndImage')),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 10.0),
                  child: fluent.Button(
                    onPressed: () async {
                      final value = await showDialog(
                        context: context,
                        builder: (context) {
                          return EditLocationBasics(
                            category: 'site',
                            atLocation: _city,
                            allowEditCategory: false,
                            allowEditKind: true,
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
                      final site = engine.hetu.invoke(
                        'Location',
                        namedArgs: {
                          'category': 'site',
                          'kind': kind,
                          'id': id,
                          'name': name,
                          'image': image,
                          'background': background,
                          'atLocation': _city,
                          'npcId': npcId,
                          'sectId': _city['sectId'],
                        },
                      );
                      context.read<ViewPanelState>().toogle(
                        ViewPanels.siteInformation,
                        arguments: {
                          'site': site,
                          'isAdmin': true,
                        },
                      );
                      _updateSitesData();
                    },
                    child: Text(engine.locale('addSite')),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                  child: fluent.Button(
                    onPressed: () {
                      if (widget.mode == InformationViewMode.edit) {
                        _saveData();
                      }
                      Navigator.of(context).pop(true);
                    },
                    child: Text(engine.locale('confirm')),
                  ),
                ),
              ],
            ),
        ],
      ),
    );

    return ResponsiveView(
      width: 1000.0,
      height: isEditorMode ? 660.0 : 610.0,
      onBarrierDismissed: close,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_city['name']),
          actions: [CloseButton2(onPressed: close)],
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
      ),
    );
  }
}
