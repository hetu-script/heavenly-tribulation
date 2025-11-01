import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/mouse_region2.dart';
import 'package:samsara/widgets/ui/label.dart';

import '../../global.dart';
import '../../ui.dart';
import '../../data/game.dart';
import 'edit_location_basics.dart';
import '../common.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';
import '../character/inventory/material.dart';
import '../../logic/logic.dart';
import '../../state/states.dart';
import '../ui/menu_builder.dart';

enum NpcOperation {
  create,
  delete,
  edit,
}

class SiteView extends StatefulWidget {
  const SiteView({
    super.key,
    this.siteId,
    this.site,
    this.mode = InformationViewMode.view,
  });

  final String? siteId;
  final dynamic site;
  final InformationViewMode mode;

  @override
  State<SiteView> createState() => _SiteViewState();
}

class _SiteViewState extends State<SiteView>
    with SingleTickerProviderStateMixin {
  final fluent.FlyoutController _depositMaterialMenuController =
      fluent.FlyoutController();

  bool get isEditorMode => widget.mode == InformationViewMode.edit;
  bool get isManageMode => widget.mode == InformationViewMode.manage;

  late final dynamic _site;
  dynamic _manager;
  dynamic _atLocation;

  bool _isDeveloping = false;
  int _progress = 0, _max = 0;

  String _statusString = '';
  String _costDescription = '';

  Map<String, int> _developmentCost = {};
  String? _developmentCostDescription;

  @override
  void initState() {
    super.initState();

    assert(widget.site != null || widget.siteId != null,
        'SiteView must have either siteId or site data.');
    if (widget.site != null) {
      _site = widget.site!;
    } else if (widget.siteId != null) {
      _site = GameData.getLocation(widget.siteId);
    }
    assert(_site != null && _site['category'] == 'site',
        'SiteView siteId must refer to a site location.');

    final managerId = _site['managerId'];
    // 这里的 manager 可能是 null
    _manager = GameData.game['characters'][managerId];

    _atLocation = GameData.game['locations'][_site['atCityId']];

    _updateDevelopmentStatus();
  }

  void _updateDevelopmentStatus() {
    final (isDeveloping, progress, max, statusString, costDescription) =
        GameData.getLocationDevelopmentStatus(_site);
    _isDeveloping = isDeveloping;
    _progress = progress;
    _max = max;
    _statusString = statusString;
    _costDescription = costDescription;

    _developmentCost = GameLogic.calculateLocationDevelopmentCost(_site);
    _developmentCostDescription =
        GameData.getLocationDevelopmentCostDescription(_developmentCost);
  }

  void _tryStartDevelopment() {
    context.read<HoverContentState>().hide();
    final result =
        GameLogic.tryStartLocationDevelopment(_site, cost: _developmentCost);
    if (result) {
      _updateDevelopmentStatus();
      setState(() {});
    }
  }

  void _cancelDevelopment() async {
    context.read<HoverContentState>().hide();
    await GameLogic.cancelLocationDevelopment(_site);
    _updateDevelopmentStatus();
    setState(() {});
  }

  void _saveData() {}

  void close() {
    if (widget.mode == InformationViewMode.edit ||
        widget.mode == InformationViewMode.select) {
      Navigator.of(context).pop();
    } else {
      engine.context.read<ViewPanelState>().toogle(ViewPanels.siteInformation);
    }
  }

  @override
  Widget build(BuildContext context) {
    String sectName = engine.locale('none');
    final sectId = _site['sectId'];
    if (sectId != null) {
      final sectData = GameData.getSect(sectId);
      sectName = sectData['name'];
    }

    final mainPanel = Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 285.0,
                height: 440.0,
                // decoration: GameUI.boxDecoration,
                padding: const EdgeInsets.all(0.0),
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
                        Text('${_site['development']}'),
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
                                          _site['updateStatus']['cost'];
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
                                          _site, toDeposit);
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
                  ],
                ),
              ),
              SizedBox(
                height: 445.0,
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
                          if (isManageMode)
                            fluent.Button(
                              onPressed: () async {
                                await engine.hetu.invoke('collectAll',
                                    namespace: 'Player',
                                    positionalArgs: [
                                      GameData.hero,
                                      _site['storage'],
                                    ]);
                                _site['storage'].clear();
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
                      entity: _site,
                      height: 400.0,
                      showZeroAmount: true,
                      materialListType: MaterialListType.storage,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          if (isEditorMode)
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 0.0),
                  child: fluent.Button(
                    onPressed: () async {
                      final value = await showDialog(
                        context: context,
                        builder: (context) => EditLocationBasics(
                          id: _site['id'],
                          category: _site['category'],
                          kind: _site['kind'],
                          name: _site['name'],
                          image: _site['image'],
                          background: _site['background'],
                          atCity: _atLocation,
                          npcId: _site['npcId'],
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
                      _site['category'] = category;
                      _site['kind'] = kind;
                      _site['name'] = name;
                      _site['image'] = image;
                      _site['background'] = background;
                      _site['npcId'] = npcId;

                      if (id != null && id != _site['id']) {
                        final oldId = _site['id'];
                        GameData.game['locations'].remove(oldId);
                        GameData.game['locations'][id] = _site;

                        if (_site['category'] == 'site') {
                          final atCity =
                              GameData.getLocation(_site['atCityId']);
                          atCity['siteIds'].remove(oldId);
                          atCity['siteIds'].add(id);
                        }
                        _site['id'] = id;
                      }
                      setState(() {});
                    },
                    child: Text(engine.locale('editIdAndImage')),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.only(right: 0.0),
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
      width: 600.0,
      height: isEditorMode ? 585.0 : 535.0,
      onBarrierDismissed: close,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_site['name']),
          actions: [
            CloseButton2(
              onPressed: close,
            )
          ],
        ),
        body: mainPanel,
      ),
    );
  }
}
