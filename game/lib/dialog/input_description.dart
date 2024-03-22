import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';

import '../config.dart';

class InputDescriptionDialog extends StatefulWidget {
  static Future<String?> show({
    required BuildContext context,
    String? title,
  }) {
    return showDialog<String?>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return InputDescriptionDialog(title: title);
      },
    );
  }

  const InputDescriptionDialog({
    super.key,
    this.title,
    this.description = '',
  });

  final String? title;

  final String description;

  @override
  State<InputDescriptionDialog> createState() => _InputDescriptionDialogState();
}

class _InputDescriptionDialogState extends State<InputDescriptionDialog> {
  final _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _textEditingController.text = widget.description;
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      child: SizedBox(
        width: 400.0,
        height: 400.0,
        child: Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(widget.title ?? engine.locale('inputDescription')),
            actions: const [CloseButton2()],
          ),
          body: Container(
            alignment: AlignmentDirectional.center,
            child: Column(
              children: [
                Container(
                  width: 400.0,
                  height: 280.0,
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  margin: const EdgeInsets.all(15.0),
                  decoration: BoxDecoration(
                      border: Border.all(color: kForegroundColor)),
                  child: SingleChildScrollView(
                    child: TextField(
                      autofocus: true,
                      controller: _textEditingController,
                      maxLines: null,
                      minLines: 9,
                      decoration:
                          const InputDecoration(border: InputBorder.none),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ElevatedButton(
                    onPressed: () {
                      String result = _textEditingController.text.trim();
                      Navigator.of(context).pop(result.nonEmptyValueOrNull);
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
