import 'package:flutter/material.dart';

class SelectionDialog extends StatefulWidget {
  static Future<dynamic> show(
    BuildContext context,
    dynamic selections,
  ) async {
    assert(selections.isNotEmpty);
    return await showDialog<dynamic>(
      context: context,
      builder: (BuildContext context) {
        return SelectionDialog(selections: selections);
      },
      barrierDismissible: false,
    );
  }

  final dynamic selections;

  const SelectionDialog({
    Key? key,
    required this.selections,
  }) : super(key: key);

  @override
  _SelectionDialogState createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<SelectionDialog> {
  dynamic get _selections => widget.selections;

  @override
  void initState() {
    assert(_selections.isNotEmpty);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];
    for (final key in _selections.keys) {
      final value = _selections[key];
      buttons.add(
        Container(
          margin: const EdgeInsets.all(5.0),
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context, key);
            },
            child: Text(value.toString()),
          ),
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: buttons,
    );
  }
}
