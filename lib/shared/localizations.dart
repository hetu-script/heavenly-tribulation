class _Language {
  static const missingText = 'missing_text_';

  final Map<String, dynamic> strings;

  _Language(this.strings);

  String operator [](String key) {
    final str = strings[key];
    if (str == null) {
      return '$missingText[$key]';
    } else {
      return str;
    }
  }
}

class GameLocalizations {
  static const missingLanguage = 'missing_language_';
  static const defaultLanguage = 'zhHans';

  String selectedLanguage = defaultLanguage;

  final languages = <String, _Language>{};

  GameLocalizations();

  loadFromJson(Map<String, dynamic> data) {
    for (final key in data.keys) {
      final Map<String, dynamic> strings = data[key]!;
      final language = _Language(strings);
      languages[key] = language;
    }
  }

  String operator [](String key) {
    final lang = languages[selectedLanguage];
    if (lang == null) {
      return '$missingLanguage[$selectedLanguage]';
    } else {
      return lang[key];
    }
  }
}
