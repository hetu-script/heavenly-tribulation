import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

import '../../engine.dart';

extension SamsaraEngineBinding on SamsaraEngine {
  dynamic htFetch(String varName) {
    switch (varName) {
      case 'updateLocale':
        return (HTEntity object,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            updateLocale(positionalArgs.first);
      case 'updateZoneColors':
        return (HTEntity object,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            updateZoneColors(positionalArgs.first);
      case 'updateNationColors':
        return (HTEntity object,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            updateNationColors(positionalArgs.first);
      // case 'onIncident':
      //   return (HTEntity object,
      //           {List<dynamic> positionalArgs = const [],
      //           Map<String, dynamic> namedArgs = const {},
      //           List<HTType> typeArgs = const []}) =>
      //       onIncident(positionalArgs.first);
      case 'debug':
        return (HTEntity object,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            debug(positionalArgs.first);
      case 'info':
        return (HTEntity object,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            info(positionalArgs.first);
      case 'warning':
        return (HTEntity object,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            warning(positionalArgs.first);
      case 'error':
        return (HTEntity object,
                {List<dynamic> positionalArgs = const [],
                Map<String, dynamic> namedArgs = const {},
                List<HTType> typeArgs = const []}) =>
            error(positionalArgs.first);
      default:
        throw HTError.undefined(varName);
    }
  }
}

class SamsaraEngineClassBinding extends HTExternalClass {
  SamsaraEngineClassBinding() : super(r'SamsaraEngine');

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    var i = object as SamsaraEngine;
    return i.htFetch(varName);
  }
}
