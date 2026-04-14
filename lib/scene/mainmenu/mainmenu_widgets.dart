import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:samsara/widgets/ui/label.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/extensions.dart';
import 'package:samsara/widgets/ui/menu_builder.dart';

import '../../ui.dart';
import '../../data/game.dart';
import '../../global.dart';
import '../game_creation/load_game.dart';
import '../game_creation/create_sandbox_game.dart';
import '../game_creation/create_blank_map.dart';
import '../game_creation/game_settings.dart';
import '../game_creation/mods_list.dart';
import '../../state/states.dart';
import '../common.dart';
import '../../data/common.dart';

enum MenuStates {
  main,
  editor,
  game,
}

class MainMenuWidgets extends StatefulWidget {
  const MainMenuWidgets({
    super.key,
  });

  @override
  State<MainMenuWidgets> createState() => _MainMenuWidgetsState();
}

class _MainMenuWidgetsState extends State<MainMenuWidgets> {
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
                      child: fluent.Button(
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
                      child: fluent.Button(
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
                      child: fluent.Button(
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => const GameSettingsDialog(),
                          );
                        },
                        child: Label(
                          engine.locale('settings'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.Button(
                        onPressed: () async {
                          await showDialog(
                            context: context,
                            builder: (context) => const ModsListDialog(),
                          );
                        },
                        child: Label(
                          engine.locale('modsList'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: fluent.Button(
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
                      child: fluent.Button(
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
                      child: fluent.Button(
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
                      child: fluent.Button(
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
                      child: fluent.Button(
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
                      child: fluent.Button(
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
                      child: fluent.Button(
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
                      child: fluent.Button(
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
                      child: fluent.Button(
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
      decoration: GameUI.boxDecoration,
      width: GameUI.infoButtonSize.width,
      height: GameUI.infoButtonSize.height,
      child: fluent.FlyoutTarget(
        controller: menuController,
        child: IconButton(
          icon: Icon(Icons.menu_open),
          padding: const EdgeInsets.all(0),
          mouseCursor: GameUI.cursor.resolve({WidgetState.hovered}),
          onPressed: () {
            showFluentMenu(
              cursor: GameUI.cursor,
              controller: menuController,
              items: {
                'console': 'debugConsole',
                'chat': 'debugLlmChat',
                'resetHero': 'debugResetHero',
                'get item': 'debugItem',
                '___1': null,
                'merchant': 'debugMerchant',
                'workbench': 'debugWorkbench',
                'alchemy': 'debugAlchemy',
                '___2': null,
                'debugMeeting': 'debugMeeting',
                '___3': null,
                'debugMatchingGame': 'debugMatchingGame',
                'debugMatchingGame2': {
                  'easy': 'debugMatchingGame2_easy',
                  'normal': 'debugMatchingGame2_normal',
                  'challenging': 'debugMatchingGame2_challenging',
                  'hard': 'debugMatchingGame2_hard',
                  'tough': 'debugMatchingGame2_tough',
                  'brutal': 'debugMatchingGame2_brutal',
                },
                'debugDifferenceGame': {
                  'easy': 'debugDifferenceGame_easy',
                  'normal': 'debugDifferenceGame_normal',
                  'challenging': 'debugDifferenceGame_challenging',
                  'hard': 'debugDifferenceGame_hard',
                  'tough': 'debugDifferenceGame_tough',
                  'brutal': 'debugDifferenceGame_brutal',
                },
                'debugMouseMazeGame': {
                  'easy': 'debugMouseMazeGame_easy',
                  'normal': 'debugMouseMazeGame_normal',
                  'challenging': 'debugMouseMazeGame_challenging',
                  'hard': 'debugMouseMazeGame_hard',
                  'tough': 'debugMouseMazeGame_tough',
                  'brutal': 'debugMouseMazeGame_brutal',
                },
                'debugMemoryCardGame': {
                  'easy': 'debugMemoryCardGame_easy',
                  'normal': 'debugMemoryCardGame_normal',
                  'challenging': 'debugMemoryCardGame_challenging',
                  'hard': 'debugMemoryCardGame_hard',
                  'tough': 'debugMemoryCardGame_tough',
                  'brutal': 'debugMemoryCardGame_brutal',
                },
                'debugNanogramGame': {
                  'easy': 'debugNanogramGame_easy',
                  'normal': 'debugNanogramGame_normal',
                  'challenging': 'debugNanogramGame_challenging',
                  'hard': 'debugNanogramGame_hard',
                  'tough': 'debugNanogramGame_tough',
                  'brutal': 'debugNanogramGame_brutal',
                },
              },
              onSelectedItem: (String item) async {
                switch (item) {
                  case 'debugConsole':
                    GameUI.showConsole(context);
                  case 'debugLlmChat':
                    if (!engine.config.enableLlm) return;

                    final npc = engine.hetu.invoke('Character');
                    engine.hetu.invoke('characterMet',
                        positionalArgs: [npc, GameData.hero]);
                    if (!engine.baseInitialized) {
                      final worldInfo = GameData.getLlmChatSystemPrompt1();
                      await engine.prepareLlamaBaseState(worldInfo);
                    }
                    final prompt = GameData.getLlmChatSystemPrompt2(npc);
                    GameUI.showLlmChat(
                      context,
                      systemPrompt: prompt,
                      npc: npc,
                    );
                  case 'debugResetHero':
                    await engine.clearAllCachedScene(
                      except: Scenes.mainmenu,
                      arguments: {'reset': true},
                      triggerOnStart: true,
                    );
                  case 'debugItem':
                    engine.hetu.invoke('testItem', namespace: 'debug');
                  case 'debugMerchant':
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
                        namespace: 'debug', positionalArgs: [merchant]);
                    context.read<MerchantState>().show(
                          merchant,
                          useShard: true,
                          priceFactor: <String, dynamic>{
                            // 'base': 1.2,
                          },
                          merchantType: MerchantType.character,
                          allowManualReplenish: true,
                        );
                  case 'debugWorkbench':
                    final heroHomeSiteId = GameData.hero['homeSiteId'];
                    final location = GameData.getLocation(heroHomeSiteId);
                    location['development'] = 5;
                    context.read<ViewPanelState>().toogle(ViewPanels.workbench,
                        arguments: {'location': location});
                  case 'debugAlchemy':
                    final heroHomeSiteId = GameData.hero['homeSiteId'];
                    final location = GameData.getLocation(heroHomeSiteId);
                    location['development'] = 5;
                    context.read<ViewPanelState>().toogle(ViewPanels.alchemy,
                        arguments: {'location': location});
                  case 'debugMeeting':
                    final people = [];
                    for (var i = 0; i < 5; ++i) {
                      final char = engine.hetu.invoke('Character');
                      people.add(char);
                    }
                    context.read<MeetingState>().update(people);
                  case 'debugMatchingGame':
                    engine.pushScene(
                      Scenes.matchingGame,
                      arguments: {
                        'kind': kProductionSiteKinds.random,
                        'isProduction': math.Random().nextBool(),
                      },
                    );
                  case 'debugMatchingGame2_easy':
                    engine.pushScene(
                      Scenes.matchingGame2,
                      arguments: {'difficulty': 'easy'},
                    );
                  case 'debugMatchingGame2_normal':
                    engine.pushScene(
                      Scenes.matchingGame2,
                      arguments: {'difficulty': 'normal'},
                    );
                  case 'debugMatchingGame2_challenging':
                    engine.pushScene(
                      Scenes.matchingGame2,
                      arguments: {'difficulty': 'challenging'},
                    );
                  case 'debugMatchingGame2_hard':
                    engine.pushScene(
                      Scenes.matchingGame2,
                      arguments: {'difficulty': 'hard'},
                    );
                  case 'debugMatchingGame2_tough':
                    engine.pushScene(
                      Scenes.matchingGame2,
                      arguments: {'difficulty': 'tough'},
                    );
                  case 'debugMatchingGame2_brutal':
                    engine.pushScene(
                      Scenes.matchingGame2,
                      arguments: {'difficulty': 'brutal'},
                    );
                  case 'debugDifferenceGame_easy':
                    engine.pushScene(
                      Scenes.differenceGame,
                      arguments: {'difficulty': 'easy'},
                    );
                  case 'debugDifferenceGame_normal':
                    engine.pushScene(
                      Scenes.differenceGame,
                      arguments: {'difficulty': 'normal'},
                    );
                  case 'debugDifferenceGame_challenging':
                    engine.pushScene(
                      Scenes.differenceGame,
                      arguments: {'difficulty': 'challenging'},
                    );
                  case 'debugDifferenceGame_hard':
                    engine.pushScene(
                      Scenes.differenceGame,
                      arguments: {'difficulty': 'hard'},
                    );
                  case 'debugDifferenceGame_tough':
                    engine.pushScene(
                      Scenes.differenceGame,
                      arguments: {'difficulty': 'tough'},
                    );
                  case 'debugDifferenceGame_brutal':
                    engine.pushScene(
                      Scenes.differenceGame,
                      arguments: {'difficulty': 'brutal'},
                    );
                  case 'debugMouseMazeGame_easy':
                    engine.pushScene(
                      Scenes.mouseMazeGame,
                      arguments: {'difficulty': 'easy'},
                    );
                  case 'debugMouseMazeGame_normal':
                    engine.pushScene(
                      Scenes.mouseMazeGame,
                      arguments: {'difficulty': 'normal'},
                    );
                  case 'debugMouseMazeGame_challenging':
                    engine.pushScene(
                      Scenes.mouseMazeGame,
                      arguments: {'difficulty': 'challenging'},
                    );
                  case 'debugMouseMazeGame_hard':
                    engine.pushScene(
                      Scenes.mouseMazeGame,
                      arguments: {'difficulty': 'hard'},
                    );
                  case 'debugMouseMazeGame_tough':
                    engine.pushScene(
                      Scenes.mouseMazeGame,
                      arguments: {'difficulty': 'tough'},
                    );
                  case 'debugMouseMazeGame_brutal':
                    engine.pushScene(
                      Scenes.mouseMazeGame,
                      arguments: {'difficulty': 'brutal'},
                    );
                  case 'debugMemoryCardGame_easy':
                    engine.pushScene(
                      Scenes.memoryCardGame,
                      arguments: {'difficulty': 'easy'},
                    );
                  case 'debugMemoryCardGame_normal':
                    engine.pushScene(
                      Scenes.memoryCardGame,
                      arguments: {'difficulty': 'normal'},
                    );
                  case 'debugMemoryCardGame_challenging':
                    engine.pushScene(
                      Scenes.memoryCardGame,
                      arguments: {'difficulty': 'challenging'},
                    );
                  case 'debugMemoryCardGame_hard':
                    engine.pushScene(
                      Scenes.memoryCardGame,
                      arguments: {'difficulty': 'hard'},
                    );
                  case 'debugMemoryCardGame_tough':
                    engine.pushScene(
                      Scenes.memoryCardGame,
                      arguments: {'difficulty': 'tough'},
                    );
                  case 'debugMemoryCardGame_brutal':
                    engine.pushScene(
                      Scenes.memoryCardGame,
                      arguments: {'difficulty': 'brutal'},
                    );
                  case 'debugNanogramGame_easy':
                    engine.pushScene(
                      Scenes.nanogramGame,
                      arguments: {'difficulty': 'easy'},
                    );
                  case 'debugNanogramGame_normal':
                    engine.pushScene(
                      Scenes.nanogramGame,
                      arguments: {'difficulty': 'normal'},
                    );
                  case 'debugNanogramGame_challenging':
                    engine.pushScene(
                      Scenes.nanogramGame,
                      arguments: {'difficulty': 'challenging'},
                    );
                  case 'debugNanogramGame_hard':
                    engine.pushScene(
                      Scenes.nanogramGame,
                      arguments: {'difficulty': 'hard'},
                    );
                  case 'debugNanogramGame_tough':
                    engine.pushScene(
                      Scenes.nanogramGame,
                      arguments: {'difficulty': 'tough'},
                    );
                  case 'debugNanogramGame_brutal':
                    engine.pushScene(
                      Scenes.nanogramGame,
                      arguments: {'difficulty': 'brutal'},
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
