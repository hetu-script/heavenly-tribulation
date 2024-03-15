import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/integer_input_field.dart';
import 'package:samsara/ui/close_button.dart';

import '../config.dart';

class InputWorldLocationDialog extends StatefulWidget {
  static Future<(int, int)?> show({
    required BuildContext context,
    int? defaultX,
    int? defaultY,
    int? maxX,
    int? maxY,
    String? title,
  }) {
    return showDialog<(int, int)>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return InputWorldLocationDialog(
          defaultX: defaultX,
          defaultY: defaultY,
          maxX: maxX,
          maxY: maxY,
          title: title,
        );
      },
    );
  }

  const InputWorldLocationDialog({
    super.key,
    this.defaultX,
    this.defaultY,
    this.maxX,
    this.maxY,
    this.title,
  });

  final int? defaultX, defaultY;
  final int? maxX, maxY;
  final String? title;

  @override
  State<InputWorldLocationDialog> createState() =>
      _InputWorldLocationDialogState();
}

class _InputWorldLocationDialogState extends State<InputWorldLocationDialog> {
  final _posXController = TextEditingController();
  final _posYController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _posXController.text = widget.defaultX?.toString() ?? '';
    _posYController.text = widget.defaultY?.toString() ?? '';
  }

  @override
  void dispose() {
    _posXController.dispose();
    _posYController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWindow(
      size: const Size(240.0, 160.0),
      alignment: AlignmentDirectional.center,
      child: SizedBox(
        child: Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(widget.title ?? engine.locale('inputInteger')),
            actions: const [CloseButton2()],
          ),
          body: Container(
            alignment: AlignmentDirectional.center,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 100.0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 20.0),
                      child: IntegerInputField(
                        initValue: widget.defaultX,
                        min: 0,
                        max: widget.maxX,
                        controller: _posXController,
                      ),
                    ),
                    Container(
                      width: 100.0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 20.0),
                      child: IntegerInputField(
                        initValue: widget.defaultY,
                        min: 0,
                        max: widget.maxY,
                        controller: _posYController,
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.all(5.0),
                  child: ElevatedButton(
                    onPressed: () {
                      final x = int.tryParse(_posXController.text);
                      final y = int.tryParse(_posYController.text);
                      (int, int)? result;
                      if (x != null && y != null) {
                        result = (x, y);
                      }
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
