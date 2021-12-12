import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/binding.dart';

import '../../engine/game.dart';

extension SamsaraGameBinding on SamsaraGame {
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

class SamsaraGameClassBinding extends HTExternalClass {
  SamsaraGameClassBinding() : super(r'SamsaraGame');

  @override
  dynamic instanceMemberGet(dynamic object, String varName) {
    var i = object as SamsaraGame;
    return i.htFetch(varName);
  }
}
