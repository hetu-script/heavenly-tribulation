import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/extensions.dart';

import '../../ui.dart';

const kProgressIndicatorSpeed = 0.036;

class ProgressIndicator extends StatefulWidget {
  static Future<void> show({
    required BuildContext context,
    required String title,
    bool? Function()? checkProgress,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return ProgressIndicator(
          title: title,
          checkProgress: checkProgress,
        );
      },
    );
  }

  const ProgressIndicator({
    super.key,
    required this.title,
    this.checkProgress,
  });

  final String title;
  final bool? Function()? checkProgress;

  @override
  State<ProgressIndicator> createState() => _ProgressIndicatorState();
}

class _ProgressIndicatorState extends State<ProgressIndicator> {
  Timer? _timer;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(milliseconds: 50),
      (timer) {
        if (_progress < 1.0) {
          setState(() {
            _progress += kProgressIndicatorSpeed;
          });
        } else {
          if (widget.checkProgress == null) {
            _timer?.cancel();
            Navigator.of(context).pop();
          } else {
            final result = widget.checkProgress!();
            if (result == true) {
              setState(() {
                _progress = 0.0;
              });
            } else {
              _timer?.cancel();
              Navigator.of(context).pop();
            }
          }
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
    return ResponsiveView(
      alignment: AlignmentDirectional.center,
      child: SizedBox(
        width: 140,
        height: 140,
        child: Scaffold(
          backgroundColor: GameUI.backgroundColor,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Text(widget.title),
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
