import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../ui/dropdown_menu_button.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';
import '../../ui.dart';

class SelectMenuDialog extends StatefulWidget {
  static Future<String?> show({
    required BuildContext context,
    required Map<String, String> selections,
    String? title,
    bool barrierDismissible = true,
  }) {
    return showDialog<String?>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return SelectMenuDialog(
          selections: selections,
          title: title,
          barrierDismissible: barrierDismissible,
        );
      },
    );
  }

  SelectMenuDialog({
    super.key,
    required this.selections,
    this.selectedValue,
    this.title,
    this.barrierDismissible = true,
  })  : assert(selections.isNotEmpty),
        assert(selectedValue == null || selections.containsKey(selectedValue));

  final Map<String, String> selections;
  final String? selectedValue;
  final String? title;
  final bool barrierDismissible;

  @override
  State<SelectMenuDialog> createState() => _SelectMenuDialogState();
}

class _SelectMenuDialogState extends State<SelectMenuDialog> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();

    _selectedValue = widget.selectedValue ?? widget.selections.keys.first;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      barrierDismissible: widget.barrierDismissible,
      barrierColor: null,
      backgroundColor: GameUI.backgroundColorOpaque,
      width: 320,
      height: 200,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.title ?? engine.locale('select')),
          actions: const [CloseButton2()],
        ),
        body: Container(
          alignment: AlignmentDirectional.center,
          child: Column(
            children: [
              Container(
                width: 280.0,
                height: 80,
                padding: const EdgeInsets.symmetric(
                    horizontal: 10.0, vertical: 20.0),
                child: DropdownMenuButton(
                  selected: _selectedValue,
                  selections: widget.selections,
                  onChanged: (newValue) {
                    setState(() {
                      _selectedValue = newValue;
                    });
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: fluent.FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(_selectedValue);
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
