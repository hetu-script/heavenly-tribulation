import 'dart:ui';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';

import '../../global.dart';
import 'package:samsara/ui/shared/close_button.dart';
import 'package:samsara/ui/shared/responsive_window.dart';

class Console extends StatefulWidget {
  const Console({super.key});

  @override
  State<Console> createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  static int _commandHistoryIndex = 0;
  static final _commandHistory = <String>[];
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  late final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textEditingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final layout = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(engine.locale['console']),
        actions: const [ButtonClose()],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(10.0),
              child: ScrollConfiguration(
                behavior: ScrollConfiguration.of(context).copyWith(
                  dragDevices: {
                    PointerDeviceKind.touch,
                    PointerDeviceKind.mouse,
                  },
                ),
                child: ListView(
                  controller: _scrollController,
                  reverse: true,
                  children: engine
                      .getLog()
                      .map((line) => Text(line))
                      .toList()
                      .reversed
                      .toList(),
                ),
              ),
            ),
          ),
          RawKeyboardListener(
            focusNode: _textFieldFocusNode,
            key: UniqueKey(),
            onKey: (RawKeyEvent key) {
              if (key is RawKeyUpEvent) {
                if (key.data is RawKeyEventDataWindows ||
                    key.data is RawKeyEventDataMacOs ||
                    key.data is RawKeyEventDataLinux) {
                  final int code = (key.data as dynamic).keyCode;
                  switch (code) {
                    case 36: // home
                      _textEditingController.selection =
                          TextSelection.fromPosition(
                              const TextPosition(offset: 0));
                      break;
                    case 35: // end
                      _textEditingController.selection =
                          TextSelection.fromPosition(TextPosition(
                              offset: _textEditingController.text.length));
                      break;
                    case 38: // up
                      if (_commandHistoryIndex > 0) {
                        --_commandHistoryIndex;
                      }
                      if (_commandHistory.isNotEmpty) {
                        _textEditingController.text =
                            _commandHistory[_commandHistoryIndex];
                      } else {
                        _textEditingController.text = '';
                      }
                      break;
                    case 40: // down
                      if (_commandHistoryIndex < _commandHistory.length - 1) {
                        ++_commandHistoryIndex;
                        _textEditingController.text =
                            _commandHistory[_commandHistoryIndex];
                      } else {
                        _textEditingController.text = '';
                      }
                      break;
                  }
                }
              }
            },
            child: TextField(
              key: UniqueKey(),
              onSubmitted: (value) {
                _commandHistory.add(value);
                _commandHistoryIndex = _commandHistory.length;
                setState(() {
                  try {
                    final r = engine.hetu.eval(value, globallyImport: true);
                    if (r != null) {
                      engine.info(engine.hetu.lexicon.stringify(r));
                    }
                  } catch (e) {
                    engine.error(e.toString());
                  }
                  _textEditingController.text = '';
                  _textFieldFocusNode.requestFocus();
                  _scrollController
                      .jumpTo(_scrollController.position.minScrollExtent);
                });
              },
              autofocus: true,
              controller: _textEditingController,
              cursorColor: kForegroundColor,
              decoration: const InputDecoration(
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 1.0),
                ),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey, width: 0.0),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      child: layout,
    );
  }
}
