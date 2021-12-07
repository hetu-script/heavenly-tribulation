import 'package:flutter/material.dart';

class SelectionDialog extends StatefulWidget {
  static Future<String?> show(
    BuildContext context,
    Map<String, dynamic> options,
  ) async {
    return await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SelectionDialog(options: options);
      },
      barrierDismissible: false,
    );
  }

  final Map<String, dynamic> options;

  const SelectionDialog({
    Key? key,
    required this.options,
  }) : super(key: key);

  @override
  _SelectionDialogState createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<SelectionDialog> {
  Map<String, dynamic> get _options => widget.options;

  @override
  void initState() {
    assert(_options.isNotEmpty);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final buttons = <Widget>[];
    for (final key in _options.keys) {
      final value = _options[key]!.toString();
      buttons.add(
        Container(
          margin: const EdgeInsets.all(5.0),
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.black87,
              side: const BorderSide(
                width: 1.0,
                color: Colors.white70,
              ),
              textStyle: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
            onPressed: () {
              Navigator.pop(context, key);
            },
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white60,
              ),
            ),
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
