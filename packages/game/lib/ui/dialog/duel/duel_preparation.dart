import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

class DuelPraparation extends StatefulWidget {
  const DuelPraparation({
    Key? key,
    required this.data,
    required this.onFinished,
  }) : super(key: key);

  final HTStruct data;

  final void Function() onFinished;

  @override
  _DuelPraparationState createState() => _DuelPraparationState();
}

class _DuelPraparationState extends State<DuelPraparation> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
