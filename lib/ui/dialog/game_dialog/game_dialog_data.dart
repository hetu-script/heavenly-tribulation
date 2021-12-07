class GameDialogContent {
  final String characterId;

  final List<String> saying;

  GameDialogContent(this.characterId, this.saying);
}

class GameDialogOption {
  final String id;

  final String text;

  GameDialogOption(this.id, this.text);
}

class GameDialogData {
  final String id;

  final List<GameDialogContent> contents;

  final List<GameDialogOption>? options;

  GameDialogData({
    required this.id,
    required this.contents,
    this.options,
  });

  static GameDialogData fromJson(Map<String, dynamic> data) {
    final id = data['id'];
    final contents = <GameDialogContent>[];
    final contentData = data['content'];
    for (final content in contentData) {
      final characterId = content['characterId'];
      final saying = <String>[];
      final sayingData = content['saying'];
      for (final text in sayingData) {
        saying.add(text);
      }
      final dlgContent = GameDialogContent(characterId, saying);
      contents.add(dlgContent);
    }
    List<GameDialogOption>? options;
    final optionData = data['option'];
    if (optionData != null) {
      options = [];
      for (final option in optionData) {
        final optionId = option['id'];
        final text = option['text'];
        final dlgOption = GameDialogOption(optionId, text);
        options.add(dlgOption);
      }
    }
    return GameDialogData(id: id, contents: contents, options: options);
  }
}
