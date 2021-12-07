import 'package:flutter/material.dart';

import 'duel_preparation.dart';
import 'duel_game.dart';

class Duel extends StatefulWidget {
  static Future<void> show(BuildContext context, Map<String, dynamic> data) {
    return showDialog<void>(
      context: context,
      builder: (context) {
        return Duel(data: data);
      },
    );
  }

  const Duel({required this.data, Key? key}) : super(key: key);

  final Map<String, dynamic> data;

  @override
  _DuelState createState() => _DuelState();
}

class _DuelState extends State<Duel> {
  bool _isPreparing = true;

  final _log = <String>[];

  @override
  Widget build(BuildContext context) {
    if (_isPreparing) {
      return DuelPraparation(data: widget.data, onFinished: _finishPraparation);
    } else {
      return DuelGame(_log);
    }
  }

  void _finishPraparation() {
    setState(() {
      _isPreparing = false;
    });
  }
}
