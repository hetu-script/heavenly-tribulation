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
// import '../common.dart';
import 'edit_location_basics.dart';
// import '../ui/menu_builder.dart';
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
    this.onTapOnSite,
  });

  final String? locationId;
  final dynamic locationData;
  final String? category, kind;
  final void Function(String siteId)? onTapOnSite;

  @override
  State<EditLocation> createState() => _EditLocationState();
}

class _EditLocationState extends State<EditLocation> {
  late final dynamic _locationData;
  final List<Widget> _siteCards = [];

  dynamic _atLocation;

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

    _atLocation = GameData.gameData['locations'][_locationData['atLocationId']];

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
      final npcData = GameData.gameData['npcs'][_locationData['npcId']];
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
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 800.0,
      height: 450.0,
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
                      if (isCity)
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
                            child: Text('${engine.locale('development')}:'),
                          ),
                          Text('${_locationData['development']}'),
                        ],
                      ),
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
                        final oldId = _locationData['id'];
                        GameData.gameData['locations'].remove(oldId);
                        GameData.gameData['locations'][id] = _locationData;

                        if (_locationData['category'] == 'site') {
                          final atLocation = GameData.gameData['locations']
                              [_locationData['atLocationId']];
                          assert(atLocation != null);
                          atLocation['sites'].remove(oldId);
                          atLocation['sites'].add(id);
                        }

                        _locationData['id'] = id;
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
                              allowEditKind:
                                  _locationData['category'] == 'city',
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
                              locationData: locationData,
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
          ],
        ),
      ),
    );
  }
}
