import 'package:flutter/material.dart';
// import 'package:quiver/pattern.dart';
// import 'package:samsara/event.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:samsara/ui/responsive_panel.dart';

import '../../engine.dart';
import '../../ui.dart';
import 'site_card.dart';
import '../common.dart';
import 'edit_location_id_and_image.dart';
import 'edit_site.dart';

class LocationView extends StatefulWidget {
  final String? locationId;
  final dynamic locationData;
  final int? left, top;
  final String? category;
  final InformationViewMode mode;

  const LocationView({
    super.key,
    this.locationId,
    this.locationData,
    this.left,
    this.top,
    this.category,
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
      // 临时创建的数据，此时尚未加入游戏中
      assert(widget.left != null && widget.top != null);
      final terrain = engine.hetu.invoke('getTerrainByWorldPosition',
          positionalArgs: [widget.left, widget.top]);
      _locationData =
          engine.hetu.invoke('Location', namedArgs: {'terrain': terrain});
    }

    _isDiscovered = _locationData['isDiscovered'] ?? false;

    _loadData();
  }

  void _saveData() {
    _locationData['isDiscovered'] = _isDiscovered;
  }

  void _loadData() {
    final locations = engine.hetu.invoke('getLocations');
    _siteCards = List<Widget>.from(
      (_locationData['buildings'] as Map).values.map(
        (buildingId) {
          final siteData = locations[buildingId];
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
    return ResponsivePanel(
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${engine.locale('worldPosition')}: ${_locationData['worldPosition']['left']}, ${_locationData['worldPosition']['top']}'),
                  Text(
                      '${engine.locale('development')}: ${_locationData['development']}'),
                  SizedBox(
                    width: 300,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100.0,
                          child: Text('${engine.locale('isDiscovered')}: '),
                        ),
                        SizedBox(
                          width: 150.0,
                          child: Switch(
                            value: _isDiscovered,
                            activeColor: Colors.white,
                            onChanged: (bool value) {
                              setState(() {
                                _isDiscovered = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 600,
                    height: 280,
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
                              'category': 'building',
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
