import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:samsara/widgets/ui/label.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
// import 'package:samsara/console.dart';
import 'package:samsara/extensions.dart';

import '../../ui.dart';
// import '../../game/logic/logic.dart';
import '../../data/game.dart';
import '../../engine.dart';
import '../../widgets/load_game.dart';
import 'create_sandbox_game.dart';
import '../world/widgets/create_blank_map.dart';
import '../../state/states.dart';
import '../common.dart';
import '../../widgets/ui/menu_builder.dart';
import '../../widgets/character/details.dart';
import '../../data/common.dart';
// import '../../widgets/ui/close_button2.dart';

enum DebugMenuItems {
  debugConsole,
  debugResetHero,
  debugItem,
  debugMerchant,
  debugMaterialMerchant,
  debugWorkbench,
  debugAlchemy,
  debugMeeting,
  debugMatchingGame,
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
            height: 360.0,
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
                        onPressed: null,
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
                          setMenuState(MenuStates.main);
                          // 这里必须延迟一会儿，否则界面会卡住而无法及时显示载入界面
                          engine.setLoading(true,
                              tip: engine.locale(kTips.random));
                          await Future.delayed(
                              const Duration(milliseconds: 250));
                          await engine.clearAllCachedScene(
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
                          setMenuState(MenuStates.main);
                          // 这里必须延迟一会儿，否则界面会卡住而无法及时显示载入界面
                          engine.setLoading(true,
                              tip: engine.locale(kTips.random));
                          await Future.delayed(
                              const Duration(milliseconds: 250));
                          await engine.clearAllCachedScene(
                              except: Scenes.mainmenu, triggerOnStart: false);
                          await GameData.createGame(
                            args['saveName'],
                            arguments: args,
                            seed: args['seed'],
                            mainWorldId: args['id'],
                            enableTutorial: args['enableTutorial'],
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
                          setMenuState(MenuStates.main);
                          GameData.loadGame(info);
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
                            builder: (context) =>
                                const CreateBlankMapDialog(isNewGame: true),
                          );
                          if (args == null) return;
                          setMenuState(MenuStates.main);
                          // 这里必须延迟一会儿，否则界面会卡住而无法及时显示载入界面
                          engine.setLoading(true,
                              tip: engine.locale(kTips.random));
                          await Future.delayed(
                              const Duration(milliseconds: 250));
                          await engine.clearAllCachedScene(
                              except: Scenes.mainmenu, triggerOnStart: false);
                          await GameData.createGame(
                            args['saveName'],
                            arguments: args,
                            seed: args['seed'],
                            mainWorldId: args['id'],
                            isEditorMode: true,
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
                          setMenuState(MenuStates.main);
                          GameData.loadGame(info, isEditorMode: true);
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
      width: GameUI.infoButtonSize.width,
      height: GameUI.infoButtonSize.height,
      child: fluent.FlyoutTarget(
        controller: menuController,
        child: IconButton(
          icon: const Icon(Icons.menu_open, size: 20.0),
          mouseCursor: GameUI.cursor.resolve({WidgetState.hovered}),
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
                '___3': null,
                engine.locale('debugMatchingGame'):
                    DebugMenuItems.debugMatchingGame,
              },
              onSelectedItem: (DebugMenuItems item) async {
                switch (item) {
                  case DebugMenuItems.debugConsole:
                    GameUI.showConsole(context);
                  case DebugMenuItems.debugResetHero:
                    await engine.clearAllCachedScene(
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
                  case DebugMenuItems.debugMatchingGame:
                    engine.pushScene(
                      Scenes.matchingGame,
                      arguments: {
                        'kind': kProductionSiteKinds.random,
                        'isProduction': math.Random().nextBool(),
                      },
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
