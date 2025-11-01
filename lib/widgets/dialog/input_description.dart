import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../global.dart';
import '../../ui.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';

class InputDescriptionDialog extends StatefulWidget {
  static Future<String?> show({
    required BuildContext context,
    String? title,
    bool barrierDismissible = true,
  }) {
    return showDialog<String?>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return InputDescriptionDialog(
          title: title,
          barrierDismissible: barrierDismissible,
        );
      },
    );
  }

  const InputDescriptionDialog({
    super.key,
    this.title,
    this.description = '',
    this.barrierDismissible = true,
  });

  final String? title;
  final String description;
  final bool barrierDismissible;

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
    super.dispose();

    _textEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      barrierDismissible: widget.barrierDismissible,
      barrierColor: null,
      backgroundColor: GameUI.backgroundColorOpaque,
      width: 600.0,
      height: 600.0,
      child: Scaffold(
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
                width: 600.0,
                height: 480.0,
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                margin: const EdgeInsets.all(15.0),
                decoration: GameUI.boxDecoration,
                child: SingleChildScrollView(
                  child: fluent.TextBox(
                    autofocus: true,
                    controller: _textEditingController,
                    maxLines: null,
                    minLines: 9,
                    // decoration: const InputDecoration(border: InputBorder.none),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: fluent.Button(
                  onPressed: () {
                    String result = _textEditingController.text.trim();
                    Navigator.of(context).pop(result.nonEmptyValue);
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
    );
  }
}
