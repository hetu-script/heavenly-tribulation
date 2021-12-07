import 'package:flutter/material.dart';

class LoadingScreen extends StatelessWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: Material(
        color: Colors.black,
        child: Center(
          child: Text(
            'Loading...',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
