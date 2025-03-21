import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:samsara/ui/label.dart';
import 'package:provider/provider.dart';

import '../../game/ui.dart';
import '../../game/data.dart';
import '../../engine.dart';
import 'load_game.dart';
import 'create_sandbox_game.dart';
import 'create_blank_map.dart';
import '../../state/states.dart';
import '../common.dart';

enum MenuStates {
  main,
  editor,
  game,
}

enum DebugStates {
  main,
  debug1,
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

  DebugStates _debugState = DebugStates.main;
  void setDebugMenuState(DebugStates state) {
    setState(() {
      _debugState = state;
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
            image: AssetImage('assets/images/title2.gif'),
            fit: BoxFit.cover,
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            padding: const EdgeInsets.only(top: 200.0),
            child: Image(
              image: AssetImage('assets/images/title.png'),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 280.0,
            width: 180.0,
            padding: EdgeInsets.only(
              bottom: 20.0,
            ),
            child: Column(
              children: switch (_state) {
                MenuStates.main => [
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
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
                      child: ElevatedButton(
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
                      child: ElevatedButton(
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
                      child: ElevatedButton(
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
                      child: ElevatedButton(
                        onPressed: () async {
                          context
                              .read<HeroInfoVisibilityState>()
                              .setVisible(false);
                          setMenuState(MenuStates.main);

                          await GameData.loadPreset('story');
                          engine.pushScene(
                            'cave',
                            constructorId: Scenes.worldmap,
                            arguments: const {
                              'id': 'cave',
                              'savePath': 'save',
                              'method': 'preset',
                            },
                          );
                        },
                        child: Label(
                          engine.locale('storyMode'),
                          width: 150.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    // Padding(
                    //   padding: const EdgeInsets.only(top: 20.0),
                    //   child: ElevatedButton(
                    //     onPressed: () {},
                    //     child: Label(
                    //       engine.locale('storyMode'),
                    //       width: 150.0,
                    //       textAlign: TextAlign.center,
                    //     ),
                    //   ),
                    // ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          final args = await showDialog(
                            context: context,
                            builder: (context) =>
                                const CreateSandboxGameDialog(),
                          );
                          if (args == null) return;
                          if (context.mounted) {
                            context
                                .read<HeroInfoVisibilityState>()
                                .setVisible(false);
                          }
                          setMenuState(MenuStates.main);

                          await GameData.createGame(
                            args['id'],
                            saveName: args['saveName'],
                          );
                          engine.pushScene(
                            args['id'],
                            constructorId: Scenes.worldmap,
                            arguments: args,
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
                      child: ElevatedButton(
                        onPressed: () async {
                          final SaveInfo? info = await showDialog<SaveInfo?>(
                            context: context,
                            builder: (context) => const LoadGameDialog(),
                          );
                          if (info == null) return;
                          if (context.mounted) {
                            context
                                .read<HeroInfoVisibilityState>()
                                .setVisible(false);
                          }
                          setMenuState(MenuStates.main);

                          await GameData.loadGame(info.savePath);
                          engine.pushScene(
                            info.currentWorldId,
                            constructorId: Scenes.worldmap,
                            arguments: {
                              'id': info.currentWorldId,
                              'savePath': info.savePath,
                              'method': 'load',
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
                      child: ElevatedButton(
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
                      child: ElevatedButton(
                        onPressed: () async {
                          final args = await showDialog(
                            context: context,
                            builder: (context) => const CreateBlankMapDialog(),
                          );
                          if (args == null) return;
                          setMenuState(MenuStates.main);
                          await GameData.createGame(
                            args['id'],
                            saveName: args['saveName'],
                            isEditorMode: true,
                          );
                          engine.pushScene(
                            args['id'],
                            constructorId: Scenes.worldmap,
                            arguments: args,
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
                      child: ElevatedButton(
                        onPressed: () async {
                          final SaveInfo? info = await showDialog<SaveInfo?>(
                            context: context,
                            builder: (context) => const LoadGameDialog(),
                          );
                          if (info == null) return;
                          setMenuState(MenuStates.main);
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
                      child: ElevatedButton(
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
        Align(
          alignment: Alignment.topRight,
          child: Container(
            width: 180.0,
            padding: EdgeInsets.only(
              right: 20.0,
              bottom: 20.0,
            ),
            child: Column(
              children: switch (_debugState) {
                DebugStates.main => [
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setDebugMenuState(DebugStates.debug1);
                        },
                        child: Label(
                          engine.locale('debugMode'),
                          width: 200.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                DebugStates.debug1 => [
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setDebugMenuState(DebugStates.main);
                        },
                        child: Label(engine.locale('goBack'),
                            width: 200.0, textAlign: TextAlign.center),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: () async {
                          context.read<HeroState>().update();
                          engine.clearAllCachedScene(
                            except: Scenes.mainmenu,
                            arguments: {'reset': true},
                          );
                        },
                        child: Label(
                          engine.locale('debug_reset_hero'),
                          width: 200.0,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          engine.hetu.invoke('debugDialog', namespace: 'Debug');
                        },
                        child: Label(engine.locale('debug_dialog'),
                            width: 200.0, textAlign: TextAlign.center),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          engine.hetu.invoke('testItem', namespace: 'Debug');
                        },
                        child: Label(engine.locale('debug_item'),
                            width: 200.0, textAlign: TextAlign.center),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          engine.hetu.invoke('testQuest', namespace: 'Debug');
                        },
                        child: Label(engine.locale('debug_quest'),
                            width: 200.0, textAlign: TextAlign.center),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          final enemy =
                              engine.hetu.invoke('Character', namedArgs: {
                            'isFemale': false,
                            'level': 0,
                            'rank': 0,
                          });
                          engine.hetu
                              .invoke('generateDeck', positionalArgs: [enemy]);
                          context.read<EnemyState>().show(enemy);
                        },
                        child: Label(engine.locale('debug_battle'),
                            width: 200.0, textAlign: TextAlign.center),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          final merchant =
                              engine.hetu.invoke('Character', namedArgs: {
                            'rank': 2,
                            'level': 10,
                          });
                          engine.hetu.invoke('testItem',
                              namespace: 'Debug', positionalArgs: [merchant]);
                          context
                              .read<MerchantState>()
                              .show(merchant, priceFactor: {
                            // 'useShard': true,
                            // 'base': 0.5,
                          });
                        },
                        child: Label(engine.locale('debug_merchant'),
                            width: 200.0, textAlign: TextAlign.center),
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
