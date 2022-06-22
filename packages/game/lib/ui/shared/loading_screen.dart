import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(text),
        ),
      ),
    );
  }
}
