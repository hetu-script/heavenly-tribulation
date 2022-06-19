import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../global.dart';

class SelectionDialog extends StatefulWidget {
  static Future<dynamic> show(
    BuildContext context,
    HTStruct selections,
  ) async {
    assert(selections.isNotEmpty);
    return await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return SelectionDialog(selections: selections);
      },
      barrierColor: kBarrierColor,
      barrierDismissible: false,
    );
  }

  final HTStruct selections;

  const SelectionDialog({
    Key? key,
    required this.selections,
  }) : super(key: key);

  @override
  State<SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<SelectionDialog> {
  HTStruct get _selections => widget.selections;

  @override
  void initState() {
    assert(_selections.isNotEmpty);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final buttons = _selections.keys.map((key) {
      final value = _selections[key];
      return Container(
        margin: const EdgeInsets.all(5.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context, key);
          },
          child: Text(value.toString()),
        ),
      );
    }).toList();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons,
    );
  }
}
