import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:samsara/ui/label.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';
// import 'package:samsara/console.dart';
import 'package:samsara/extensions.dart';

import '../../game/ui.dart';
// import '../../game/logic/logic.dart';
import '../../game/game.dart';
import '../../engine.dart';
import 'load_game.dart';
import 'create_sandbox_game.dart';
import 'create_blank_map.dart';
import '../../state/states.dart';
import '../common.dart';
import '../../widgets/ui/menu_builder.dart';
import '../../widgets/character/details.dart';
import '../../game/common.dart';
// import '../../widgets/ui/close_button2.dart';

enum DebugMenuItems {
  // debugConsole,
  debugResetHero,
  debugItem,
  debugMerchant,
  debugMaterialMerchant,
  debugWorkbench,
  debugAlchemy,
  debugMeeting,
}

enum MenuStates {
  main,
  editor,
  game,
}

class MainMenuButtons extends StatefulWidget {
  const MainMenuButtons({
    super.key,
  });

  @override
  State<MainMenuButtons> createState() => _MainMenuButtonsState();
}

class _MainMenuButtonsState extends State<MainMenuButtons> {
  // dynamic _heroData;

  MenuStates _state = MenuStates.main;
  void setMenuState(MenuStates state) {
    setState(() {
      _state = state;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SizedBox(
          width: GameUI.size.x,
          height: GameUI.size.y,
          child: const Image(
            image: AssetImage('assets/images/title_background.gif'),
            fit: BoxFit.cover,
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.only(top: 200.0),
            child: Image(
              image: AssetImage('assets/images/title2.png'),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 400.0,
            width: 200.0,
            padding: const EdgeInsets.only(bottom: 20.0),
            child: Column(
              children: switch (_state) {
                MenuStates.main => [
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.FilledButton(
                        onPressed: () {
                          setMenuState(MenuStates.game);
                        },
                        child: Label(
                          engine.locale('startGame'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.FilledButton(
                        onPressed: () {
                          setMenuState(MenuStates.editor);
                        },
                        child: Label(
                          engine.locale('editors'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.FilledButton(
                        onPressed: () {},
                        child: Label(
                          engine.locale('settings'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.FilledButton(
                        onPressed: () {
                          windowManager.close();
                        },
                        child: Label(
                          engine.locale('exit'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                MenuStates.game => [
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.FilledButton(
                        onPressed: () async {
                          engine.setLoading(true,
                              tip: engine.locale(kTips.random));
                          // 这里必须延迟一会儿，否则界面会卡住而无法及时显示载入界面
                          await Future.delayed(
                              const Duration(milliseconds: 250));
                          setMenuState(MenuStates.main);
                          engine.clearAllCachedScene(
                              except: Scenes.mainmenu, triggerOnStart: false);
                          engine.hetu.invoke('resetDungeon', namedArgs: {
                            'rank': GameData.hero['rank'],
                          });
                          engine.pushScene(
                            'dungeon_1',
                            constructorId: Scenes.worldmap,
                            arguments: {
                              'id': 'dungeon_1',
                              'method': 'load',
                            },
                            onAfterLoaded: () {
                              engine.setLoading(false);
                            },
                          );
                        },
                        child: Label(
                          engine.locale('endlessMode'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.FilledButton(
                        onPressed: () async {
                          final args = await showDialog(
                            context: context,
                            builder: (context) =>
                                const CreateSandboxGameDialog(),
                          );
                          if (args == null) return;
                          engine.setLoading(true,
                              tip: engine.locale(kTips.random));
                          // 这里必须延迟一会儿，否则界面会卡住而无法及时显示载入界面
                          await Future.delayed(
                              const Duration(milliseconds: 250));
                          setMenuState(MenuStates.main);
                          engine.clearAllCachedScene(
                              except: Scenes.mainmenu, triggerOnStart: false);
                          await GameData.createGame(
                            args['saveName'],
                            seed: args['seed'],
                            mainWorldId: args['id'],
                            enableTutorial: args['enableTutorial'],
                          );
                          engine.pushScene(
                            args['id'],
                            constructorId: Scenes.worldmap,
                            arguments: args,
                            onAfterLoaded: () {
                              engine.setLoading(false);
                            },
                          );
                        },
                        child: Label(
                          engine.locale('sandboxMode'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.FilledButton(
                        onPressed: null,
                        // () async {
                        //   context
                        //       .read<HeroInfoVisibilityState>()
                        //       .setVisible(false);
                        //  // 这里必须延迟一会儿，否则界面会卡住而无法及时显示载入界面
                        // await Future.delayed(
                        //     const Duration(milliseconds: 250));
                        //   setMenuState(MenuStates.main);
                        //   engine.clearAllCachedScene(except: Scenes.mainmenu, triggerOnStart: false);

                        //   await GameData.loadPreset('story');
                        //   engine.pushScene(
                        //     'prelude',
                        //     constructorId: Scenes.worldmap,
                        //     arguments: const {
                        //       'id': 'prelude',
                        //       'savePath': 'save',
                        //       'method': 'preset',
                        //     },
                        //   );
                        // },
                        child: Label(
                          engine.locale('storyMode'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.FilledButton(
                        onPressed: () async {
                          final SaveInfo? info = await showDialog<SaveInfo?>(
                            context: context,
                            builder: (context) => const LoadGameDialog(),
                          );
                          if (info == null) return;
                          engine.setLoading(true,
                              tip: engine.locale(kTips.random));
                          // 这里必须延迟一会儿，否则界面会卡住而无法及时显示载入界面
                          await Future.delayed(
                              const Duration(milliseconds: 250));
                          setMenuState(MenuStates.main);
                          engine.clearAllCachedScene(
                              except: Scenes.mainmenu, triggerOnStart: false);
                          final sceneIds =
                              await GameData.loadGame(info.savePath);
                          if (sceneIds.isNotEmpty) {
                            for (var i = 0; i < sceneIds.length; ++i) {
                              final sceneId = sceneIds[i];
                              final constructorId =
                                  engine.cachedConstructorIds[sceneId];
                              final arguments = engine.cachedArguments[sceneId];
                              if (constructorId == Scenes.worldmap) {
                                await engine.pushScene(
                                  info.currentWorldId,
                                  constructorId: Scenes.worldmap,
                                  arguments: {
                                    'id': info.currentWorldId,
                                    'savePath': info.savePath,
                                    'method': 'load',
                                  },
                                  onAfterLoaded: i == sceneIds.length - 1
                                      ? () {
                                          engine.setLoading(false);
                                        }
                                      : null,
                                );
                              } else {
                                await engine.pushScene(
                                  sceneId,
                                  constructorId: constructorId,
                                  arguments: arguments,
                                  onAfterLoaded: i == sceneIds.length - 1
                                      ? () {
                                          engine.setLoading(false);
                                        }
                                      : null,
                                );
                              }
                            }
                          } else {
                            await engine.pushScene(
                              info.currentWorldId,
                              constructorId: Scenes.worldmap,
                              arguments: {
                                'id': info.currentWorldId,
                                'savePath': info.savePath,
                                'method': 'load',
                              },
                              onAfterLoaded: () {
                                engine.setLoading(false);
                              },
                            );
                          }
                        },
                        child: Label(
                          engine.locale('load'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.FilledButton(
                        onPressed: () {
                          setMenuState(MenuStates.main);
                        },
                        child: Label(
                          engine.locale('goBack'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                MenuStates.editor => [
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.FilledButton(
                        onPressed: () async {
                          final args = await showDialog(
                            context: context,
                            builder: (context) => const CreateBlankMapDialog(
                              isCreatingNewGame: true,
                              isEditorMode: true,
                            ),
                          );
                          if (args == null) return;
                          engine.setLoading(true,
                              tip: engine.locale(kTips.random));
                          // 这里必须延迟一会儿，否则界面会卡住而无法及时显示载入界面
                          await Future.delayed(
                              const Duration(milliseconds: 250));
                          setMenuState(MenuStates.main);
                          engine.clearAllCachedScene(
                              except: Scenes.mainmenu, triggerOnStart: false);
                          await GameData.createGame(
                            args['saveName'],
                            seed: args['seed'],
                            mainWorldId:
                                args['isMain'] == true ? args['id'] : null,
                            isEditorMode: true,
                          );
                          engine.pushScene(
                            args['id'],
                            constructorId: Scenes.worldmap,
                            arguments: args,
                            onAfterLoaded: () {
                              engine.setLoading(false);
                            },
                          );
                        },
                        child: Label(
                          engine.locale('createMap'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.FilledButton(
                        onPressed: () async {
                          final SaveInfo? info = await showDialog<SaveInfo?>(
                            context: context,
                            builder: (context) => const LoadGameDialog(),
                          );
                          if (info == null) return;
                          engine.setLoading(true,
                              tip: engine.locale(kTips.random));
                          // 这里必须延迟一会儿，否则界面会卡住而无法及时显示载入界面
                          await Future.delayed(
                              const Duration(milliseconds: 250));
                          setMenuState(MenuStates.main);
                          engine.clearAllCachedScene(
                              except: Scenes.mainmenu, triggerOnStart: false);
                          await GameData.loadGame(
                            info.savePath,
                            isEditorMode: true,
                          );
                          engine.pushScene(
                            info.currentWorldId,
                            constructorId: Scenes.worldmap,
                            arguments: {
                              'id': info.currentWorldId,
                              'method': 'load',
                              'savePath': info.savePath,
                              'isEditorMode': true,
                            },
                            onAfterLoaded: () {
                              engine.setLoading(false);
                            },
                          );
                        },
                        child: Label(
                          engine.locale('load'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.FilledButton(
                        onPressed: () {
                          setMenuState(MenuStates.main);
                        },
                        child: Label(
                          engine.locale('goBack'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
              },
            ),
          ),
        ),
      ],
    );
  }
}

class DebugButton extends StatefulWidget {
  const DebugButton({super.key});

  @override
  State<DebugButton> createState() => _DebugButtonState();
}

class _DebugButtonState extends State<DebugButton> {
  final menuController = fluent.FlyoutController();

  @override
  void dispose() {
    super.dispose();

    menuController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: GameUI.foregroundColor),
      ),
      child: fluent.FlyoutTarget(
        controller: menuController,
        child: IconButton(
          icon: const Icon(Icons.menu_open, size: 20.0),
          mouseCursor: FlutterCustomMemoryImageCursor(key: 'click'),
          padding: const EdgeInsets.all(0),
          onPressed: () {
            showFluentMenu(
              controller: menuController,
              items: {
                // engine.locale('console'): DebugMenuItems.debugConsole,
                engine.locale('debugResetHero'): DebugMenuItems.debugResetHero,
                engine.locale('debugItem'): DebugMenuItems.debugItem,
                '___1': null,
                engine.locale('debugMerchant'): DebugMenuItems.debugMerchant,
                engine.locale('debugMaterialMerchant'):
                    DebugMenuItems.debugMaterialMerchant,
                engine.locale('debugWorkbench'): DebugMenuItems.debugWorkbench,
                engine.locale('debugAlchemy'): DebugMenuItems.debugAlchemy,
                '___2': null,
                engine.locale('debugMeeting'): DebugMenuItems.debugMeeting,
              },
              onSelectedItem: (DebugMenuItems item) {
                switch (item) {
                  // case DebugMenuItems.debugConsole:
                  //   showDialog(
                  //     context: context,
                  //     builder: (BuildContext context) => Console(
                  //       engine: engine,
                  //       margin: const EdgeInsets.all(50.0),
                  //       backgroundColor: GameUI.backgroundColor2,
                  //       closeButton: CloseButton2(),
                  //     ),
                  //   );
                  case DebugMenuItems.debugResetHero:
                    engine.clearAllCachedScene(
                      except: Scenes.mainmenu,
                      arguments: {'reset': true},
                      triggerOnStart: true,
                    );
                  case DebugMenuItems.debugItem:
                    engine.hetu.invoke('testItem', namespace: 'Debug');
                  case DebugMenuItems.debugMerchant:
                    final merchant =
                        engine.hetu.invoke('BattleEntity', namedArgs: {
                      'rank': 2,
                      'level': 10,
                    });
                    engine.hetu.invoke('entityCollect', positionalArgs: [
                      merchant,
                      'money',
                      50000,
                    ]);
                    engine.hetu.invoke('entityCollect',
                        positionalArgs: [merchant, 'shard', 500]);
                    engine.hetu.invoke('testItem',
                        namespace: 'Debug', positionalArgs: [merchant]);
                    context.read<MerchantState>().show(
                          merchant,
                          useShard: true,
                          priceFactor: <String, dynamic>{
                            'base': 1.2,
                          },
                          merchantType: MerchantType.character,
                        );
                  case DebugMenuItems.debugMaterialMerchant:
                    final merchant =
                        engine.hetu.invoke('BattleEntity', namedArgs: {
                      'rank': 2,
                      'level': 10,
                    });
                    engine.hetu.invoke('entityCollect',
                        positionalArgs: [merchant, 'money', 50000]);
                    engine.hetu.invoke('entityCollect',
                        positionalArgs: [merchant, 'shard', 500]);
                    for (final materialId in kOtherMaterials) {
                      engine.hetu.invoke('entityCollect',
                          positionalArgs: [merchant, materialId, 500]);
                    }
                    context.read<MerchantState>().show(
                      merchant,
                      materialMode: true,
                      priceFactor: <String, dynamic>{
                        'base': 1.2,
                      },
                    );
                  case DebugMenuItems.debugWorkbench:
                    context.read<ViewPanelState>().toogle(ViewPanels.workbench);
                  case DebugMenuItems.debugAlchemy:
                    context.read<ViewPanelState>().toogle(ViewPanels.alchemy);
                  case DebugMenuItems.debugMeeting:
                    final people = [];
                    for (var i = 0; i < 5; ++i) {
                      final char = engine.hetu.invoke('Character');
                      people.add(char);
                    }
                    context.read<MeetingState>().update(people);
                }
              },
            );
          },
        ),
      ),
    );
  }
}
