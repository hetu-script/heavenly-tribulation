import 'package:flutter/material.dart';

class EmptyPlaceholder extends StatelessWidget {
  const EmptyPlaceholder(
    this.text, {
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(text),
        ),
      ),
    );
  }
}
