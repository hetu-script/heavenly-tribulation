import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import 'package:samsara/ui/loading_screen.dart';
import 'package:samsara/ui/label.dart';
// import 'package:flutter/services.dart';
// import 'package:json5/json5.dart';
import 'package:samsara/widgets/markdown_wiki.dart';
// import 'package:video_player_win/video_player_win.dart';

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
  // late WinVideoPlayerController _videoController;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    engine.registerSceneConstructor('game', ([dynamic data]) async {
      return GameScene(id: 'game', context: context);
    });
  }

  @override
  void dispose() {
    super.dispose();

    // _videoController.dispose();
  }

  Future<bool> _loadData() async {
    if (engine.isInitted) return true;
    if (_isLoading) return false;

    _isLoading = true;

    await engine.init(context);

    // final localeStrings =
    //     await rootBundle.loadString('assets/locale/chs.json5');
    // final localeData = JSON5.parse(localeStrings);
    // engine.loadLocale(localeData);

    engine.hetu.evalFile('main.ht', globallyImport: true);

    // const videoFilename = 'D:/_dev/heavenly-tribulation/media/video/title2.mp4';
    // final videoFile = File.fromUri(Uri.file(videoFilename));
    // _videoController = WinVideoPlayerController.file(videoFile);
    // _videoController.initialize().then((_) {
    //   // Ensure the first frame is shown after the video is initialized.
    //   setState(() {
    //     if (_videoController.value.isInitialized) {
    //       _videoController.play();
    //     } else {
    //       engine.error("Failed to load [$videoFilename]!");
    //     }
    //   });
    // });
    // _videoController.setLooping(true);
    _isLoading = false;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final view = View.of(context);
    final screenSize = view.physicalSize;
    return FutureBuilder(
      future: _loadData(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data == false) {
          if (snapshot.hasError) {
            throw Exception('${snapshot.error}\n${snapshot.stackTrace}');
          }
          return LoadingScreen(
            text: engine.isInitted ? engine.locale('loading') : 'Loading...',
            showClose: snapshot.hasError,
          );
        } else {
          return Scaffold(
            body: Stack(
              children: [
                Center(
                  child: SizedBox(
                    width: screenSize.width,
                    height: screenSize.height,
                    child: AspectRatio(
                      aspectRatio: screenSize.aspectRatio,
                      // child: WinVideoPlayer(_videoController),
                    ),
                  ),
                ),
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
                            engine.locale('newGame'),
                            width: 100.0,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 20.0, bottom: 20.0),
                        child: ElevatedButton(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (context) => MarkdownWiki(
                                resourceManager: AssetManager(),
                              ),
                            );
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
                            engine.locale('exit'),
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
