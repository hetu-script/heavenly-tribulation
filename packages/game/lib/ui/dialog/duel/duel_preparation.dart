import 'package:flutter/material.dart';

class DuelPraparation extends StatefulWidget {
  const DuelPraparation({
    required this.data,
    required this.onFinished,
    Key? key,
  }) : super(key: key);

  final Map<String, dynamic> data;

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
