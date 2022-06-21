import 'dart:async';

import 'package:flutter/material.dart';

import '../../../global.dart';
import '../../shared/responsive_route.dart';

class Duel extends StatefulWidget {
  static Future<void> show(BuildContext context, List<dynamic> log) {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return Duel(log);
      },
    );
  }

  // use dynamic list here to compatible with Hetu list
  final List<dynamic> log;

  const Duel(this.log, {super.key});

  @override
  State<Duel> createState() => _DuelState();
}

class _DuelState extends State<Duel> {
  Timer? _timer;
  int _count = 1;
  bool _finished = false;

  bool get finished => _finished || _count >= widget.log.length;

  late final ScrollController _scrollController;

  void _startTimer() {
    _timer = Timer.periodic(
      const Duration(milliseconds: 800),
      (Timer timer) {
        if (finished) {
          setState(() {
            timer.cancel();
          });
        } else {
          setState(() {
            ++_count;
            _scrollController.animateTo(
              _scrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastOutSlowIn,
            );
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final lines = <Text>[];
    for (var i = 0; i < (finished ? widget.log.length : _count); ++i) {
      final text = widget.log[i].toString();
      lines.add(
        Text.rich(
          TextSpan(
            text: text,
          ),
          style: Theme.of(context).textTheme.bodyText1,
        ),
      );
    }

    final widgets = [
      ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 200,
          minHeight: 275,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: lines,
          ),
        ),
      )
    ];

    final layout = GestureDetector(
      onTap: () {
        setState(() {
          if (_count > 30) {
            _finished = true;
          }
        });
      },
      child: Container(
        color: kBackgroundColor,
        padding: const EdgeInsets.fromLTRB(10.0, 15.0, 10.0, 15.0),
        width: 400,
        height: 400,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: ListView(
                  controller: _scrollController,
                  children: widgets,
                ),
              ),
            ),
            if (finished)
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(engine.locale['close']),
              ),
          ],
        ),
      ),
    );

    return ResponsiveRoute(
      alignment: AlignmentDirectional.bottomCenter,
      size: const Size(300.0, 300.0),
      child: layout,
    );
  }
}
