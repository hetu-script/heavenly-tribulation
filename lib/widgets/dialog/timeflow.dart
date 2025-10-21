import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/responsive_view.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../ui.dart';
import '../../logic/logic.dart';
import '../../engine.dart';
import '../../state/game_update.dart';
import '../../data/common.dart';

class TimeflowDialog extends StatefulWidget {
  static Future<int> show({
    required BuildContext context,
    required int ticks,
    bool Function()? onProgress,
  }) async {
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return TimeflowDialog(
          max: ticks,
          onProgress: onProgress,
        );
      },
    );
    return result ?? 0;
  }

  const TimeflowDialog({
    super.key,
    required this.max,
    this.onProgress,
  });

  final int max;
  final bool Function()? onProgress;

  @override
  State<TimeflowDialog> createState() => _TimeflowDialogState();
}

class _TimeflowDialogState extends State<TimeflowDialog> {
  Timer? _timer;
  int _progress = 0;

  bool _isFinished = false;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(milliseconds: kTimeFlowInterval ~/ kTicksPerTime),
      (timer) async {
        ++_progress;
        _isFinished = _progress >= widget.max;

        if (_isFinished) {
          _timer!.cancel();
        }

        final updated = await GameLogic.updateGame(ticks: 1);

        if (updated) {
          final result = widget.onProgress?.call();
          if (result == true) {
            _isFinished = true;
            _timer!.cancel();
            return;
          }
        }

        setState(() {});
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
    final (_, dateTimeString) = context.watch<GameTimestampState>().get();
    final timeOfDayImageId = 'assets/images/time/${GameLogic.timeString}.png';

    return ResponsiveView(
      cursor: GameUI.cursor,
      backgroundColor: GameUI.backgroundColor,
      width: 300.0,
      height: 380.0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Image(image: AssetImage(timeOfDayImageId)),
          LinearProgressIndicator(
            value: _progress / (widget.max),
          ),
          Text(dateTimeString),
          if (_isFinished)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: fluent.FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(_progress);
                },
                child: Text(
                  engine.locale('close'),
                ),
              ),
            )
        ],
      ),
    );
  }
}
