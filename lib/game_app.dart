import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:sing2/ui/city/city_view.dart';

import 'engine/scene/scene.dart';
import 'engine/scene/rogue/rogue_game.dart';
import 'ui/loading_screen.dart';
import 'ui/map/map_view.dart';
import 'engine/game.dart';

class GameApp extends StatefulWidget {
  final SamsaraGame game;

  const GameApp({required this.game, Key? key}) : super(key: key);

  @override
  State<GameApp> createState() => _GameAppState();
}

class _GameAppState extends State<GameApp>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  SamsaraGame get game => widget.game;

  final _pageController = PageController();
  var _currentPage = 0;

  late final List<Widget> _pages;

  bool isAppLoading = false;

  bool isSceneLoading = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void init() async {
    await game.init();
    setState(() {
      isAppLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();

    _pages = [
      CityView(game: game),
      const MapView(),
      const Align(
        alignment: Alignment.center,
        child: Text('关注'),
      ),
      const Align(
        alignment: Alignment.center,
        child: Text('我的'),
      ),
    ];

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

    isAppLoading = true;
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
    if (game.isLoaded) {
      // pass the build context to script
      game.hetu.invoke('build', positionalArgs: [context]);
    }

    if (game.currentScene == null) {
      if (isAppLoading) {
        return const LoadingScreen();
      } else {
        return Scaffold(
          appBar: AppBar(
            title: const Text('aleph03r2'),
          ),
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
                label: '场景',
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
            elevation: 0.0,
            onTap: _onItemTapped,
          ),
        );
      }
    } else {
      return game.currentScene!.widget;
    }
  }
}
