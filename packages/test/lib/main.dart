import 'package:flutter/material.dart';

import 'package:samsara/markdown_wiki/markdown_wiki.dart';

import 'noise_test.dart';
import 'explore.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  AssetManager assetManager = AssetManager();
  runApp(MyApp(assetManager: assetManager));
}

class MyApp extends StatelessWidget {
  final AssetManager assetManager;

  const MyApp({Key? key, required this.assetManager}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Heavenly Tribulation Tests',
      initialRoute: '/',
      routes: {
        '/': (context) => const MyHomePage(title: 'Heavenly Tribulation Tests'),
        'wiki': (context) => MarkdownWiki(
              resourceManager: assetManager,
            ),
      },
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    Key? key,
    required this.title,
  }) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Align(
        alignment: AlignmentDirectional.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('wiki');
              },
              child: const Text('markdown_wiki'),
            ),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const NoiseTest(),
                );
              },
              child: const Text('perlin noise'),
            ),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => const ExploreDialog(),
                );
              },
              child: const Text('progress indicator'),
            ),
          ],
        ),
      ),
    );
  }
}
