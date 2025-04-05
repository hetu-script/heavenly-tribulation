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
import '../../game/logic.dart';
import '../../widgets/menu_item_builder.dart';

enum DebugMenuItems {
  debugResetHero,
  debugDialog,
  debugItem,
  debugQuest,
  debugMerchant,
  debugCompanion,
  debugBattle,
  debugTribulation,
  debugAutoAllocateSkills,
}

List<PopupMenuEntry<DebugMenuItems>> buildDebugMenuItems(
    {void Function(DebugMenuItems item)? onSelectedItem}) {
  return <PopupMenuEntry<DebugMenuItems>>[
    buildMenuItem(
      item: DebugMenuItems.debugResetHero,
      name: engine.locale('debugResetHero'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: DebugMenuItems.debugDialog,
      name: engine.locale('debugDialog'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: DebugMenuItems.debugItem,
      name: engine.locale('debugItem'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: DebugMenuItems.debugQuest,
      name: engine.locale('debugQuest'),
      onSelectedItem: onSelectedItem,
    ),
    const PopupMenuDivider(),
    buildMenuItem(
      item: DebugMenuItems.debugMerchant,
      name: engine.locale('debugMerchant'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: DebugMenuItems.debugCompanion,
      name: engine.locale('debugCompanion'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: DebugMenuItems.debugBattle,
      name: engine.locale('debugBattle'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: DebugMenuItems.debugTribulation,
      name: engine.locale('debugTribulation'),
      onSelectedItem: onSelectedItem,
    ),
    buildMenuItem(
      item: DebugMenuItems.debugAutoAllocateSkills,
      name: engine.locale('debugAutoAllocateSkills'),
      onSelectedItem: onSelectedItem,
    ),
  ];
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
            image: AssetImage('assets/images/title2.gif'),
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
                          engine.clearAllCachedScene(except: Scenes.mainmenu);

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
                          setMenuState(MenuStates.main);
                          engine.clearAllCachedScene(except: Scenes.mainmenu);

                          await GameData.createGame(args['saveName']);
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
                          setMenuState(MenuStates.main);
                          engine.clearAllCachedScene(except: Scenes.mainmenu);
                          engine.hetu.invoke('resetDungeon', namedArgs: {
                            'rank': 0,
                          });
                          engine.pushScene(
                            'dungeon_1',
                            constructorId: Scenes.worldmap,
                            arguments: {
                              'id': 'dungeon_1',
                              'method': 'load',
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
                      child: ElevatedButton(
                        onPressed: () async {
                          final SaveInfo? info = await showDialog<SaveInfo?>(
                            context: context,
                            builder: (context) => const LoadGameDialog(),
                          );
                          if (info == null) return;
                          setMenuState(MenuStates.main);
                          engine.clearAllCachedScene(except: Scenes.mainmenu);
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
                            builder: (context) => const CreateBlankMapDialog(
                              isCreatingNewGame: true,
                              isEditorMode: true,
                            ),
                          );
                          if (args == null) return;
                          setMenuState(MenuStates.main);
                          engine.clearAllCachedScene(except: Scenes.mainmenu);
                          await GameData.createGame(
                            args['saveName'],
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
                          engine.clearAllCachedScene(except: Scenes.mainmenu);
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
      ],
    );
  }
}

class DebugButton extends StatelessWidget {
  const DebugButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(color: GameUI.foregroundColor),
      ),
      child: PopupMenuButton<DebugMenuItems>(
        padding: EdgeInsets.zero,
        offset: const Offset(0, 45),
        icon: const Icon(Icons.menu_open, size: 20.0),
        tooltip: engine.locale('debugMode'),
        onSelected: (item) {
          switch (item) {
            case DebugMenuItems.debugResetHero:
              context.read<HeroState>().update();
              engine.clearAllCachedScene(
                except: Scenes.mainmenu,
                arguments: {'reset': true},
                restart: true,
              );
              context.read<NpcListState>().update();
            case DebugMenuItems.debugDialog:
              engine.hetu.invoke('debugDialog', namespace: 'Debug');
            case DebugMenuItems.debugItem:
              engine.hetu.invoke('testItem', namespace: 'Debug');
            case DebugMenuItems.debugQuest:
              engine.hetu.invoke('testQuest', namespace: 'Debug');
            case DebugMenuItems.debugMerchant:
              final merchant = engine.hetu.invoke('Character', namedArgs: {
                'rank': 2,
                'level': 10,
              });
              engine.hetu.invoke('testItem',
                  namespace: 'Debug', positionalArgs: [merchant]);
              context.read<MerchantState>().show(merchant, priceFactor: {
                // 'useShard': true,
                // 'base': 0.5,
              });
            case DebugMenuItems.debugCompanion:
              final companion = engine.hetu.invoke('Character');
              engine.hetu.invoke(
                'accompany',
                namespace: 'Player',
                positionalArgs: [
                  companion,
                ],
              );
              context.read<NpcListState>().update([companion]);
            case DebugMenuItems.debugBattle:
              final enemy = engine.hetu.invoke('Character', namedArgs: {
                'isFemale': true,
                'level': GameData.heroData['level'],
                'rank': GameData.heroData['rank'],
              });
              GameLogic.characterAllocateSkills(enemy);
              engine.hetu.invoke('generateDeck', positionalArgs: [enemy]);
              context.read<EnemyState>().show(enemy);
            case DebugMenuItems.debugTribulation:
              final targetRank = GameData.heroData['rank'] + 1;
              final levelMin = GameLogic.minLevelForRank(targetRank);
              GameLogic.showTribulation(levelMin + 5, targetRank);
            case DebugMenuItems.debugAutoAllocateSkills:
              GameLogic.characterAllocateSkills(GameData.heroData);
          }
        },
        itemBuilder: (BuildContext context) => buildDebugMenuItems(),
      ),
    );
  }
}
