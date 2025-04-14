import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/widgets/common.dart';
import 'package:samsara/ui/responsive_view.dart';

import '../../engine.dart';
// import '../../util.dart';
import '../game_entity_listview.dart';
import '../character/profile.dart';
import '../ui/menu_builder.dart';
import '../character/details.dart';
import '../character/memory.dart';
import '../../game/ui.dart';

enum SelectCharacterPopUpMenuItems {
  select,
  checkProfile,
  checkStatsAndEquipments,
  checkMemory,
}

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
    Iterable? charactersData,
    bool showCloseButton = true,
  }) async {
    return await showDialog<dynamic>(
      context: context,
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
      // row.add(getNameFromId(char['locationId']));
      // 门派名字
      row.add(char['organizationId'] ?? engine.locale('none'));
      final fame =
          engine.hetu.invoke('getCharacterFameString', positionalArgs: [char]);
      // 名声
      row.add(fame);
      // 多存一个隐藏的 id 信息，用于点击事件
      row.add(char['id']);
      data.add(row);
    }

    return ResponsiveView(
      backgroundColor: GameUI.backgroundColorOpaque,
      alignment: AlignmentDirectional.center,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(title),
          actions: [if (showCloseButton) const CloseButton()],
        ),
        body: GameEntityListView(
          columns: _kInformationViewCharacterColumns,
          tableData: data,
          onItemPressed: (position, dataId) {
            showFluentMenu(
              position: position,
              items: {
                engine.locale('select'): SelectCharacterPopUpMenuItems.select,
                '___': null,
                engine.locale('checkInformation'):
                    SelectCharacterPopUpMenuItems.checkProfile,
                engine.locale('checkStatsAndEquipments'):
                    SelectCharacterPopUpMenuItems.checkStatsAndEquipments,
                engine.locale('checkMemory'):
                    SelectCharacterPopUpMenuItems.checkMemory,
              },
              onSelectedItem: (item) {
                switch (item) {
                  case SelectCharacterPopUpMenuItems.select:
                    Navigator.of(context).pop(dataId);
                  case SelectCharacterPopUpMenuItems.checkProfile:
                    showDialog(
                      context: context,
                      builder: (context) => CharacterProfileView(
                        characterId: dataId,
                        mode: InformationViewMode.select,
                      ),
                    );
                  case SelectCharacterPopUpMenuItems.checkStatsAndEquipments:
                    showDialog(
                      context: context,
                      builder: (context) => CharacterDetails(
                        characterId: dataId,
                        mode: InformationViewMode.select,
                      ),
                    );
                  case SelectCharacterPopUpMenuItems.checkMemory:
                    showDialog(
                      context: context,
                      builder: (context) => CharacterMemory(
                        characterId: dataId,
                        mode: InformationViewMode.select,
                      ),
                    );
                }
              },
            );
          },
        ),
      ),
    );
  }
}
