import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../ui/close_button2.dart';

class NameGenerator extends StatefulWidget {
  const NameGenerator({
    super.key,
    this.text,
    this.showCloseButton = false,
  });

  final String? text;

  final bool showCloseButton;

  @override
  State<NameGenerator> createState() => _NameGeneratorState();
}

class _NameGeneratorState extends State<NameGenerator> {
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    if (widget.text != null) {
      _textController.text = widget.text!;
    }
  }

  @override
  void dispose() {
    super.dispose();

    _textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      alignment: AlignmentDirectional.center,
      width: 220.0,
      height: 100.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('inputName')),
          actions: [if (widget.showCloseButton) const CloseButton2()],
        ),
        body: Column(
          children: [
            Row(
              children: [
                TextField(
                  controller: _textController,
                ),
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.casino),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: fluent.FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(engine.locale('confirm')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
