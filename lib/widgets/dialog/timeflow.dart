import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../game/ui.dart';
import '../../game/logic/logic.dart';
import '../../engine.dart';
import '../../state/game_update.dart';
import '../../game/common.dart';
import '../../state/character.dart';

const _kTimeFlowDivisions = 10;

class TimeflowDialog extends StatefulWidget {
  static Future<int> show({
    required BuildContext context,
    required int max,
    bool Function()? onProgress,
  }) async {
    final result = await showDialog<int>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return TimeflowDialog(
          max: max,
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

  bool get finished => _progress >= widget.max * 10;

  @override
  void initState() {
    super.initState();

    _timer = Timer.periodic(
      const Duration(
          milliseconds: kAutoTimeFlowInterval ~/ _kTimeFlowDivisions),
      (timer) {
        setState(() {});

        if (finished) {
          _timer!.cancel();
          return;
        }

        ++_progress;
        if (_progress % _kTimeFlowDivisions == 0) {
          GameLogic.updateGame();
          context.read<HeroState>().update();

          final result = widget.onProgress?.call();
          if (result == true) {
            _timer!.cancel();
            return;
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
    final (_, dateTimeString) = context.watch<GameTimestampState>().get();
    final timeOfDayImageId = 'assets/images/time/${GameLogic.timeOfDay}.png';

    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 300.0,
      height: 380.0,
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(5.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image(image: AssetImage(timeOfDayImageId)),
            LinearProgressIndicator(
              value: _progress / (widget.max * 10),
            ),
            Text(dateTimeString),
            if (finished)
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
      ),
    );
  }
}
