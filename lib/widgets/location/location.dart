import 'package:flutter/material.dart';
// import 'package:quiver/pattern.dart';
// import 'package:samsara/event.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:samsara/ui/responsive_view.dart';

import '../../engine.dart';
import '../../game/ui.dart';
import 'site_card.dart';
import '../common.dart';
import 'edit_location_basics.dart';

class LocationView extends StatefulWidget {
  final String? locationId;
  final dynamic locationData;
  final dynamic atTerrain;
  final dynamic atLocation;
  final String? category, kind;
  final InformationViewMode mode;

  const LocationView({
    super.key,
    this.locationId,
    this.locationData,
    this.category,
    this.kind,
    this.atTerrain,
    this.atLocation,
    this.mode = InformationViewMode.view,
  });

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  bool get isEditorMode => widget.mode == InformationViewMode.edit;

  late final dynamic _locationData;
  final List<Widget> _siteCards = [];

  bool get isCity => _locationData['category'] == 'city';
  bool get isSite => _locationData['category'] == 'site';

  @override
  void initState() {
    super.initState();

    // if (widget.mode == InformationViewMode.create) {
    //   assert(widget.category != null && widget.kind != null);
    //   _locationData = engine.hetu.invoke('Location', namedArgs: {
    //     'atTerrain': widget.atTerrain,
    //     'atLocation': widget.atLocation,
    //     'category': widget.category,
    //     'kind': widget.kind,
    //   });
    // } else {
    assert(widget.locationData != null || widget.locationId != null);
    if (widget.locationData != null) {
      _locationData = widget.locationData!;
    } else if (widget.locationId != null) {
      _locationData = engine.hetu
          .invoke('getLocationById', positionalArgs: [widget.locationId]);
    }
    assert(_locationData != null);
    // }

    _updateSitesData();
  }

  void _saveData() {}

  void _updateSitesData() {
    _siteCards.clear();
    for (final siteId in _locationData['sites']) {
      final siteData =
          engine.hetu.invoke('getLocationById', positionalArgs: [siteId]);
      final siteCard = SiteCard(
        siteData: siteData,
        imagePath: siteData['image'],
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
      width: 720.0,
      height: widget.mode != InformationViewMode.view ? 460.0 : 400.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_locationData['name']),
          actions: const [CloseButton2()],
        ),
        body: Column(
          children: [
            Container(
              height: 360,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    children: [
                      if (isCity) ...[
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0, top: 8.0),
                          child: Text(
                              '${engine.locale('worldPosition')}: ${_locationData['worldPosition']['left']}, ${_locationData['worldPosition']['top']}'),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(right: 10.0, top: 8.0),
                          child: Text(
                              '${engine.locale('development')}: ${_locationData['development']}'),
                        ),
                        SizedBox(
                          width: 220.0,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 150,
                                child:
                                    Text('${engine.locale('isDiscovered')}: '),
                              ),
                              SizedBox(
                                width: 50,
                                height: 30,
                                child: FittedBox(
                                  fit: BoxFit.fill,
                                  child: Switch(
                                    value:
                                        _locationData['isDiscovered'] ?? false,
                                    activeColor: Colors.white,
                                    onChanged: (bool value) {
                                      setState(() {
                                        _locationData['isDiscovered'] = value;
                                      });
                                    },
                                  ),
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
                    ],
                  ),
                  Container(
                    width: 750,
                    height: 140,
                    margin: const EdgeInsets.only(top: 10.0),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white54,
                        width: 0.5,
                      ),
                      borderRadius: BorderRadius.circular(5.0),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        shrinkWrap: true,
                        children: [
                          Wrap(
                            // spacing: 4.0, // gap between adjacent chips
                            runSpacing: 4.0, // gap between lines
                            children: _siteCards,
                          ),
                        ],
                      ),
                    ),
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
                      child: ElevatedButton(
                        onPressed: () async {
                          final value = await showDialog(
                            context: context,
                            builder: (context) => EditLocationBasics(
                              id: _locationData['id'],
                              name: _locationData['name'],
                              background: _locationData['background'],
                            ),
                          );
                          if (value == null) return;
                          final (
                            id,
                            name,
                            background,
                          ) = value;
                          _locationData['name'] = name;
                          _locationData['background'] = background;

                          if (id != null && id != _locationData['id']) {
                            engine.hetu.invoke('removeLocationById',
                                positionalArgs: [_locationData['id']]);
                            _locationData['id'] = id;
                            engine.hetu.invoke('addLocation',
                                positionalArgs: [_locationData]);
                          }
                          setState(() {});
                        },
                        child: Text(engine.locale('editIdAndImage')),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: ElevatedButton(
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
                          final (category, kind, id, name, image, background) =
                              value;
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
                                return LocationView(
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
                    child: ElevatedButton(
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
