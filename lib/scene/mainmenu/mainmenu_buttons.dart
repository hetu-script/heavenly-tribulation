import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:samsara/ui/label.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';
import 'package:samsara/console.dart';

import '../../game/ui.dart';
import '../../game/logic/logic.dart';
import '../../game/data.dart';
import '../../engine.dart';
import 'load_game.dart';
import 'create_sandbox_game.dart';
import 'create_blank_map.dart';
import '../../state/states.dart';
import '../common.dart';
import '../../widgets/ui/menu_builder.dart';
import '../../widgets/character/details.dart';
// import '../../game/common.dart';

enum DebugMenuItems {
  debugConsole,
  debugResetHero,
  debugItem,
  debugJournal,
  debugMerchant,
  debugMaterialMerchant,
  debugWorkbench,
  debugAlchemy,
  debugCompanion,
  debugBattle,
  debugTribulation,
  debugImmortalityTrial,
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
                          setMenuState(MenuStates.main);
                          engine.clearAllCachedScene(except: Scenes.mainmenu);
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
                          engine.setLoading(true);
                          setMenuState(MenuStates.main);
                          engine.clearAllCachedScene(except: Scenes.mainmenu);
                          // 这里必须延迟一会儿，否则会让界面卡住而不会显示载入界面
                          Future.delayed(const Duration(milliseconds: 250),
                              () async {
                            await GameData.createGame(
                              args['saveName'],
                              seedString: args['seedString'],
                              enableTutorial: args['enableTutorial'],
                            );
                            engine.pushScene(
                              args['id'],
                              constructorId: Scenes.worldmap,
                              arguments: args,
                            );
                          });
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
                        //   setMenuState(MenuStates.main);
                        //   engine.clearAllCachedScene(except: Scenes.mainmenu);

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
                          engine.setLoading(true);
                          setMenuState(MenuStates.main);
                          engine.clearAllCachedScene(except: Scenes.mainmenu);
                          // 这里必须延迟一会儿，否则会让界面卡住而不会显示载入界面
                          Future.delayed(const Duration(milliseconds: 250),
                              () async {
                            await GameData.createGame(
                              args['saveName'],
                              seedString: args['seedString'],
                              isEditorMode: true,
                            );
                            engine.pushScene(
                              args['id'],
                              constructorId: Scenes.worldmap,
                              arguments: args,
                            );
                          });
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
                engine.locale('console'): DebugMenuItems.debugConsole,
                engine.locale('debugResetHero'): DebugMenuItems.debugResetHero,
                engine.locale('debugItem'): DebugMenuItems.debugItem,
                engine.locale('debugJournal'): DebugMenuItems.debugJournal,
                '___1': null,
                engine.locale('debugMerchant'): DebugMenuItems.debugMerchant,
                engine.locale('debugMaterialMerchant'):
                    DebugMenuItems.debugMaterialMerchant,
                engine.locale('debugWorkbench'): DebugMenuItems.debugWorkbench,
                engine.locale('debugAlchemy'): DebugMenuItems.debugAlchemy,
                '___2': null,
                engine.locale('debugCompanion'): DebugMenuItems.debugCompanion,
                engine.locale('debugBattle'): DebugMenuItems.debugBattle,
                engine.locale('debugTribulation'):
                    DebugMenuItems.debugTribulation,
                engine.locale('debugImmortalityTrial'):
                    DebugMenuItems.debugImmortalityTrial,
              },
              onSelectedItem: (DebugMenuItems item) {
                switch (item) {
                  case DebugMenuItems.debugConsole:
                    showDialog(
                      context: context,
                      builder: (BuildContext context) => Console(
                        engine: engine,
                        margin: const EdgeInsets.all(50.0),
                        backgroundColor: GameUI.backgroundColor2,
                      ),
                    );
                  case DebugMenuItems.debugResetHero:
                    engine.clearAllCachedScene(
                      except: Scenes.mainmenu,
                      arguments: {'reset': true},
                      restart: true,
                    );
                  case DebugMenuItems.debugItem:
                    engine.hetu.invoke('testItem', namespace: 'Debug');
                  case DebugMenuItems.debugJournal:
                    engine.hetu.invoke('testJournal', namespace: 'Debug');
                  case DebugMenuItems.debugMerchant:
                    final merchant =
                        engine.hetu.invoke('BattleEntity', namedArgs: {
                      'rank': 2,
                      'level': 10,
                    });
                    engine.hetu.invoke('entityCollect', positionalArgs: [
                      merchant,
                      'money'
                    ], namedArgs: {
                      'amount': 50000,
                    });
                    engine.hetu.invoke('entityCollect', positionalArgs: [
                      merchant,
                      'shard'
                    ], namedArgs: {
                      'amount': 500,
                    });
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
                    engine.hetu.invoke('entityCollect', positionalArgs: [
                      merchant,
                      'money'
                    ], namedArgs: {
                      'amount': 50000,
                    });
                    engine.hetu.invoke('entityCollect', positionalArgs: [
                      merchant,
                      'shard'
                    ], namedArgs: {
                      'amount': 500,
                    });
                    for (final materialId in kOtherMaterials) {
                      engine.hetu.invoke('entityCollect', positionalArgs: [
                        merchant,
                        materialId,
                      ], namedArgs: {
                        'amount': 500,
                      });
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
                  case DebugMenuItems.debugCompanion:
                    final companion = engine.hetu.invoke('Character');
                    engine.hetu.invoke(
                      'accompany',
                      namespace: 'Player',
                      positionalArgs: [companion],
                    );
                    context.read<NpcListState>().update([companion]);
                  case DebugMenuItems.debugBattle:
                    // final enemy = engine.hetu.invoke('Character', namedArgs: {
                    //   'level': GameData.hero['level'],
                    //   'rank': GameData.hero['rank'],
                    // });
                    final enemy = engine.hetu.invoke('Character', namedArgs: {
                      'name': 'wooden_dummy',
                      'isFemale': false,
                      'level': 10,
                      'rank': 0,
                      'icon': 'illustration/npc/wooden_dummy_head.png',
                      'skin': 'wooden_dummy',
                      'attributes': {
                        'charisma': 0,
                        'wisdom': 0,
                        'luck': 0,
                        'spirituality': 0,
                        'dexterity': 0,
                        'strength': 120,
                        'willpower': 0,
                        'perception': 0,
                      },
                      'cultivationFavor': '',
                    });
                    engine.hetu.invoke('characterCalculateStats',
                        positionalArgs: [enemy]);
                    // engine.hetu.invoke('generateDeck', positionalArgs: [enemy]);
                    engine.hetu.invoke('generateDeck', positionalArgs: [
                      enemy
                    ], namedArgs: {
                      'cardInfoList': [
                        {
                          'affixId': 'blank_default',
                        },
                        {
                          'affixId': 'blank_default',
                        },
                        {
                          'affixId': 'blank_default',
                        },
                      ],
                    });
                    context.read<EnemyState>().show(enemy,
                        onBattleEnd: (bool battleResult, int roundCount) {
                      dialog.pushDialogRaw(
                          'It took you $roundCount rounds to defeat the dummy.');
                      dialog.execute();
                    });
                  case DebugMenuItems.debugTribulation:
                    final targetRank = GameData.hero['rank'] + 1;
                    final levelMin = GameLogic.minLevelForRank(targetRank);
                    GameLogic.showTribulation(levelMin + 5, targetRank);
                  case DebugMenuItems.debugImmortalityTrial:
                    engine.clearAllCachedScene(except: Scenes.mainmenu);
                    GameData.game['flags']['cultivationTrial'] = {
                      'name': engine.locale('cultivation_trial'),
                      'difficulty': 0,
                      'introCompleted': false,
                      'buildCompleted': false,
                      'room': 0,
                      'roomMax': 3,
                    };
                    engine.pushScene(
                      'cultivation_trial_1',
                      constructorId: Scenes.worldmap,
                      arguments: {
                        'id': 'cultivation_trial_1',
                        'method': 'load',
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
