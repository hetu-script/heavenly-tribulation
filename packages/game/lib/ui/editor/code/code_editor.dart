import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
import 'package:flutter_highlight/themes/monokai-sublime.dart';

import 'hetu_mode.dart';
import '../../shared/bordered_tab.dart';

class CodeEditor extends StatefulWidget {
  CodeEditor(
      {super.key,
      required this.names,
      required this.contents,
      this.untitledName = 'untitled_script'}) {
    assert(names.length == contents.length);
  }

  final String untitledName;

  final List<String> names;

  final List<String> contents;

  @override
  State<CodeEditor> createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor> with TickerProviderStateMixin {
  final _fileListViewWidth = 200.0;
  List<String> get names => widget.names;
  List<String> get contents => widget.contents;
  final _codeControllers = <CodeController>[];
  final _textFieldFocusNodes = <FocusNode>[];
  TabController? _tabController;
  final _tabs = <BorderedTab>[];
  final _textFields = [];
  final _openedNames = <String>[];
  int _selectedIndex = -1;
  final _fileListItem = <Widget>[];

  @override
  void setState(VoidCallback fn) {
    super.setState(fn);

    _updateData();
  }

  void _updateData() {
    _openedNames.removeWhere((name) => !names.contains(name));
    if (_openedNames.isEmpty && names.isNotEmpty) {
      _openedNames.add(names.first);
      _selectedIndex = 0;
    }

    _codeControllers.clear();
    _textFieldFocusNodes.clear();
    _fileListItem.clear();
    _textFields.clear();
    _tabs.clear();
    _tabController?.dispose();
    for (var index = 0; index < names.length; ++index) {
      final name = names[index];
      final content = contents[index];
      _codeControllers.add(
        CodeController(
          text: content,
          language: hetuscript,
          theme: monokaiSublimeTheme,
        ),
      );
      _textFieldFocusNodes.add(FocusNode());
      _fileListItem.add(InkWell(
        focusNode: _textFieldFocusNodes[index],
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            name,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14.0),
          ),
        ),
        onTap: () {
          setState(() {
            if (!_openedNames.contains(name)) {
              _openedNames.add(name);
              _selectedIndex = _openedNames.indexOf(name);
            }
          });
        },
      ));
      _textFields.add(
        CodeField(
          controller: _codeControllers[index],
          textStyle: const TextStyle(fontFamily: 'UbuntuMono'),
          focusNode: _textFieldFocusNodes[index],
        ),
      );
    }
    for (final name in _openedNames) {
      _tabs.add(BorderedTab(text: name));
    }
    if (_tabs.isNotEmpty) {
      _tabController = TabController(vsync: this, length: _tabs.length);
    }
    if (_textFieldFocusNodes.isNotEmpty) {
      _textFieldFocusNodes.first.requestFocus();
    }
  }

  @override
  void initState() {
    super.initState();

    _updateData();
  }

  @override
  void dispose() {
    super.dispose();
    for (final node in _textFieldFocusNodes) {
      node.dispose();
    }
    for (final controller in _codeControllers) {
      controller.dispose();
    }
    _tabController?.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_selectedIndex >= 0) {
      _tabController?.index = _selectedIndex;
      _textFieldFocusNodes[_selectedIndex].requestFocus();
    }
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      return SizedBox(
        width: constraints.maxWidth,
        child: Stack(
          children: [
            Positioned(
              child: GestureDetector(
                onTap: () {
                  if (_selectedIndex >= 0) {
                    _textFieldFocusNodes[_selectedIndex].requestFocus();
                  }
                },
                child: Container(
                  width: _fileListViewWidth,
                  height: MediaQuery.of(context).size.height,
                  alignment: Alignment.topLeft,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey[200]!,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: ListView(
                      shrinkWrap: true,
                      children: _fileListItem,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              left: _fileListViewWidth,
              height: kToolbarHeight,
              child: Align(
                alignment: Alignment.topLeft,
                child: _tabs.isNotEmpty
                    ? TabBar(
                        labelColor: Colors.black87,
                        unselectedLabelColor: Colors.black38,
                        controller: _tabController,
                        tabs: _tabs,
                        isScrollable: true,
                        onTap: (index) {
                          _textFieldFocusNodes[index].requestFocus();
                        },
                      )
                    : null,
              ),
            ),
            Positioned(
              left: _fileListViewWidth,
              top: kToolbarHeight,
              width: constraints.maxWidth - _fileListViewWidth,
              height: constraints.maxHeight - kToolbarHeight,
              child: GestureDetector(
                onTap: () {
                  if (_selectedIndex >= 0) {
                    _textFieldFocusNodes[_selectedIndex].requestFocus();
                  }
                },
                // color: const Color(0xff23241f),
                child: SingleChildScrollView(
                  controller: ScrollController(),
                  child: _textFields.isNotEmpty
                      ? _textFields[_selectedIndex]
                      : null,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}
