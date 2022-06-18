import 'dart:ui';

import 'package:flutter/material.dart';

import '../../global.dart';
import '../shared/close_button.dart';
import '../shared/responsive_route.dart';

class Console extends StatefulWidget {
  const Console({Key? key}) : super(key: key);

  @override
  _ConsoleState createState() => _ConsoleState();
}

class _ConsoleState extends State<Console> {
  final TextEditingController _textEditingController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  late final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final layout = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
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
          TextField(
            focusNode: _textFieldFocusNode,
            onSubmitted: (value) {
              setState(() {
                try {
                  final r = engine.hetu.eval(value);
                  engine.info(engine.hetu.lexicon.stringify(r));
                } catch (e) {
                  engine.error(e.toString());
                }
                _textEditingController.text = '';
                _textFieldFocusNode.requestFocus();
                _scrollController
                    .jumpTo(_scrollController.position.minScrollExtent);
              });
            },
            cursorColor: kForegroundColor,
            autofocus: true,
            controller: _textEditingController,
            decoration: const InputDecoration(
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 1.0),
              ),
              border: OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey, width: 0.0),
              ),
            ),
          ),
        ],
      ),
    );

    return ResponsiveRoute(
      child: layout,
      alignment: AlignmentDirectional.center,
    );
  }
}
