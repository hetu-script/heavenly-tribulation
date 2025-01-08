import 'package:flutter/foundation.dart';

import '../scene/common.dart';
import '../scene/world/location/components/location_site.dart';
import '../engine.dart';

class LocationSiteSceneState with ChangeNotifier {
  LocationSiteScene? scene;

  final List<String> _sceneIds = [];

  dynamic _locationData;

  void clear() {
    for (final id in _sceneIds) {
      engine.clearCache(id);
    }
    _sceneIds.clear();
  }

  Future<LocationSiteScene?> pop() async {
    // engine.clearCache(_sceneIds.last);
    _sceneIds.removeLast();
    String? currentSceneId;
    if (_sceneIds.isNotEmpty) {
      currentSceneId = _sceneIds.last;
      scene = await (engine.createScene<LocationSiteScene>(
          contructorKey: 'locationSite', sceneId: currentSceneId));
    } else {
      scene = null;
    }
    notifyListeners();
    return scene;
  }

  // TODO: 检查重复进入场景？
  Future<LocationSiteScene> push({
    dynamic locationData,
    String? siteId,
  }) async {
    if (locationData != null) {
      clear();
      _locationData = locationData;
      final id = _locationData['id'];
      _sceneIds.add(id);
      final sitesIds = _locationData['sites']
          .values
          .where((value) => !(value['isSubSite'] ?? false))
          .map((value) => value['id']);
      scene = await engine.createScene(
        contructorKey: kSceneLocationSite,
        sceneId: id,
        arg: {
          'id': id,
          'background': _locationData['background'],
          'sitesIds': sitesIds,
          'sitesData': _locationData['sites'],
        },
      ) as LocationSiteScene;
    } else {
      assert(_locationData != null);
      assert(_sceneIds.isNotEmpty && siteId != _sceneIds.last);
      _sceneIds.add(siteId!);
      dynamic siteData = _locationData['sites'][siteId];
      scene = await engine.createScene(
        contructorKey: kSceneLocationSite,
        sceneId: siteId,
        arg: {
          'id': siteId,
          'background': siteData['background'],
          'sitesIds': siteData['siteIds'],
          'sitesData': _locationData['sites'],
        },
      ) as LocationSiteScene;
    }
    notifyListeners();
    return scene!;
  }
}
