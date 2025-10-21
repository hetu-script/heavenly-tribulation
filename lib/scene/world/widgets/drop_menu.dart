import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:provider/provider.dart';
import 'package:samsara/tilemap/tilemap.dart';

import '../../../widgets/ui/menu_builder.dart';
import '../../../ui.dart';
import '../../../engine.dart';
import '../../../data/game.dart';
import '../../game_dialog/game_dialog_content.dart';
import '../../../widgets/load_game.dart';
import '../../../widgets/information.dart';
import '../../../widgets/dialog/input_string.dart';
import '../../common.dart';
import 'create_blank_map.dart';
import '../../../logic/logic.dart';
import '../../../widgets/dialog/confirm.dart';
import 'expand_world_dialog.dart';
import '../../../state/states.dart';

enum ViewModeMenuItems {
  none,
  zone,
  city,
  nation,
}

class ViewModeMenuButton extends StatefulWidget {
  const ViewModeMenuButton({
    super.key,
    required this.map,
  });

  final TileMap map;

  @override
  State<ViewModeMenuButton> createState() => _ViewModeMenuButtonState();
}

class _ViewModeMenuButtonState extends State<ViewModeMenuButton> {
  final menuController = fluent.FlyoutController();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: GameUI.foregroundColor),
      ),
      margin: const EdgeInsets.only(left: 5.0),
      width: GameUI.infoButtonSize.width,
      height: GameUI.infoButtonSize.height,
      child: fluent.FlyoutTarget(
        controller: menuController,
        child: IconButton(
          icon: const Icon(Icons.dashboard, size: 20.0),
          mouseCursor: GameUI.cursor.resolve({WidgetState.hovered}),
          padding: const EdgeInsets.all(0),
          onPressed: () {
            showFluentMenu<ViewModeMenuItems>(
              controller: menuController,
              items: {
                engine.locale('none'): ViewModeMenuItems.none,
                engine.locale('continent'): ViewModeMenuItems.zone,
                engine.locale('city'): ViewModeMenuItems.city,
                engine.locale('organization'): ViewModeMenuItems.nation,
              },
              onSelectedItem: (ViewModeMenuItems item) async {
                switch (item) {
                  case ViewModeMenuItems.none:
                    widget.map.colorMode = kColorModeNone;
                  case ViewModeMenuItems.zone:
                    widget.map.colorMode = kColorModeZone;
                  case ViewModeMenuItems.city:
                    widget.map.colorMode = kColorModeCity;
                  case ViewModeMenuItems.nation:
                    widget.map.colorMode = kColorModeNation;
                }
              },
            );
          },
        ),
      ),
    );
  }
}

enum DropMenuItems {
  save,
  saveAs,
  load,
  info,
  console,
  exit,
  addWorld,
  switchWorld,
  deleteWorld,
  expandWorld,
  regenerateZone,
  updateCharacterStats,
  reloadGameData,
  saveMapAs,
}

class DropMenuButton extends StatefulWidget {
  const DropMenuButton({
    super.key,
    this.isEditorMode = false,
    this.map,
  });

  final bool isEditorMode;

  final TileMap? map;

  @override
  State<DropMenuButton> createState() => _DropMenuButtonState();
}

class _DropMenuButtonState extends State<DropMenuButton> {
  final menuController = fluent.FlyoutController();

  void _save(String saveName) async {
    String worldId = GameData.world['id'];
    final saveInfo =
        await context.read<GameSavesState>().saveGame(worldId, saveName);
    if (saveInfo != null) {
      GameDialogContent.show(
        context,
        engine.locale('savedSuccessfully', interpolations: [saveInfo.savePath]),
      );
    } else {
      GameDialogContent.show(
        context,
        engine.locale('saveFailed'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: GameUI.foregroundColor),
      ),
      margin: const EdgeInsets.only(left: 5.0),
      width: GameUI.infoButtonSize.width,
      height: GameUI.infoButtonSize.height,
      child: fluent.FlyoutTarget(
        controller: menuController,
        child: IconButton(
          icon: const Icon(Icons.menu_open, size: 20.0),
          mouseCursor: GameUI.cursor.resolve({WidgetState.hovered}),
          padding: const EdgeInsets.all(0),
          onPressed: () {
            showFluentMenu<DropMenuItems>(
              controller: menuController,
              items: {
                engine.locale('save'): DropMenuItems.save,
                engine.locale('saveAs'): DropMenuItems.saveAs,
                engine.locale('load'): DropMenuItems.load,
                if (widget.isEditorMode) ...{
                  '___01': null,
                  engine.locale('regenerateZone'): DropMenuItems.regenerateZone,
                  engine.locale('updateCharacterStats'):
                      DropMenuItems.updateCharacterStats,
                  engine.locale('reloadGameData'): DropMenuItems.reloadGameData,
                  engine.locale('saveMapAs'): DropMenuItems.saveMapAs,
                  '___02': null,
                  engine.locale('addWorld'): DropMenuItems.addWorld,
                  engine.locale('switchWorld'): DropMenuItems.switchWorld,
                  engine.locale('deleteWorld'): DropMenuItems.deleteWorld,
                  engine.locale('expandWorld'): DropMenuItems.expandWorld,
                },
                '___1': null,
                engine.locale('info'): DropMenuItems.info,
                '___2': null,
                engine.locale('console'): DropMenuItems.console,
                engine.locale('exit'): DropMenuItems.exit,
              },
              onSelectedItem: (DropMenuItems item) async {
                switch (item) {
                  case DropMenuItems.save:
                    widget.map?.saveComponentsFrameData();
                    String saveName = GameData.game['saveName'];
                    _save(saveName);
                  case DropMenuItems.saveAs:
                    widget.map?.saveComponentsFrameData();
                    final saveName = await showDialog(
                      context: context,
                      builder: (context) {
                        return InputStringDialog(
                          title: engine.locale('inputName'),
                        );
                      },
                    );
                    if (saveName == null) return;
                    GameData.game['saveName'] = saveName;
                    _save(saveName);
                  case DropMenuItems.load:
                    final SaveInfo? info = await showDialog<SaveInfo?>(
                      context: context,
                      builder: (context) => const LoadGameDialog(),
                    );
                    if (info == null) return;
                    GameData.loadGame(info);
                  case DropMenuItems.info:
                    showDialog(
                        context: context,
                        builder: (context) => const InformationView());
                  case DropMenuItems.console:
                    GameUI.showConsole(context);
                  case DropMenuItems.exit:
                    context.read<SelectedPositionState>().clear();
                    context.read<EditorToolState>().clear();
                    await engine.clearAllCachedScene(
                      except: Scenes.mainmenu,
                      arguments: {'reset': true},
                      triggerOnStart: true,
                    );
                  case DropMenuItems.addWorld:
                    final args = await showDialog(
                      context: context,
                      builder: (context) =>
                          CreateBlankMapDialog(isNewGame: false),
                    );
                    if (args == null) return;
                    engine.pushScene(args['id'],
                        constructorId: Scenes.worldmap, arguments: args);
                  case DropMenuItems.switchWorld:
                    final worldId = await GameLogic.selectWorld();
                    if (worldId == null) return;
                    if (worldId == GameData.world['id']) return;
                    engine.hetu
                        .invoke('setCurrentWorld', positionalArgs: [worldId]);

                    if (engine.hasScene(worldId)) {
                      engine.switchScene(worldId);
                    } else {
                      engine.pushScene(
                        worldId,
                        constructorId: Scenes.worldmap,
                        arguments: {
                          'id': worldId,
                          'method': 'load',
                          'isEditorMode': true,
                        },
                      );
                    }
                  case DropMenuItems.deleteWorld:
                    final worldId = await GameLogic.selectWorld();
                    if (worldId == null) return;
                    if (worldId == GameData.world['id']) {
                      GameDialogContent.show(
                        context,
                        engine.locale('cannotDeleteCurrentWorld'),
                      );
                      return;
                    }
                    final result = await showDialog<bool?>(
                      context: context,
                      builder: (context) => ConfirmDialog(
                          description: engine.locale('dangerOperationPrompt')),
                    );
                    if (result == true) {
                      engine.hetu
                          .invoke('deleteWorldById', positionalArgs: [worldId]);
                    }
                  case DropMenuItems.expandWorld:
                    final value = await showDialog<(int, int, String)>(
                        context: context,
                        builder: (context) => const ExpandWorldDialog());
                    if (value == null) return;
                    engine.hetu.invoke('expandCurrentWorldBySize',
                        positionalArgs: [value.$1, value.$2, value.$3]);
                    widget.map?.loadTerrainData();
                  case DropMenuItems.regenerateZone:
                    final count = GameLogic.generateZone(GameData.world);
                    engine.info('重新生成地图分区，共生成 $count 个分区');
                    engine.hetu
                        .invoke('nameZones', positionalArgs: [GameData.world]);
                    GameDialogContent.show(
                      context,
                      engine.locale(
                        'generatedZone',
                        interpolations: [count],
                      ),
                    );
                    if (widget.map != null) {
                      GameData.loadZoneColors(widget.map!);
                    }
                  case DropMenuItems.reloadGameData:
                    GameData.initGameData();
                    GameDialogContent.show(
                        context, engine.locale('reloadGameDataPrompt'));
                  case DropMenuItems.updateCharacterStats:
                    for (final character
                        in GameData.game['characters'].values) {
                      engine.hetu.invoke(
                        'characterCalculateStats',
                        positionalArgs: [character],
                        namedArgs: {
                          'reset': true,
                          'rejuvenate': true,
                        },
                      );
                    }
                    GameDialogContent.show(
                      context,
                      engine.locale('hint_updateCharacterStats'),
                    );
                  case DropMenuItems.saveMapAs:
                    String worldId = GameData.world['id'];
                    final saveName = await showDialog(
                      context: context,
                      builder: (context) {
                        return InputStringDialog(
                          title: engine.locale('inputName'),
                          value: worldId,
                        );
                      },
                    );
                    if (saveName == null) return;
                    final savePath = await context
                        .read<GameSavesState>()
                        .saveMap(worldId, saveName);
                    if (savePath != null) {
                      GameDialogContent.show(
                        context,
                        engine.locale('savedSuccessfully',
                            interpolations: [savePath]),
                      );
                    } else {
                      GameDialogContent.show(
                        context,
                        engine.locale('saveFailed'),
                      );
                    }
                }
              },
            );
          },
        ),
      ),
    );
  }
}
