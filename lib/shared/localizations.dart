class GameLocalization {
  static const missingText = 'missing_text_';

  final data = <String, dynamic>{};

  void loadData(Map<String, dynamic> data) {
    this.data.addAll(data);
  }

  String operator [](String key) {
    final text = data[key];
    if (text == null) {
      return missingText;
    } else {
      return text;
    }
  }
}
