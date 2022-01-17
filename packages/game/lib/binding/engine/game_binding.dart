import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

import '../../engine/engine.dart';

extension SamsaraEngineBinding on SamsaraEngine {
  dynamic htFetch(String varName) {
    switch (varName) {
      case r'updateLanguagesData':
        return (HTEntity object,
            {List<dynamic> positionalArgs = const [],
            Map<String, dynamic> namedArgs = const {},
            List<HTType> typeArgs = const []}) {
          updateLanguagesData(positionalArgs[0]);
        };
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
