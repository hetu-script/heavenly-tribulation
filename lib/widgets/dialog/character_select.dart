import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';

import '../../engine.dart';
import '../game_entity_listview.dart';
import '../character/profile.dart';
import '../ui/menu_builder.dart';
import '../character/details.dart';
import '../character/memory.dart';
import '../../game/ui.dart';
import '../../common.dart';
import '../../game/logic.dart';
import '../common.dart';
import '../ui/close_button2.dart';

enum SelectCharacterPopUpMenuItems {
  select,
  checkProfile,
  checkStatsAndEquipments,
  checkMemory,
}

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
    for (final character in chars) {
      final row = GameLogic.getCharacterInformationRow(character);
      data.add(row);
    }

    void showProfile(String dataId) async {
      final result = await showDialog(
        context: context,
        builder: (context) => CharacterProfileView(
          characterId: dataId,
          mode: InformationViewMode.select,
          showIntimacy: true,
          showPersonality: false,
          showPosition: true,
          showRelationships: true,
        ),
      );
      if (result == dataId) {
        Navigator.of(context).pop(dataId);
      }
    }

    return ResponsiveView(
      backgroundColor: GameUI.backgroundColorOpaque,
      alignment: AlignmentDirectional.center,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(title),
          actions: [if (showCloseButton) const CloseButton2()],
        ),
        body: GameEntityListView(
          columns: kInformationViewCharacterColumns,
          tableData: data,
          onItemPressed: (position, dataId) async {
            showProfile(dataId);
          },
          onItemSecondaryPressed: (position, dataId) {
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
              onSelectedItem: (item) async {
                switch (item) {
                  case SelectCharacterPopUpMenuItems.select:
                    Navigator.of(context).pop(dataId);
                  case SelectCharacterPopUpMenuItems.checkProfile:
                    showProfile(dataId);
                  case SelectCharacterPopUpMenuItems.checkStatsAndEquipments:
                    showDialog(
                      context: context,
                      builder: (context) =>
                          CharacterDetailsView(characterId: dataId),
                    );
                  case SelectCharacterPopUpMenuItems.checkMemory:
                    showDialog(
                      context: context,
                      builder: (context) =>
                          CharacterMemoryView(characterId: dataId),
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
