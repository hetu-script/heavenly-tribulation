import 'package:flutter/material.dart';
// import 'package:quiver/pattern.dart';
// import 'package:samsara/event.dart';
import 'package:samsara/ui/close_button.dart';
import 'package:samsara/ui/responsive_window.dart';

import '../../config.dart';
import 'site_card.dart';
import '../common.dart';
import 'edit_location_id_and_image.dart';

class LocationView extends StatefulWidget {
  final String? locationId;
  final dynamic locationData;
  final int? left, top;
  final String? category;
  final ViewPanelMode mode;

  const LocationView({
    super.key,
    this.locationId,
    this.locationData,
    this.left,
    this.top,
    this.category,
    this.mode = ViewPanelMode.view,
  });

  @override
  State<LocationView> createState() => _LocationViewState();
}

class _LocationViewState extends State<LocationView> {
  bool get isEditorMode =>
      widget.mode == ViewPanelMode.edit || widget.mode == ViewPanelMode.create;

  late final dynamic _locationData;
  List<Widget> _siteCards = [];

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

    updateData();
  }

  void updateData() {
    // final HTStruct sitesData = _locationData['sites'];
    // final heroHomeId = engine.hetu.invoke('getHeroHomeLocationId');
    // if (_locationData['id'] == heroHomeId) {
    //   final heroHomeSite = engine.hetu.invoke('getHeroHomeSite');
    //   _siteCards.add(
    //     SiteCard(
    //       siteData: heroHomeSite,
    //       imagePath: heroHomeSite['image'],
    //     ),
    //   );
    // }
    final sitesData = _locationData['sites']
        .values
        .where((value) => !(value['isSubSite'] ?? false));

    _siteCards = List<Widget>.from(sitesData.map(
      (siteData) {
        return SiteCard(
          siteData: siteData,
          imagePath: siteData['image'],
        );
      },
    ));
  }

  void _saveData() {}

  @override
  Widget build(BuildContext context) {
    return ResponsiveWindow(
      color: kBackgroundColor,
      alignment: AlignmentDirectional.center,
      size: Size(400.0, widget.mode != ViewPanelMode.view ? 440.0 : 400.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(_locationData['name']),
          actions: const [CloseButton2()],
        ),
        body: Column(
          children: [
            Container(
              height: 350,
              width: 380,
              alignment: Alignment.topLeft,
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      '${engine.locale('worldPosition')}: ${_locationData['worldPosition']['left']}, ${_locationData['worldPosition']['top']}'),
                  Text(
                      '${engine.locale('development')}: ${_locationData['development']}'),
                ],
              ),
            ),
            if (widget.mode != ViewPanelMode.view)
              Row(
                children: [
                  if (isEditorMode)
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
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0, right: 10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        switch (widget.mode) {
                          case ViewPanelMode.select:
                            Navigator.of(context).pop(_locationData['id']);
                          case ViewPanelMode.edit:
                            _saveData();
                            Navigator.of(context).pop(true);
                          case ViewPanelMode.create:
                            _saveData();
                            Navigator.of(context).pop(_locationData);
                          case ViewPanelMode.view:
                            Navigator.of(context).pop();
                        }
                      },
                      child: Text(
                          engine.locale(isEditorMode ? 'save' : 'confirm')),
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
