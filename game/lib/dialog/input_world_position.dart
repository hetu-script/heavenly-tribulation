import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/integer_input_field.dart';
import 'package:samsara/ui/close_button.dart';

import '../config.dart';

class InputWorldPositionDialog extends StatefulWidget {
  static Future<(int, int, String?)?> show({
    required BuildContext context,
    int? defaultX,
    int? defaultY,
    int? maxX,
    int? maxY,
    String? title,
    String? worldId,
    bool enableWorldId = true,
  }) {
    return showDialog<(int, int, String?)>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return InputWorldPositionDialog(
          defaultX: defaultX,
          defaultY: defaultY,
          maxX: maxX,
          maxY: maxY,
          title: title,
          worldId: worldId,
          enableWorldId: enableWorldId,
        );
      },
    );
  }

  const InputWorldPositionDialog({
    super.key,
    this.defaultX,
    this.defaultY,
    this.maxX,
    this.maxY,
    this.title,
    this.worldId,
    this.enableWorldId = true,
  });

  final int? defaultX, defaultY;
  final int? maxX, maxY;
  final String? title;
  final String? worldId;
  final bool enableWorldId;

  @override
  State<InputWorldPositionDialog> createState() =>
      _InputWorldPositionDialogState();
}

class _InputWorldPositionDialogState extends State<InputWorldPositionDialog> {
  final _posXController = TextEditingController();
  final _posYController = TextEditingController();
  final _worldIdEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _posXController.text = widget.defaultX?.toString() ?? '';
    _posYController.text = widget.defaultY?.toString() ?? '';

    _worldIdEditingController.text = widget.worldId ?? '';
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
      size: const Size(240.0, 210.0),
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
                if (widget.enableWorldId)
                  SizedBox(
                    width: 200,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 60.0,
                          child: Text('${engine.locale('worldId')}: '),
                        ),
                        SizedBox(
                          width: 120.0,
                          child: TextField(
                            controller: _worldIdEditingController,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(' ')
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
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
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: ElevatedButton(
                    onPressed: () {
                      final x = int.tryParse(_posXController.text);
                      final y = int.tryParse(_posYController.text);
                      (int, int, String?)? result;
                      if (x != null && y != null) {
                        result = (
                          x,
                          y,
                          _worldIdEditingController.text.nonEmptyValueOrNull,
                        );
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
