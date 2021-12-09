class GameLocalization {
  static const missingText = 'missing_text_';

  final Map<String, dynamic> data;

  GameLocalization(this.data);

  String operator [](String key) {
    final text = data[key];
    if (text == null) {
      return missingText;
    } else {
      return text;
    }
  }
}
