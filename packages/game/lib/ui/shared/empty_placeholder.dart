import 'package:flutter/material.dart';

import '../../engine/engine.dart';

class EmptyPlaceholder extends StatelessWidget {
  const EmptyPlaceholder({Key? key, this.text}) : super(key: key);

  final String? text;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            text ?? engine.locale['empty'],
          ),
        ),
      ),
    );
  }
}
