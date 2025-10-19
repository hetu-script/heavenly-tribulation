import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../dropdown_menu_button.dart';
import '../../ui.dart';
import '../ui/close_button2.dart';

class SelectMenuDialog extends StatefulWidget {
  static Future<String?> show({
    required BuildContext context,
    required Map<String, String> selections,
  }) {
    return showDialog<String?>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return SelectMenuDialog(selections: selections);
      },
    );
  }

  SelectMenuDialog({
    super.key,
    required this.selections,
    this.selectedValue,
  })  : assert(selections.isNotEmpty),
        assert(selectedValue == null || selections.containsKey(selectedValue));

  final Map<String, String> selections;
  final String? selectedValue;

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
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      child: SizedBox(
        width: 320,
        height: 200,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(engine.locale('selectOne')),
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
      ),
    );
  }
}
