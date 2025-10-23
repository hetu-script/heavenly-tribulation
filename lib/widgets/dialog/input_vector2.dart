import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/integer_input_field.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';
import '../../ui.dart';

class InputVector2Dialog extends StatefulWidget {
  static Future<(int, int)?> show({
    required BuildContext context,
    int? defaultX,
    int? defaultY,
    int? maxX,
    int? maxY,
    String? title,
    bool barrierDismissible = true,
  }) {
    return showDialog<(int, int)>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return InputVector2Dialog(
          defaultX: defaultX,
          defaultY: defaultY,
          maxX: maxX,
          maxY: maxY,
          title: title,
          barrierDismissible: barrierDismissible,
        );
      },
    );
  }

  const InputVector2Dialog({
    super.key,
    this.defaultX,
    this.defaultY,
    this.maxX,
    this.maxY,
    this.title,
    this.barrierDismissible = true,
  });

  final int? defaultX, defaultY;
  final int? maxX, maxY;
  final String? title;
  final bool barrierDismissible;

  @override
  State<InputVector2Dialog> createState() => _InputVector2DialogState();
}

class _InputVector2DialogState extends State<InputVector2Dialog> {
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
    super.dispose();

    _posXController.dispose();
    _posYController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      barrierDismissible: widget.barrierDismissible,
      barrierColor: null,
      backgroundColor: GameUI.backgroundColorOpaque,
      width: 240.0,
      height: 210.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.title ?? engine.locale('input')),
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
                      autofocus: true,
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
                child: fluent.Button(
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
    );
  }
}
