import 'package:flutter/material.dart';
// import 'package:quiver/pattern.dart';
// import 'package:samsara/event.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../game/ui.dart';
import '../../game/data.dart';
import 'site_card.dart';
import '../common.dart';
import 'edit_location_basics.dart';
import '../ui/menu_builder.dart';
import 'edit_npc_basics.dart';

enum NpcOperation {
  create,
  delete,
  edit,
}

class EditLocation extends StatefulWidget {
  const EditLocation({
    super.key,
    this.locationId,
    this.locationData,
    this.category,
    this.kind,
    this.atTerrain,
    this.atLocation,
    this.mode = InformationViewMode.view,
    this.onTapOnSite,
  });

  final String? locationId;
  final dynamic locationData;
  final dynamic atTerrain;
  final dynamic atLocation;
  final String? category, kind;
  final InformationViewMode mode;
  final void Function(String siteId)? onTapOnSite;

  @override
  State<EditLocation> createState() => _EditLocationState();
}

class _EditLocationState extends State<EditLocation> {
  bool get isEditorMode => widget.mode == InformationViewMode.edit;

  late final dynamic _locationData;
  final List<Widget> _siteCards = [];

  bool get isCity => _locationData['category'] == 'city';
  bool get isSite => _locationData['category'] == 'site';

  @override
  void initState() {
    super.initState();

    assert(widget.locationData != null || widget.locationId != null);
    if (widget.locationData != null) {
      _locationData = widget.locationData!;
    } else if (widget.locationId != null) {
      _locationData = GameData.gameData['locations'][widget.locationId];
    }
    assert(_locationData != null);

    _updateSitesData();
  }

  void _saveData() {}

  void _updateSitesData() {
    _siteCards.clear();
    for (final siteId in _locationData['sites']) {
      final siteData = GameData.gameData['locations'][siteId];
      final siteCard = SiteCard(
        siteData: siteData,
        imagePath: siteData['image'],
        onTap: widget.onTapOnSite,
      );
      _siteCards.add(siteCard);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 800.0,
      height: widget.mode != InformationViewMode.view ? 450.0 : 400.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_locationData['name']),
          actions: const [CloseButton2()],
        ),
        body: Column(
          children: [
            Container(
              width: 800.0,
              height: 350,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isCity) ...[
                        Row(
                          children: [
                            SizedBox(
                              width: 120.0,
                              height: 30.0,
                              child: Text('${engine.locale('worldPosition')}:'),
                            ),
                            Text(
                                '${_locationData['worldPosition']['left']}, ${_locationData['worldPosition']['top']}'),
                          ],
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 120.0,
                              height: 30.0,
                              child: Text('${engine.locale('development')}:'),
                            ),
                            Text('${_locationData['development']}'),
                          ],
                        ),
                        SizedBox(
                          height: 30.0,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 120.0,
                                child:
                                    Text('${engine.locale('isDiscovered')}: '),
                              ),
                              SizedBox(
                                width: 20.0,
                                height: 20.0,
                                child: fluent.Checkbox(
                                  checked:
                                      _locationData['isDiscovered'] ?? false,
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
                        ),
                        SizedBox(
                          height: 30.0,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 120.0,
                                child: Text('NPC:'),
                              ),
                              fluent.DropDownButton(
                                title: Text(engine.locale('setNpc')),
                                items: buildFluentMenuItems(
                                  items: {
                                    if (_locationData['npcId'] == null)
                                      engine.locale('create'):
                                          NpcOperation.create,
                                    if (_locationData['npcId'] != null)
                                      engine.locale('edit'): NpcOperation.edit,
                                    if (_locationData['npcId'] != null)
                                      '___': null,
                                    if (_locationData['npcId'] != null)
                                      engine.locale('delete'):
                                          NpcOperation.delete
                                  },
                                  onSelectedItem:
                                      (NpcOperation operation) async {
                                    switch (operation) {
                                      case NpcOperation.create:
                                        final npcData = await showDialog(
                                          context: context,
                                          builder: (context) {
                                            return EditNpcBasics(
                                              id: _locationData['id'] + '_npc',
                                            );
                                          },
                                        );
                                        _locationData['npcId'] = npcData['id'];
                                      case NpcOperation.edit:
                                        final npcData =
                                            GameData.gameData['npcs']
                                                [_locationData['npcId']];
                                        assert(npcData != null);
                                        await showDialog(
                                          context: context,
                                          builder: (context) {
                                            return EditNpcBasics(
                                              id: npcData['id'],
                                              name: npcData['name'],
                                              icon: npcData['icon'],
                                              illustration:
                                                  npcData['illustration'],
                                            );
                                          },
                                        );
                                      case NpcOperation.delete:
                                        final npcData =
                                            GameData.gameData['npcs']
                                                [_locationData['npcId']];
                                        assert(npcData != null);
                                        GameData.gameData['npcs']
                                            .remove(npcData['id']);
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        // SizedBox(
                        //   width: 220.0,
                        //   child: Row(
                        //     children: [
                        //       SizedBox(
                        //         width: 150,
                        //         child: Text(
                        //             '${engine.locale('addDefaultSites')}: '),
                        //       ),
                        //       Switch(
                        //         value:
                        //             _locationData['addDefaultSites'] ?? false,
                        //         activeColor: Colors.white,
                        //         onChanged: (bool value) {
                        //           setState(() {
                        //             _locationData['addDefaultSites'] = value;
                        //           });
                        //         },
                        //       ),
                        //     ],
                        //   ),
                        // ),
                      ],
                      const Spacer(),
                      Container(
                        width: 600,
                        height: 140,
                        margin: const EdgeInsets.only(top: 10.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.white54,
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
                  if (_locationData['category'] == 'city')
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(' ${engine.locale('residents')}:'),
                        Container(
                          width: 165,
                          height: 322,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white54,
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          margin: const EdgeInsets.only(top: 5.0, left: 5.0),
                          padding: const EdgeInsets.all(5.0),
                          child: ListView(
                            children: (_locationData['residents'] as List)
                                .map((id) => Text(id))
                                .toList(),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            if (widget.mode != InformationViewMode.view)
              Row(
                children: [
                  if (isEditorMode) ...[
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
                          ) = value;
                          _locationData['category'] = category;
                          _locationData['kind'] = kind;
                          _locationData['name'] = name;
                          _locationData['image'] = image;
                          _locationData['background'] = background;

                          if (id != null && id != _locationData['id']) {
                            GameData.gameData['locations']
                                .remove(_locationData['id']);
                            _locationData['id'] = id;
                            GameData.gameData['locations'][id] = _locationData;
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
                                  allowEditCategory: false,
                                );
                              });
                          if (value == null) return;
                          final (
                            id,
                            category,
                            kind,
                            name,
                            image,
                            background,
                          ) = value;
                          final locationData = engine.hetu.invoke(
                            'Location',
                            namedArgs: {
                              'category': 'site',
                              'kind': kind,
                              'id': id,
                              'name': name,
                              'image': image,
                              'background': background,
                              'atLocation': _locationData,
                            },
                          );
                          await showDialog(
                              context: context,
                              builder: (context) {
                                return EditLocation(
                                  mode: InformationViewMode.edit,
                                  locationData: locationData,
                                );
                              });
                          _updateSitesData();
                        },
                        child: Text(engine.locale('addSite')),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                    child: fluent.FilledButton(
                      onPressed: () {
                        switch (widget.mode) {
                          case InformationViewMode.view:
                            Navigator.of(context).pop();
                          case InformationViewMode.select:
                            Navigator.of(context).pop(_locationData['id']);
                          case InformationViewMode.edit:
                            _saveData();
                            Navigator.of(context).pop(true);
                          // case InformationViewMode.create:
                          //   _saveData();
                          //   Navigator.of(context).pop(_locationData);
                        }
                      },
                      child: Text(engine.locale('confirm')),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
