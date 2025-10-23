import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:samsara/samsara.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';
import '../../ui.dart';

enum InputNameMode {
  character,
  city,
  organization,
}

class InputNameDialog extends StatefulWidget {
  static Future<String?> show({
    required BuildContext context,
    String? title,
    String? value,
    required InputNameMode mode,
    bool barrierDismissible = true,
  }) {
    return showDialog<String?>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return InputNameDialog(
          title: title,
          value: value,
          mode: mode,
          barrierDismissible: barrierDismissible,
        );
      },
    );
  }

  const InputNameDialog({
    super.key,
    this.title,
    this.value,
    required this.mode,
    this.barrierDismissible = true,
  });

  final String? title;
  final String? value;
  final InputNameMode mode;
  final bool barrierDismissible;

  @override
  State<InputNameDialog> createState() => _InputNameDialogState();
}

class _InputNameDialogState extends State<InputNameDialog> {
  final _textEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _textEditingController.text = widget.value ?? generate();
  }

  String generate() {
    switch (widget.mode) {
      case InputNameMode.character:
        return engine.hetu.invoke('generateCharacterName');
      case InputNameMode.city:
        return engine.hetu.invoke('generateCityName');
      case InputNameMode.organization:
        return engine.hetu.invoke('generateOrganizationName');
    }
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
      width: 280,
      height: 170,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.title ?? engine.locale('inputName')),
          actions: const [CloseButton2()],
        ),
        body: Container(
          alignment: AlignmentDirectional.center,
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 180.0,
                    height: 80,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10.0, vertical: 20.0),
                    child: TextField(
                      inputFormatters: [FilteringTextInputFormatter.deny(' ')],
                      autofocus: true,
                      controller: _textEditingController,
                    ),
                  ),
                  fluent.FilledButton(
                    onPressed: () {
                      _textEditingController.text = generate();
                      setState(() {});
                    },
                    child: Text(
                      engine.locale('random'),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: fluent.FilledButton(
                  onPressed: () {
                    final result = _textEditingController.text.nonEmptyValue;
                    Navigator.of(context).pop(result);
                  },
                  child: Text(
                    engine.locale('confirm'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
