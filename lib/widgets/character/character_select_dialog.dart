import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';

import '../../engine.dart';
import '../game_entity_listview.dart';
import '../../game/ui.dart';
import 'profile.dart';
import '../common.dart';
import '../ui/close_button2.dart';

const _kInformationViewCharacterColumns = [
  'name',
  'age',
  // 'currentLocation',
  'organization',
  'fame',
  // 'infamy',
];

class CharacterSelectDialog extends StatelessWidget {
  static Future<dynamic> show({
    required BuildContext context,
    required String title,
    Iterable<String>? characterIds,
    Iterable? characters,
    bool showCloseButton = true,
  }) async {
    return await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return CharacterSelectDialog(
          title: title,
          characterIds: characterIds,
          characters: characters,
          showCloseButton: showCloseButton,
        );
      },
    );
  }

  const CharacterSelectDialog({
    super.key,
    required this.title,
    this.characterIds,
    this.characters,
    this.showCloseButton = true,
  });

  final String title;

  final Iterable<String>? characterIds;
  final Iterable? characters;

  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    Iterable chars;
    if (characters != null) {
      chars = characters!;
    } else {
      assert(characterIds != null);
      chars =
          engine.hetu.invoke('getCharacters', positionalArgs: [characterIds]);
    }

    final List<List<String>> data = [];
    for (final char in chars) {
      final row = <String>[];
      row.add(char['name']);
      final age =
          engine.hetu.invoke('getCharacterAgeString', positionalArgs: [char]);
      // 年龄
      row.add(age);
      // // 当前所在地点
      // row.add(char['locationId']);
      // 门派名字
      row.add(char['organizationId']);
      final fame =
          engine.hetu.invoke('getCharacterFameString', positionalArgs: [char]);
      // 名声
      row.add(fame);
      // 多存一个隐藏的 id 信息，用于点击事件
      row.add(char['id']);
      data.add(row);
    }

    return ResponsiveView(
      alignment: AlignmentDirectional.center,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(title),
          actions: [if (showCloseButton) const CloseButton2()],
        ),
        body: GameEntityListView(
          columns: _kInformationViewCharacterColumns,
          tableData: data,
          onItemPressed: (position, dataId) async {
            final value = await showDialog(
              context: context,
              builder: (context) {
                return ResponsiveView(
                  alignment: AlignmentDirectional.center,
                  width: GameUI.profileWindowSize.x,
                  height: 400.0,
                  child: CharacterProfile(
                    characterId: dataId,
                    mode: InformationViewMode.select,
                  ),
                );
              },
            );
            if (value != null) {
              Navigator.of(context).pop(value);
            }
          },
        ),
      ),
    );
  }
}
