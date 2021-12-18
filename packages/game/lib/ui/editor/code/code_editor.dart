import 'package:flutter/material.dart';
import 'package:code_text_field/code_text_field.dart';
// Import the language & theme
import 'package:flutter_highlight/themes/monokai-sublime.dart';

import 'hetu_mode.dart';
import '../../shared/bordered_tab.dart';

class CodeEditor extends StatefulWidget {
  CodeEditor(
      {Key? key,
      required this.names,
      required this.contents,
      this.untitledName = 'untitled_script'})
      : super(key: key) {
    assert(names.length == contents.length);
  }

  final String untitledName;

  final List<String> names;

  final List<String> contents;

  @override
  _CodeEditorState createState() => _CodeEditorState();
}

class _CodeEditorState extends State<CodeEditor>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  var _untitledIndex = 0;
  List<String> get names => widget.names;
  List<String> get contents => widget.contents;
  final _codeControllers = <CodeController>[];
  final _textFieldFocusNodes = <FocusNode>[];
  TabController? _tabController;
  final _tabs = <BorderedTab>[];
  final _textFields = <Widget>[];
  final _openedIndex = <int>{};
  int _selectedIndex = 0;
  final _fileListItem = <Widget>[];

  void _updateData() {
    if (names.isEmpty) {
      names.add('${widget.untitledName}${++_untitledIndex}');
      contents.add('');
      _openedIndex.add(0);
    }

    for (var index = 0; index < names.length; ++index) {
      final content = contents[index];
      _codeControllers.add(
        CodeController(
          text: content,
          language: hetuscript,
          theme: monokaiSublimeTheme,
        ),
      );

      _textFieldFocusNodes.add(FocusNode());

      final name = names[index];
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
            _openedIndex.add(index);
            _selectedIndex = index;
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

    for (final index in _openedIndex) {
      _tabs.add(BorderedTab(text: names[index]));
    }
    _tabController = TabController(vsync: this, length: _tabs.length);
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
    super.build(context);
    _tabController?.index = _selectedIndex;
    _textFieldFocusNodes[_selectedIndex].requestFocus();
    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Stack(
        children: <Widget>[
          Positioned(
            child: GestureDetector(
              onTap: () {
                _textFieldFocusNodes[_selectedIndex].requestFocus();
              },
              child: Container(
                width: 200.0,
                height: MediaQuery.of(context).size.height,
                alignment: Alignment.topLeft,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[200]!,
                  ),
                ),
                child: SingleChildScrollView(
                  child: ListView(
                    children: _fileListItem,
                    shrinkWrap: true,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 200,
            width: MediaQuery.of(context).size.width - 200,
            height: MediaQuery.of(context).size.height,
            child: GestureDetector(
              onTap: () {
                _textFieldFocusNodes[_selectedIndex].requestFocus();
              },
              child: Column(
                children: [
                  PreferredSize(
                    preferredSize: const Size.fromHeight(kToolbarHeight),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: TabBar(
                        labelColor: Colors.black87,
                        unselectedLabelColor: Colors.black38,
                        controller: _tabController,
                        tabs: _tabs,
                        isScrollable: true,
                        onTap: (index) {
                          _textFieldFocusNodes[index].requestFocus();
                        },
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      color: const Color(0xff23241f),
                      child: SingleChildScrollView(
                        controller: ScrollController(),
                        child: _textFields[_selectedIndex],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
