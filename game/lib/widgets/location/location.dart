import 'package:flutter/material.dart';
// import 'package:quiver/pattern.dart';
// import 'package:samsara/event.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:samsara/ui/responsive_view.dart';

import '../../engine.dart';
import '../../ui.dart';
import 'site_card.dart';
import '../common.dart';
import 'edit_location_id_and_image.dart';
import 'edit_site.dart';

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
  bool get isEditorMode =>
      widget.mode == InformationViewMode.edit ||
      widget.mode == InformationViewMode.create;

  late final dynamic _locationData;
  List<Widget> _siteCards = [];
  late bool _isDiscovered;
  late bool _hasDefaultSites;

  @override
  void initState() {
    super.initState();

    if (widget.mode.index <= 2) {
      if (widget.locationData != null) {
        _locationData = widget.locationData!;
      } else if (widget.locationId != null) {
        _locationData = engine.hetu
            .invoke('getLocationById', positionalArgs: [widget.locationId]);
      }
    } else {
      // 处理 `widget.mode == InformationViewMode.create` 的情况
      assert(widget.category != null && widget.kind != null);
      _locationData = engine.hetu.invoke('Location', namedArgs: {
        'isMain': false, // 临时数据尚未加入游戏中
        'atTerrain': widget.atTerrain,
        'atLocation': widget.atLocation,
        'category': widget.category,
        'kind': widget.kind,
      });
    }

    _isDiscovered = _locationData['isDiscovered'] ?? false;
    _hasDefaultSites = _locationData['hasDefaultSites'] ?? false;

    _loadData();
  }

  void _saveData() {
    _locationData['isDiscovered'] = _isDiscovered;
    _locationData['hasDefaultSites'] = _hasDefaultSites;
  }

  void _loadData() {
    _siteCards = List<Widget>.from(
      _locationData['sites'].map(
        (siteId) {
          final siteData =
              engine.hetu.invoke('getLocationById', positionalArgs: [siteId]);
          return SiteCard(
            siteData: siteData,
            imagePath: siteData['image'],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      color: GameUI.backgroundColor,
      alignment: AlignmentDirectional.center,
      width: 640.0,
      height: widget.mode != InformationViewMode.view ? 440.0 : 400.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_locationData['name']),
          actions: const [CloseButton2()],
        ),
        body: Column(
          children: [
            Container(
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 248,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_locationData['worldPosition']?['left'] != null &&
                            _locationData['worldPosition']?['top'] != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: Text(
                                '${engine.locale('worldPosition')}: ${_locationData['worldPosition']['left']}, ${_locationData['worldPosition']['top']}'),
                          ),
                        Text(
                            '${engine.locale('development')}: ${_locationData['development']}'),
                        Row(
                          children: [
                            SizedBox(
                              width: 180.0,
                              child: Text('${engine.locale('isDiscovered')}: '),
                            ),
                            Switch(
                              value: _isDiscovered,
                              activeColor: Colors.white,
                              onChanged: (bool value) {
                                setState(() {
                                  _isDiscovered = value;
                                });
                              },
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            SizedBox(
                              width: 180.0,
                              child: Text(
                                  '${engine.locale('addDefaultSubsidiaries')}: '),
                            ),
                            Switch(
                              value: _isDiscovered,
                              activeColor: Colors.white,
                              onChanged: (bool value) {
                                setState(() {
                                  _isDiscovered = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 350,
                    height: 350,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                        width: 1.0,
                      ),
                    ),
                    child: SingleChildScrollView(
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Wrap(
                                spacing: 8.0, // gap between adjacent chips
                                runSpacing: 4.0, // gap between lines
                                children: _siteCards,
                              ),
                            ),
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
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => EditLocationIdAndBackground(
                              id: _locationData['id'],
                              name: _locationData['name'],
                              backgroundPath: _locationData['background'],
                            ),
                          ).then(
                            (value) {
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
                          );
                        },
                        child: Text(engine.locale('editIdAndImage')),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 10.0),
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => const EditSite(),
                          ).then((value) {
                            if (value == null) return;
                            engine.hetu.invoke('Location', namedArgs: {
                              'category': 'site',
                              'kind': value,
                              'location': _locationData,
                            });
                            setState(() {});
                          });
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
                          case InformationViewMode.select:
                            Navigator.of(context).pop(_locationData['id']);
                          case InformationViewMode.edit:
                            _saveData();
                            Navigator.of(context).pop(true);
                          case InformationViewMode.create:
                            _saveData();
                            Navigator.of(context).pop(_locationData);
                          case InformationViewMode.view:
                            Navigator.of(context).pop();
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
