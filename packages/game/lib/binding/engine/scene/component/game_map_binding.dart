import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

import '../../../../../engine/tilemap/map.dart';

extension MapComponentBinding on TileMap {
  dynamic htFetch(String varName) {
    switch (varName) {
      case r'moveCameraToTilePosition':
        return (HTEntity object,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          moveCameraToTilePosition(positionalArgs[0], positionalArgs[1]);
        };
      case r'lightUpAroundTerrain':
        return (HTEntity object,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          lightUpAroundTerrain(positionalArgs[0], positionalArgs[1]);
        };
      default:
        throw HTError.undefined(varName);
    }
  }
}

class MapComponentClassBinding extends HTExternalClass {
  MapComponentClassBinding() : super(r'MapComponent');

  @override
  dynamic memberGet(String varName, {String? from}) {
    switch (varName) {
      case r'MapComponent.fromJson':
        return (HTEntity object,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          return TileMap.fromJson(positionalArgs[0]);
        };
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    var i = object as TileMap;
    return i.htFetch(varName);
  }
}
