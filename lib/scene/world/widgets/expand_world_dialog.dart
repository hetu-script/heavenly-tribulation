import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/integer_input_field.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../../engine.dart';
import '../../../widgets/ui/close_button2.dart';
import '../../../widgets/ui/responsive_view.dart';

const kDirections = {
  'topLeft',
  'topCenter',
};

class ExpandWorldDialog extends StatefulWidget {
  const ExpandWorldDialog({
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
  State<ExpandWorldDialog> createState() => _ExpandWorldDialogState();
}

class _ExpandWorldDialogState extends State<ExpandWorldDialog> {
  final _posXController = TextEditingController();
  final _posYController = TextEditingController();

  String direction = 'bottomRight';

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
      width: 250.0,
      height: 200.0,
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
                padding: const EdgeInsets.all(10.0),
                child: fluent.Button(
                  onPressed: () {
                    final x = int.tryParse(_posXController.text);
                    final y = int.tryParse(_posYController.text);
                    (int, int, String)? result;
                    if (x != null && y != null) {
                      result = (x, y, direction);
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
