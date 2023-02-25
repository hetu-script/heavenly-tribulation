import 'package:flutter/material.dart';

import '../../global.dart';
import 'package:samsara/ui/responsive_window.dart';
import '../util.dart';
import 'package:samsara/ui/close_button.dart';
import '../game_entity_listview.dart';
import '../view/character/information/character.dart';

const _kInformationViewCharacterColumns = [
  'name',
  'age',
  'currentLocation',
  'organization',
  'fame',
  // 'infamy',
];

class CharacterSelectDialog extends StatelessWidget {
  static Future<dynamic> show({
    required BuildContext context,
    required String title,
    Iterable<String>? characterIds,
    Iterable? charactersData,
    bool showCloseButton = true,
  }) async {
    return await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CharacterSelectDialog(
          title: title,
          characterIds: characterIds,
          charactersData: charactersData,
          showCloseButton: showCloseButton,
        );
      },
    );
  }

  const CharacterSelectDialog({
    super.key,
    required this.title,
    this.characterIds,
    this.charactersData,
    this.showCloseButton = true,
  });

  final String title;

  final Iterable<String>? characterIds;
  final Iterable? charactersData;

  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    Iterable chars;
    if (charactersData != null) {
      chars = charactersData!;
    } else {
      assert(characterIds != null);
      chars = engine.invoke('getCharacters', positionalArgs: [characterIds]);
    }

    final List<List<String>> data = [];
    for (final char in chars) {
      final row = <String>[];
      row.add(char['name']);
      final age =
          engine.invoke('getCharacterAgeString', positionalArgs: [char]);
      // 年龄
      row.add(age);
      // 当前所在地点
      row.add(getNameFromId(char['locationId']));
      // 门派名字
      row.add(getNameFromId(char['organizationId']));
      final fame =
          engine.invoke('getCharacterFameString', positionalArgs: [char]);
      // 名声
      row.add(fame);
      // 多存一个隐藏的 id 信息，用于点击事件
      row.add(char['id']);
      data.add(row);
    }

    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(title),
          actions: [if (showCloseButton) const ButtonClose()],
        ),
        body: GameEntityListView(
          columns: _kInformationViewCharacterColumns,
          tableData: data,
          onTap: (dataId) => showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => CharacterView(
              characterId: dataId,
              showConfirmButton: true,
            ),
          ).then((value) {
            if (value != null) {
              Navigator.of(context).pop(value);
            }
          }),
        ),
      ),
    );
  }
}
