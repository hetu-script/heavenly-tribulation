import 'dart:async';

import 'package:flutter/material.dart';

class DuelGame extends StatefulWidget {
  final List<dynamic> log;

  const DuelGame(this.log, {Key? key}) : super(key: key);

  @override
  _DuelGameState createState() => _DuelGameState();
}

class _DuelGameState extends State<DuelGame> {
  Timer? _timer;
  int _count = 1;
  bool _finished = false;

  bool get finished => _finished || _count >= widget.log.length;

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
          });
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
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  Widget build(BuildContext context) {
    final richTexts = <Text>[];
    for (var i = 0; i < (finished ? widget.log.length : _count); ++i) {
      final text = widget.log[i].toString();
      richTexts.add(
        Text.rich(
          TextSpan(
            text: text,
          ),
          style: Theme.of(context).textTheme.bodyText1,
        ),
      );
    }

    final widgets = <Widget>[
      ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 200,
          minHeight: 275,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: richTexts,
          ),
        ),
      )
    ];

    if (finished) {
      widgets.add(ElevatedButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text('Close!'),
      ));
    }

    return Center(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (_count > 30) {
              _finished = true;
            }
          });
        },
        child: Container(
          padding: const EdgeInsets.all(5),
          width: 210,
          height: 320,
          decoration: BoxDecoration(
            // image: const DecorationImage(
            //   image: NetworkImage(
            //       'https://flutter.github.io/assets-for-api-docs/assets/widgets/owl-2.jpg'),
            //   fit: BoxFit.fill,
            // ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(children: widgets),
        ),
      ),
    );
  }
}
