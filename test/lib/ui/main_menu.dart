import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:samsara/flutter_ui/loading_screen.dart';
import 'package:samsara/flutter_ui/label.dart';
import 'package:flutter/services.dart';
import 'package:json5/json5.dart';

import '../global.dart';
import '../scene/game.dart';
import 'overlay/main_game.dart';
import '../noise_test.dart';
import '../explore.dart';

class MainMenu extends StatefulWidget {
  const MainMenu({super.key});

  @override
  State<MainMenu> createState() => _MainMenuState();
}

class _MainMenuState extends State<MainMenu> {
  @override
  void initState() {
    super.initState();

    engine.registerSceneConstructor('game', ([dynamic data]) async {
      return GameScene(controller: engine, id: 'game');
    });
  }

  Future<bool> _prepareData() async {
    if (engine.isLoaded) return true;
    await engine.init();

    final localeStrings =
        await rootBundle.loadString('assets/locales/chs.json5');
    final localeData = JSON5.parse(localeStrings);
    engine.loadLocale(localeData);

    engine.hetu.evalFile('main.ht', globallyImport: true);

    engine.isLoaded = true;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _prepareData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return LoadingScreen(
              text: engine.isLoaded ? engine.locale['loading'] : 'Loading...');
        } else {
          return Scaffold(
            body: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => MainGameOverlay(),
                            );
                          },
                          child: Label(
                            engine.locale['newGame'],
                            width: 100.0,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pushNamed('wiki');
                          },
                          child: const Text('markdown_wiki'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const NoiseTest(),
                            );
                          },
                          child: const Text('perlin noise'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => const ExploreDialog(),
                            );
                          },
                          child: const Text('progress indicator'),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.only(top: 20.0, bottom: 100.0),
                        child: ElevatedButton(
                          onPressed: () {
                            windowManager.close();
                          },
                          child: Label(
                            engine.locale['exit'],
                            width: 100.0,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
