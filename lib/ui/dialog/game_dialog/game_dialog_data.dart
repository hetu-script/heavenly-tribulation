class GameDialogContent {
  final List<String> lines;
  final String? avatar;

  GameDialogContent({required this.lines, this.avatar});
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
    final contentData = data['contents'];
    for (final content in contentData) {
      final avatar = content['avatar'];
      final lines = <String>[];
      final linesData = content['lines'];
      for (final line in linesData) {
        lines.add(line);
      }
      final dlgContent = GameDialogContent(lines: lines, avatar: avatar);
      contents.add(dlgContent);
    }
    List<GameDialogOption>? options;
    final optionData = data['options'];
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
