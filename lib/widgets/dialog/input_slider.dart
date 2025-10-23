import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';
import '../../ui.dart';

class InputSliderDialog extends StatefulWidget {
  static Future<int?> show({
    required BuildContext context,
    required int min,
    required int max,
    int? value,
    String? title,
    String Function(int value)? labelBuilder,
    bool barrierDismissible = true,
  }) {
    assert(min >= 0);
    assert(max >= min);
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
          barrierDismissible: barrierDismissible,
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
    this.barrierDismissible = true,
  });

  final int min, max;
  final int? value;
  final int? divisions;
  final String? title;
  final String Function(int value)? labelBuilder;
  final bool barrierDismissible;

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
      barrierDismissible: widget.barrierDismissible,
      barrierColor: null,
      backgroundColor: GameUI.backgroundColorOpaque,
      width: 250,
      height: 300,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.title ?? engine.locale('selectAmount')),
          actions: const [CloseButton2()],
        ),
        body: Container(
          alignment: AlignmentDirectional.center,
          padding: const EdgeInsets.all(20.0),
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
                child: fluent.FilledButton(
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
    );
  }
}
