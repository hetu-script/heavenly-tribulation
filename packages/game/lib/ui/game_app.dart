import 'package:flutter/material.dart';

import 'package:tian_dao_qi_jie/shared/localization.dart';

import '../engine/scene/scene.dart';
import '../engine/scene/maze/rogue_game.dart';
import 'loading_screen.dart';
import 'game/map_view.dart';
import '../engine/game.dart';
import 'game/location_view.dart';
import 'editor/editor.dart';
import 'game/protagnist_view.dart';

enum GameMode {
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

  var _mode = GameMode.menu;

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
        const MapView(),
        const Align(
          alignment: Alignment.center,
          child: Text('关注'),
        ),
        ProtagnistView(
          game: game,
          onQuit: () {
            setState(() {
              _mode = GameMode.menu;
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

    game.registerSceneConstructor('RogueGame', () {
      return RogueGame(game: game);
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
        switch (_mode) {
          case GameMode.menu:
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
                            _mode = GameMode.game;
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
                            _mode = GameMode.editor;
                          });
                        },
                        child: Text(locale['gameEditor']),
                      ),
                    ),
                  ],
                ),
              ),
            );
          case GameMode.game:
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
          case GameMode.editor:
            return GameEditor(
                onQuit: () {
                  setState(() {
                    _mode = GameMode.menu;
                  });
                },
                game: game);
        }
      }
    } else {
      return game.currentScene!.widget;
    }
  }
}
