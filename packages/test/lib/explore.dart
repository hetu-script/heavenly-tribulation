import 'dart:async';

import 'package:flutter/material.dart';

class ExploreDialog extends StatefulWidget {
  static Future<void> show({
    required BuildContext context,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return ExploreDialog(
          key: UniqueKey(),
        );
      },
    );
  }

  const ExploreDialog({
    super.key,
  });

  @override
  State<ExploreDialog> createState() => _ExploreDialogState();
}

class _ExploreDialogState extends State<ExploreDialog> {
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
            _progress += 0.02;
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
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        alignment: AlignmentDirectional.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Scaffold(
              appBar: AppBar(
                automaticallyImplyLeading: false,
                title: const Text('search'),
              ),
              body: Align(
                alignment: AlignmentDirectional.center,
                child: Column(
                  children: [
                    SizedBox(
                      width: 150,
                      height: 50,
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
                              _progress.toStringAsFixed(2),
                              style: const TextStyle(fontSize: 10.0),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
