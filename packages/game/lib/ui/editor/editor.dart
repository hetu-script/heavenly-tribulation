import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';

import 'character/character_listview.dart';
import 'code/code_editor.dart';
import '../../global.dart';

class GameEditor extends StatefulWidget {
  const GameEditor({super.key});

  @override
  State<GameEditor> createState() => _GameEditorState();
}

class _GameEditorState extends State<GameEditor>
    with AutomaticKeepAliveClientMixin {
  // static const moduleEntryFileName = 'main.ht';
  static const charactersFileName = 'data/characters.ht';

  @override
  bool get wantKeepAlive => true;

  GameLocalization get locale => engine.locale;

  final _characterData = <Map<String, dynamic>>[];

  bool _isEditing = false;
  String? _currentProjectName;
  String? _currentSavePath;
  final _textFieldController = TextEditingController();

  final _codeFileNames = <String>[];
  final _codeFileContents = <String>[];

  @override
  void dispose() {
    super.dispose();
    _textFieldController.dispose();
  }

  void _onCharacterSaved(String content) {
    final index = _codeFileNames.indexOf(charactersFileName);
    if (index == -1) {
      _codeFileNames.add(charactersFileName);
      _codeFileContents.add(content);
    } else {
      _codeFileContents[index] = content;
    }
  }

  Future<void> _newProject() async {
    String? projectName;
    _textFieldController.text = locale['unnamedProject'];
    await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: TextField(
            controller: _textFieldController,
          ),
          actions: [
            ElevatedButton(
              child: Text(locale['cancel']),
              onPressed: () {
                setState(() {
                  Navigator.pop(context);
                });
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(primary: Colors.green[800]),
              child: Text(locale['ok']),
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
    if (_currentSavePath == null) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(locale['saveSuccessed'])));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isEditing) {
      return DefaultTabController(
        length: 8,
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  alignment: Alignment.center,
                  margin: const EdgeInsets.only(right: 10.0),
                  child: IconButton(
                    icon: const Icon(Icons.save),
                    tooltip: locale['save'],
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
              isScrollable: true,
              tabs: [
                Tab(text: locale['character']),
                Tab(text: locale['location']),
                Tab(text: locale['organization']),
                Tab(text: locale['maze']),
                Tab(text: locale['dialog']),
                Tab(text: locale['localization']),
                Tab(text: locale['meta']),
                Tab(text: locale['code']),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              Center(
                child: CharacterListView(
                  data: _characterData,
                  onSaved: (content) {
                    setState(() {
                      _onCharacterSaved(content);
                    });
                  },
                ),
              ),
              Center(child: Text(locale['location'])),
              Center(child: Text(locale['organization'])),
              Center(child: Text(locale['maze'])),
              Center(child: Text(locale['dialog'])),
              Center(child: Text(locale['localization'])),
              Center(child: Text(locale['meta'])),
              Center(
                child: CodeEditor(
                  names: _codeFileNames,
                  contents: _codeFileContents,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(locale['editorTitle']),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _newProject,
                child: SizedBox(
                  width: 200,
                  height: 100,
                  child: Center(
                    child: Text(
                      locale['newProject'],
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
