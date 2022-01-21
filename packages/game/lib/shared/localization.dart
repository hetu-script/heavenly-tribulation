import 'package:hetu_script/values.dart';

class GameLocalization {
  static const missingText = 'missing_text';

  String get missing => missingText;

  late HTStruct data;

  void loadData(HTStruct data) {
    this.data = data;
  }

  String operator [](String key) {
    final text = data[key];
    if (text == null) {
      return '$missingText($key)';
    } else {
      return text;
    }
  }
}
