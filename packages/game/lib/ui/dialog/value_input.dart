import 'package:flutter/material.dart';

import '../shared/responsive_route.dart';
import '../shared/close_button.dart';
import '../../global.dart';

class ValueInput extends StatefulWidget {
  const ValueInput({
    super.key,
    this.value,
    this.showCloseButton = false,
  });

  final int? value;

  final bool showCloseButton;

  @override
  State<ValueInput> createState() => _ValueInputState();
}

class _ValueInputState extends State<ValueInput> {
  final _textController = TextEditingController();

  @override
  void initState() {
    if (widget.value != null) {
      _textController.text = widget.value!.toString();
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
    return ResponsiveRoute(
      alignment: AlignmentDirectional.center,
      size: const Size(220.0, 100.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale['inputValue']),
          actions: [if (widget.showCloseButton) const ButtonClose()],
        ),
        body: Column(
          children: [
            Row(
              children: [
                TextField(
                  controller: _textController,
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
