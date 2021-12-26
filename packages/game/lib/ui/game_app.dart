import 'package:flutter/material.dart';
import 'package:flame/game.dart';

import '../shared/localization.dart';

import '../engine/scene/scene.dart';
import '../engine/scene/maze.dart';
import 'loading_screen.dart';
import '../engine/game.dart';
import 'game/location_view.dart';
import 'editor/editor.dart';
import 'game/protagnist_view.dart';
import '../engine/scene/worldmap.dart';
import 'pointer_detector.dart';
import '../shared/constants.dart';

enum MenuMode {
  menu,
  game,
  editor,
}

class GameApp extends StatefulWidget {
  final SamsaraGame game;

  const GameApp({Key? key, required this.game}) : super(key: key);

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  SamsaraGame get game => widget.game;

  GameLocalization get locale => widget.game.locale;

  var _menuMode = MenuMode.menu;

  final _pageController = PageController();
  var _currentPage = 0;

  late List<Widget> _pages;

  bool isAppLoading = false;

  bool isSceneLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void updateLocation() {
    setState(() {
      isAppLoading = false;
      _pages = [
        LocationView(
          game: game,
          locationId: 'current',
        ),
        const Align(
          alignment: Alignment.center,
          child: Text('世界'),
        ),
        const Align(
          alignment: Alignment.center,
          child: Text('关注'),
        ),
        ProtagnistView(
          game: game,
          onQuit: () {
            setState(() {
              _menuMode = MenuMode.menu;
            });
          },
        ),
      ];
    });
  }

  void init() async {
    await game.init();
    game.hetu.evalFile('core/main.ht', invokeFunc: 'init');
    game.hetu.switchModule('game:main');
    updateLocation();

    // pass the build context to script
    game.hetu.invoke('build', positionalArgs: [context]);
  }

  @override
  void initState() {
    super.initState();
    isAppLoading = true;

    game.registerSceneConstructor('WorldMap', () {
      return WorldMapScene(
          game: game,
          onQuit: () {
            setState(() {
              game.leaveScene();
            });
          });
    });
    game.registerSceneConstructor('Maze', () {
      return MazeScene(
          game: game,
          onQuit: () {
            setState(() {
              game.leaveScene();
            });
          });
    });
    game.registerListener(SceneEvents.started, (event) {
      setState(() {});
    });
    game.registerListener(SceneEvents.ended, (event) {
      setState(() {
        game.leaveScene();
      });
    });

    init();
  }

  void _onItemTapped(int index) {
    _pageController.animateToPage(index,
        duration: const Duration(milliseconds: 300), curve: Curves.ease);
  }

  void _onPageChanged(int value) {
    setState(() {
      _currentPage = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (game.currentScene == null) {
      if (isAppLoading) {
        return const LoadingScreen(text: 'Loading...');
      } else {
        switch (_menuMode) {
          case MenuMode.menu:
            return Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _menuMode = MenuMode.game;
                            // if this is a new game
                            game.hetu.invoke('onGameEvent',
                                positionalArgs: ['onNewGameStarted']);
                          });
                        },
                        child: Text(locale['newGame']),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _menuMode = MenuMode.editor;
                          });
                        },
                        child: Text(locale['gameEditor']),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            game.createScene('WorldMap');
                          });
                        },
                        child: const Text('世界测试'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          case MenuMode.game:
            return Scaffold(
              body: PageView(
                onPageChanged: _onPageChanged,
                controller: _pageController,
                children: _pages,
                physics: const NeverScrollableScrollPhysics(),
              ),
              bottomNavigationBar: BottomNavigationBar(
                type: BottomNavigationBarType.fixed,
                items: <BottomNavigationBarItem>[
                  BottomNavigationBarItem(
                    icon: Image.asset('assets/images/icon/home.png'),
                    label: '城市',
                  ),
                  BottomNavigationBarItem(
                    icon: Image.asset('assets/images/icon/adventure.png'),
                    label: '世界',
                  ),
                  BottomNavigationBarItem(
                    icon: Image.asset('assets/images/icon/inventory.png'),
                    label: '关注',
                  ),
                  BottomNavigationBarItem(
                    icon: Image.asset('assets/images/icon/character.png'),
                    label: '角色',
                  ),
                ],
                currentIndex: _currentPage,
                showSelectedLabels: false,
                showUnselectedLabels: false,
                elevation: 8.0,
                onTap: _onItemTapped,
              ),
            );
          case MenuMode.editor:
            return GameEditor(
                onQuit: () {
                  setState(() {
                    _menuMode = MenuMode.menu;
                  });
                },
                game: game);
        }
      }
    } else {
      shouSceneUI();
      return game.currentScene!.widget;
    }
  }

  Future<void> shouSceneUI() async {
    game.currentScene!.showUI();
  }
}
