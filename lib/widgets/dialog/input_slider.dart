import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';

import '../../engine.dart';
import '../../game/ui.dart';

class InputSliderDialog extends StatefulWidget {
  static Future<int?> show({
    required BuildContext context,
    required int min,
    required int max,
    String? title,
    String? label,
  }) {
    assert(min >= 0);
    assert(max > min);
    return showDialog<int?>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return InputSliderDialog(
          min: min,
          max: max,
          title: title,
          label: label,
        );
      },
    );
  }

  const InputSliderDialog({
    super.key,
    required this.min,
    required this.max,
    this.divisions,
    this.title,
    this.label,
  });

  final int min, max;
  final int? divisions;
  final String? title, label;

  @override
  State<InputSliderDialog> createState() => _InputSliderDialogState();
}

class _InputSliderDialogState extends State<InputSliderDialog> {
  late int _current;

  @override
  void initState() {
    super.initState();

    _current = widget.min;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      child: SizedBox(
        width: 200,
        height: 200,
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
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Slider(
                    value: _current.toDouble(),
                    min: widget.min.toDouble(),
                    max: widget.max.toDouble(),
                    divisions: widget.divisions,
                    label: _current.toString(),
                    onChanged: (double value) {
                      setState(() {
                        _current = value.toInt();
                      });
                    },
                  ),
                ),
                Text(
                  '${widget.label ?? engine.locale('value')}: $_current',
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(_current);
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
