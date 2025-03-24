import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/common.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:provider/provider.dart';

import '../../game/ui.dart';
import '../../engine.dart';
import '../../state/game_update.dart';

const kTimeOfDayImageIds = {
  0: 'morning',
  1: 'afternoon',
  2: 'evening',
  3: 'midnight',
};

class TimeflowDialog extends StatefulWidget {
  static Future<void> show({
    required BuildContext context,
    required int max,
    void Function()? onProgress,
  }) {
    return showDialog<void>(
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
  }

  const TimeflowDialog({
    super.key,
    required this.max,
    this.onProgress,
  });

  final int max;
  final void Function()? onProgress;

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
      const Duration(milliseconds: 100),
      (timer) {
        if (!finished) {
          setState(() {
            ++_progress;
            if (_progress % 10 == 0) {
              widget.onProgress?.call();
              engine.hetu.invoke('updateGame');
            }
          });
        } else {
          _timer!.cancel();
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
    final (gameDateTimeString, gameTimestamp) =
        context.watch<GameTimestampState>().get();
    final tickOfDay = gameTimestamp % kTicksPerDay;
    final timeOfDayImageId =
        'assets/images/time/${kTimeOfDayImageIds[tickOfDay]}.png';

    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor,
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
            Text(gameDateTimeString),
            if (finished)
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
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
