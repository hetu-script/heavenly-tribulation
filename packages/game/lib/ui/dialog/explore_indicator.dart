import 'dart:async';

import 'package:flutter/material.dart';
import '../shared/responsive_window.dart';
import '../../global.dart';

class ExploreIndicator extends StatefulWidget {
  static Future<void> show({
    required BuildContext context,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return const ExploreIndicator();
      },
    );
  }

  const ExploreIndicator({
    super.key,
  });

  @override
  State<ExploreIndicator> createState() => _ExploreIndicatorState();
}

class _ExploreIndicatorState extends State<ExploreIndicator> {
  Timer? _timer;
  double _progress = 0;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) {
        if (_progress < 1.0) {
          setState(() {
            _progress += 0.018;
          });
        } else {
          _timer?.cancel();
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      child: SizedBox(
        width: 140,
        height: 140,
        child: Scaffold(
          backgroundColor: kBackgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(engine.locale['explore']),
          ),
          body: Align(
            alignment: AlignmentDirectional.center,
            child: Stack(
              alignment: AlignmentDirectional.center,
              children: [
                Positioned(
                  child: CircularProgressIndicator(
                    value: _progress,
                  ),
                ),
                Positioned(
                  child: Text(
                    _progress.toPercentageString(),
                    style: const TextStyle(fontSize: 10.0),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
