import 'package:flutter/material.dart';
import 'package:samsara/ui/loading_screen.dart' as samsara;

import '../config.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  Widget build(BuildContext context) {
    return samsara.LoadingScreen(
      text: engine.locale('loading'),
    );
  }
}
