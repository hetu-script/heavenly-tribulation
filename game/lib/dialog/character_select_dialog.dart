import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_window.dart';

import '../config.dart';
import '../util.dart';
import '../view/game_entity_listview.dart';
import '../view/character/profile.dart';
import '../view/menu_item_builder.dart';
import '../view/character/equipments_and_stats.dart';
import '../view/character/memory.dart';

enum SelectCharacterPopUpMenuItems {
  select,
  checkProfile,
  checkEquipments,
  checkMemory,
}

List<PopupMenuEntry<SelectCharacterPopUpMenuItems>>
    buildSelectCharacterPopUpMenuItems(
        {void Function(SelectCharacterPopUpMenuItems item)? onItemPressed}) {
  return <PopupMenuEntry<SelectCharacterPopUpMenuItems>>[
    buildMenuItem(
      item: SelectCharacterPopUpMenuItems.select,
      name: engine.locale('select'),
      onItemPressed: onItemPressed,
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: SelectCharacterPopUpMenuItems.checkProfile,
      name: engine.locale('checkInformation'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: SelectCharacterPopUpMenuItems.checkEquipments,
      name: engine.locale('checkEquipments'),
      onItemPressed: onItemPressed,
    ),
    buildMenuItem(
      item: SelectCharacterPopUpMenuItems.checkMemory,
      name: engine.locale('checkMemory'),
      onItemPressed: onItemPressed,
    ),
  ];
}

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
      // 当前所在地点
      row.add(getNameFromId(char['locationId']));
      // 门派名字
      row.add(getNameFromId(char['organizationId'], 'none'));
      final fame =
          engine.hetu.invoke('getCharacterFameString', positionalArgs: [char]);
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
          actions: [if (showCloseButton) const CloseButton()],
        ),
        body: GameEntityListView(
          columns: _kInformationViewCharacterColumns,
          tableData: data,
          onItemPressed: (buttons, position, dataId) {
            final menuPosition = RelativeRect.fromLTRB(
                position.dx, position.dy, position.dx, 0.0);
            final items =
                buildSelectCharacterPopUpMenuItems(onItemPressed: (item) {
              switch (item) {
                case SelectCharacterPopUpMenuItems.select:
                  Navigator.of(context).pop(dataId);
                case SelectCharacterPopUpMenuItems.checkProfile:
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => ProfileView(characterId: dataId),
                  );
                case SelectCharacterPopUpMenuItems.checkEquipments:
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) =>
                        EquipmentsAndStatsView(characterId: dataId),
                  );
                case SelectCharacterPopUpMenuItems.checkMemory:
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) => MemoryView(characterId: dataId),
                  );
              }
            });
            showMenu(
              context: context,
              position: menuPosition,
              items: items,
            );
          },
        ),
      ),
    );
  }
}
