import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black,
      child: Container(
        padding: const EdgeInsets.all(25.0),
        alignment: Alignment.bottomRight,
        child: Text(
          text,
          style: const TextStyle(fontSize: 18.0),
        ),
      ),
    );
  }
}
