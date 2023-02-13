import 'package:flutter/material.dart';

import 'package:samsara/ui/shared/responsive_window.dart';
import 'package:samsara/ui/shared/close_button.dart';
import '../../global.dart';

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
    if (widget.text != null) {
      _textController.text = widget.text!;
    }
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      size: const Size(220.0, 100.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale['inputName']),
          actions: [if (widget.showCloseButton) const ButtonClose()],
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
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(engine.locale['confirm']),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
