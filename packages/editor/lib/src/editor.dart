import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class GameEditor extends StatefulWidget {
  const GameEditor({Key? key}) : super(key: key);

  @override
  State<GameEditor> createState() => _GameEditorState();
}

class _GameEditorState extends State<GameEditor> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return DefaultTabController(
        length: 6,
        child: Scaffold(
          appBar: AppBar(
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Character'),
                Tab(text: 'Location'),
                Tab(text: 'Organization'),
                Tab(text: 'Maze'),
                Tab(text: 'Dialog'),
                Tab(text: 'Language'),
              ],
            ),
            title: const Text('Tabs Demo'),
          ),
          body: const TabBarView(
            children: [
              Center(child: Text('Character')),
              Center(child: Text('Location')),
              Center(child: Text('Organization')),
              Center(child: Text('Maze')),
              Center(child: Text('Dialog')),
              Center(child: Text('Language')),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _isEditing = true;
                  });
                },
                child: const SizedBox(
                  width: 200,
                  height: 100,
                  child: Text('New Module!'),
                ),
              )
            ],
          ),
        ),
      );
    }
  }
}
