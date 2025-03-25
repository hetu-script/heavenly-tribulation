import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';

import '../../engine.dart';
import '../../game/ui.dart';

class InputStringDialog extends StatefulWidget {
  static Future<String?> show({
    required BuildContext context,
    String? title,
  }) {
    return showDialog<String?>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return InputStringDialog(title: title);
      },
    );
  }

  const InputStringDialog({
    super.key,
    this.title,
  });

  final String? title;

  @override
  State<InputStringDialog> createState() => _InputStringDialogState();
}

class _InputStringDialogState extends State<InputStringDialog> {
  final _textEditingController = TextEditingController();

  @override
  void dispose() {
    super.dispose();

    _textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      child: SizedBox(
        width: 240,
        height: 170,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(widget.title ?? engine.locale('inputID')),
            actions: const [CloseButton2()],
          ),
          body: Container(
            alignment: AlignmentDirectional.center,
            child: Column(
              children: [
                Container(
                  width: 180.0,
                  height: 80,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 20.0),
                  child: TextField(
                    inputFormatters: [FilteringTextInputFormatter.deny(' ')],
                    autofocus: true,
                    controller: _textEditingController,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ElevatedButton(
                    onPressed: () {
                      final result = _textEditingController.text.nonEmptyValue;
                      Navigator.of(context).pop(result);
                    },
                    child: Text(
                      engine.locale('confirm'),
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
