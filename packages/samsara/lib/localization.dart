import 'package:hetu_script/values.dart';

class GameLocalization {
  static const localeNotInitialized = 'locale_is_not_initialized';
  static const missingText = 'missing_text_';

  String get missing => missingText;

  HTStruct? data;

  void loadData(HTStruct localeData) {
    data = localeData;
  }

  /// 普通字符串可以直接用 [] 操作符快速获取
  String operator [](String key) {
    if (data != null) {
      final text = data![key];
      if (text == null) {
        return '$missingText($key)';
      } else {
        return text;
      }
    } else {
      return localeNotInitialized;
    }
  }

  /// 对于需要替换部分字符串的本地化串，使用这个接口
  String getString(String key, {List<String> interpolations = const []}) {
    var text = this[key];

    for (var i = 0; i < interpolations.length; ++i) {
      text = text.replaceAll('{$i}', interpolations[i]);
    }
    return text;
  }
}
