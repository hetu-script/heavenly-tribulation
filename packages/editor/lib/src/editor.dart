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
  static const moduleEntryFileName = 'main.ht';

  bool _isEditing = false;
  String? _currentProjectName;
  String? _currentSavePath;
  final _textFieldController = TextEditingController();

  @override
  void dispose() {
    super.dispose();
    _textFieldController.dispose();
  }

  Future<void> _newProject() async {
    String? projectName;
    _textFieldController.text = AppLocalizations.of(context)!.unnamedProject;
    await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: TextField(
            controller: _textFieldController,
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
              style: ElevatedButton.styleFrom(onPrimary: Colors.green),
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

  Future<void> _saveAs() async {
    _currentSavePath ??=
        await FilePicker.platform.saveFile(fileName: moduleEntryFileName);
    if (_currentSavePath == null) {
      return;
    }
    final moduleEntryFile = File(_currentSavePath!);
    moduleEntryFile.writeAsStringSync(_generateMain());

    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.saveSuccessed)));
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
                      _saveAs();
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
                Tab(text: AppLocalizations.of(context)!.character),
                Tab(text: AppLocalizations.of(context)!.location),
                Tab(text: AppLocalizations.of(context)!.organization),
                Tab(text: AppLocalizations.of(context)!.maze),
                Tab(text: AppLocalizations.of(context)!.dialog),
                Tab(text: AppLocalizations.of(context)!.language),
                Tab(text: AppLocalizations.of(context)!.meta),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              Center(child: Text(AppLocalizations.of(context)!.character)),
              Center(child: Text(AppLocalizations.of(context)!.location)),
              Center(child: Text(AppLocalizations.of(context)!.organization)),
              Center(child: Text(AppLocalizations.of(context)!.maze)),
              Center(child: Text(AppLocalizations.of(context)!.dialog)),
              Center(child: Text(AppLocalizations.of(context)!.language)),
              Center(child: Text(_currentProjectName ?? '')),
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

  String _generateMain() {
    const output = r'''
          
      fun load {

      }

      fun init {

      }
    ''';

    return output;
  }
}
