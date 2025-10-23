import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/engine.dart';

import '../logic/logic.dart';
import '../engine.dart';
// import '../state/game_update.dart';
import '../data/common.dart';
import 'ui/responsive_view.dart';

class TimeflowDialog extends StatefulWidget {
  static Future<int> show({
    required BuildContext context,
    int? ticks,
    bool Function()? onProgress,
  }) async {
    final result = await showDialog<int>(
      context: context,
      barrierColor: Colors.transparent,
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
    this.max,
    this.onProgress,
  });

  final int? max;
  final bool Function()? onProgress;

  @override
  State<TimeflowDialog> createState() => _TimeflowDialogState();
}

class _TimeflowDialogState extends State<TimeflowDialog> {
  int initialLogLength = 0;

  Timer? _timer;
  int _progress = 0;

  bool _isFinished = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    initialLogLength = engine.getLogs(level: Level.debug).length;

    _timer = Timer.periodic(
      const Duration(milliseconds: kTimeFlowInterval ~/ kTicksPerTime),
      (timer) async {
        ++_progress;
        if (widget.max != null) {
          _isFinished = _progress >= widget.max!;
        }

        if (_isFinished) {
          _timer!.cancel();
        }

        final updated = await GameLogic.updateGame(ticks: 1);

        if (updated) {
          final result = widget.onProgress?.call();
          if (result == true) {
            _isFinished = true;
            _timer!.cancel();
          }
        }

        setState(() {});
      },
    );
  }

  @override
  void dispose() {
    super.dispose();

    _timer?.cancel();
    _scrollController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final (_, dateTimeString) = context.watch<GameTimestampState>().get();
    final timeOfDayImageId = 'assets/images/time/${GameLogic.timeString}.png';

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });

    final logs =
        engine.getLogs(level: Level.debug).skip(initialLogLength).toList();

    return ResponsiveView(
      width: 900.0,
      height: 360.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ScrollConfiguration(
              behavior: MaterialScrollBehavior(),
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: ListView(
                    shrinkWrap: true,
                    children: logs.map((log) {
                      return Text(log);
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: 300.0,
            height: 360.0,
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Image(
                  image: AssetImage(timeOfDayImageId),
                  fit: BoxFit.contain,
                ),
                if (widget.max != null)
                  LinearProgressIndicator(
                    value: _progress / widget.max!,
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 10.0),
                  child: Row(
                    children: [
                      const Spacer(),
                      fluent.FilledButton(
                        onPressed: () {
                          if (_isFinished) {
                            Navigator.of(context).pop(_progress);
                          } else {
                            _isFinished = true;
                            _timer?.cancel();
                            setState(() {});
                          }
                        },
                        child: Text(
                          engine.locale(_isFinished ? 'leave' : 'stop'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
