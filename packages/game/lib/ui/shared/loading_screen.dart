import 'package:flutter/material.dart';

import '../../global.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kBackgroundColor,
      child: Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Text(text),
        ),
      ),
    );
  }
}
