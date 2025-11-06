import 'package:hetu_script/values.dart';
import 'package:samsara/game_dialog/game_dialog.dart';

import '../data/game.dart';
import '../global.dart';

extension DialogDataHelper on GameDialog {
  /// 简化模式的对话框接口，会根据情况自动包装需要的信息
  void pushDialog(
    dynamic localeKeys, {
    dynamic character,
    String? characterId,
    dynamic npc,
    String? npcId,
    bool isHero = false,
    String? nameId,
    String? name,
    bool hideName = false,
    String? icon,
    bool hideIcon = false,
    String? image,
    bool hideImage = false,
    dynamic interpolations,
    bool immediate = false,
  }) {
    // 这里 character 有可能是 null
    if (npcId != null || npc != null) {
      npc ??= GameData.game['npcs'][npcId];
      character ??= npc;
    } else {
      character ??=
          isHero ? GameData.hero : GameData.game['characters'][characterId];
    }
    icon ??= hideIcon ? null : character?['icon'];
    image ??= hideImage ? null : character?['illustration'];

    if (hideName) {
      name = '';
    } else {
      if (isHero) {
        name = engine.locale('me');
      } else {
        if (name == null) {
          if (nameId != null) {
            name = engine.locale(nameId);
          } else {
            if (character != null) {
              if (character['entityType'] == 'character') {
                final heroHaveMetChar = engine.hetu.invoke('haveMet',
                    positionalArgs: [GameData.hero, character]);
                if (heroHaveMetChar == null || heroHaveMetChar == false) {
                  if (character['titleId'] != null) {
                    name = engine.locale(character['titleId']);
                  } else {
                    name = '???';
                  }
                } else {
                  name = character['name'];
                }
              } else {
                name = character['name'];
              }
            }
          }
        }
      }
    }

    List<String> strings = [];
    if (localeKeys is List) {
      assert(localeKeys.isNotEmpty);
      strings = localeKeys
          .map((key) => engine.locale(key, interpolations: interpolations))
          .toList();
    } else if (localeKeys is String) {
      strings = [engine.locale(localeKeys, interpolations: interpolations)];
    } else {
      throw 'Dialog.pushDialog: localeKeys must be a String or a List<String>.';
    }
    List lines = [];
    for (final line in strings) {
      final splits = line.split('\n');
      for (final split in splits) {
        final trim = split.trim();
        if (trim.isNotEmpty) {
          lines.add(trim);
        }
      }
    }

    pushDialogRaw(
      {
        'name': name,
        'icon': icon,
        'lines': lines,
      },
      imageId: image,
    );
  }

  /// 简易版本的选择对话框，localeId是一个字符串列表或[Map<String, String>]，
  void pushSelection(String id, dynamic locales) {
    final selections = {};
    if (locales is List) {
      for (final value in locales) {
        if (value is String) {
          selections[value] = engine.locale(value);
        } else if (value is Map || value is HTStruct) {
          assert(value['text'] != null,
              'Dialog.pushSelection: invalid selection value data, text is null. $value');
          final keyData = {};
          keyData['text'] = engine.locale(value['text']);
          keyData['description'] = engine.locale(value['description']);
          selections[value['text']] = keyData;
        } else {
          throw 'Dialog.pushSelection: locales must be a List<String> or a Map<String, String>.';
        }
      }
    } else if (locales is Map || locales is HTStruct) {
      for (final key in locales.keys) {
        final value = locales[key];
        assert(value is Map || value is HTStruct,
            'Dialog.pushSelection: invalid selection data. $value');
        final keyData = {};
        if (value['text'] != null) {
          keyData['text'] = engine.locale(value['text']);
        } else {
          keyData['text'] = engine.locale(key);
        }
        keyData['description'] = engine.locale(value['description']);
        selections[key] = keyData;
      }
    } else {
      throw 'Dialog.pushSelection: locales must be a List<String> or a Map<String, String>.';
    }
    return pushSelectionRaw({'id': id, 'selections': selections});
  }
}
