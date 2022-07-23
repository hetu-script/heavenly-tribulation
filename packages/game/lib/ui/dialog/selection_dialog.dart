import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../global.dart';
import '../../event/events.dart';

class SelectionDialog extends StatelessWidget {
  static Future<String?> show({
    required BuildContext context,
    required HTStruct selections,
  }) async {
    assert(selections.isNotEmpty);
    return await showDialog<String>(
      context: context,
      barrierColor: kBarrierColor,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SelectionDialog(selections: selections);
      },
    );
  }

  final HTStruct selections;

  const SelectionDialog({
    super.key,
    required this.selections,
  });

  @override
  Widget build(BuildContext context) {
    final buttons = selections.keys.map((key) {
      final value = selections[key];
      return Container(
        margin: const EdgeInsets.all(5.0),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context, key);
            engine.broadcast(const UIEvent.needRebuildUI());
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
