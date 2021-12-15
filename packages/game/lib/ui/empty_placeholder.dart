import 'package:flutter/material.dart';

class EmptyPlaceholder extends StatelessWidget {
  const EmptyPlaceholder({Key? key, required this.text}) : super(key: key);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(
            text,
            style: const TextStyle(color: Colors.black),
          ),
        ),
      ),
    );
  }
}
