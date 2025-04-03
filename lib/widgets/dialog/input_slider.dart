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
    int? value,
    String? title,
    String Function(int value)? labelBuilder,
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
          value: value,
          title: title,
          labelBuilder: labelBuilder,
        );
      },
    );
  }

  const InputSliderDialog({
    super.key,
    required this.min,
    required this.max,
    this.value,
    this.divisions,
    this.title,
    this.labelBuilder,
  });

  final int min, max;
  final int? value;
  final int? divisions;
  final String? title;
  final String Function(int value)? labelBuilder;

  @override
  State<InputSliderDialog> createState() => _InputSliderDialogState();
}

class _InputSliderDialogState extends State<InputSliderDialog> {
  late int _current;

  @override
  void initState() {
    super.initState();

    _current = widget.value ?? 0;
    if (_current < widget.min) {
      _current = widget.min;
    } else if (_current > widget.max) {
      _current = widget.max;
    }
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
                  widget.labelBuilder != null
                      ? widget.labelBuilder!(_current)
                      : _current.toString(),
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
