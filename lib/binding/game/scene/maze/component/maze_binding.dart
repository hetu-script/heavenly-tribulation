import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

import '../../../../../engine/scene/maze/component/rogue_map.dart';

extension MazeBinding on Maze {
  dynamic htFetch(String varName) {
    switch (varName) {
      case r'removeEntity':
        return (HTEntity object,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          removeEntity(positionalArgs[0], positionalArgs[1]);
        };
      case r'moveToTerrain':
        return (HTEntity object,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          moveToTerrain(positionalArgs[0], positionalArgs[1]);
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

class MazeClassBinding extends HTExternalClass {
  MazeClassBinding() : super(r'Maze');

  @override
  dynamic memberGet(String varName) {
    switch (varName) {
      case r'Maze.fromJson':
        return (HTEntity object,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          return Maze.fromJson(positionalArgs.first);
        };
      default:
        throw HTError.undefined(varName);
    }
  }

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    var i = object as Maze;
    return i.htFetch(varName);
  }
}
