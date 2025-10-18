import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/integer_input_field.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../ui.dart';
import '../ui/close_button2.dart';

class InputIntegerDialog extends StatefulWidget {
  static Future<int?> show({
    required BuildContext context,
    int? min,
    int? max,
    String? title,
  }) {
    return showDialog<int?>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return InputIntegerDialog(
          min: min,
          max: max,
          title: title,
        );
      },
    );
  }

  const InputIntegerDialog({
    super.key,
    this.min,
    this.max,
    this.title,
  });

  final int? min;
  final int? max;
  final String? title;

  @override
  State<InputIntegerDialog> createState() => _InputIntegerDialogState();
}

class _InputIntegerDialogState extends State<InputIntegerDialog> {
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
        width: 200,
        height: 160,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(widget.title ?? engine.locale('inputInteger')),
            actions: const [CloseButton2()],
          ),
          body: Container(
            alignment: AlignmentDirectional.center,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10.0, vertical: 20.0),
                  child: IntegerInputField(
                    autofocus: true,
                    min: widget.min ?? 0,
                    max: widget.max,
                    showSuffixButtons: widget.max != null,
                    controller: _textEditingController,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: fluent.FilledButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        int.tryParse(_textEditingController.text) ?? 0,
                      );
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
