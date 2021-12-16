import 'dart:io';

import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'package:path/path.dart' as path;
import 'package:file_picker/file_picker.dart';

class GameEditor extends StatefulWidget {
  const GameEditor({Key? key}) : super(key: key);

  @override
  State<GameEditor> createState() => _GameEditorState();
}

class _GameEditorState extends State<GameEditor> {
  static const moduleEntryFile = 'main.ht';

  bool _isEditing = false;
  String? _currentProjectName;
  String? _currentSaveDirectory;

  final _textFieldController = TextEditingController();

  Future<void> _newProject() async {
    String? projectName;
    await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: TextField(
            controller: _textFieldController,
            decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!
                    .dialogNewProjectTextFieldPlaceholder),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: Text(AppLocalizations.of(context)!.cancel),
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                });
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(primary: Colors.greenAccent),
              child: Text(AppLocalizations.of(context)!.ok),
              onPressed: () {
                setState(() {
                  projectName = _textFieldController.text;
                  Navigator.pop(context);
                });
              },
            ),
          ],
        );
      },
    );
    if (projectName != null) {
      setState(() {
        _currentProjectName = projectName;
        _isEditing = true;
      });
    }
  }

  Future<void> _save() async {
    _currentSaveDirectory ??= await FilePicker.platform.getDirectoryPath();

    if (_currentSaveDirectory == null) {
      return;
    }
    _currentSaveDirectory =
        path.join(_currentSaveDirectory!, _currentProjectName);
    final directory = Directory(_currentSaveDirectory!);
    final moduleEntryPath = path.join(_currentSaveDirectory!, moduleEntryFile);
    final file = File(moduleEntryPath);
    file.writeAsStringSync('test content of module saving.');
    final info =
        '${AppLocalizations.of(context)!.saveSuccessed}${directory.path}';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(info)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isEditing) {
      return DefaultTabController(
        length: 7,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: 10.0),
                  child: IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: AppLocalizations.of(context)!.save,
                    onPressed: () {
                      _save();
                    },
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(_currentProjectName ?? ''),
                  ),
                ),
              ],
            ),
            bottom: TabBar(
              tabs: [
                Tab(text: AppLocalizations.of(context)!.meta),
                Tab(text: AppLocalizations.of(context)!.character),
                Tab(text: AppLocalizations.of(context)!.location),
                Tab(text: AppLocalizations.of(context)!.organization),
                Tab(text: AppLocalizations.of(context)!.maze),
                Tab(text: AppLocalizations.of(context)!.dialog),
                Tab(text: AppLocalizations.of(context)!.language),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              Center(child: Text(_currentProjectName ?? '')),
              Center(child: Text(AppLocalizations.of(context)!.character)),
              Center(child: Text(AppLocalizations.of(context)!.location)),
              Center(child: Text(AppLocalizations.of(context)!.organization)),
              Center(child: Text(AppLocalizations.of(context)!.maze)),
              Center(child: Text(AppLocalizations.of(context)!.dialog)),
              Center(child: Text(AppLocalizations.of(context)!.language)),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.editorTitle),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              ElevatedButton(
                onPressed: _newProject,
                child: SizedBox(
                  width: 200,
                  height: 100,
                  child: Center(
                    child: Text(
                      AppLocalizations.of(context)!.newProject,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      );
    }
  }
}
