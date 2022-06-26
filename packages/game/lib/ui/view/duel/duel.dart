import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import '../../shared/responsive_route.dart';

class Duel extends StatefulWidget {
  static Future<void> show(BuildContext context, HTStruct data) {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return Duel(data);
      },
    );
  }

  // use dynamic list here to compatible with Hetu list
  final HTStruct data;

  const Duel(this.data, {super.key});

  @override
  State<Duel> createState() => _DuelState();
}

class _DuelState extends State<Duel> {
  Timer? _timer;
  int _count = 1;
  late List _log;

  bool get finished => _count >= _log.length;

  late final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _timer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _log = widget.data['log'];
    assert(_log.isNotEmpty);
    _startTimer();
  }

  void _startTimer() {
    _count = 1;
    _timer = Timer.periodic(
      const Duration(milliseconds: 800),
      (Timer timer) {
        setState(() {
          if (finished) {
            timer.cancel();
          } else {
            ++_count;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> lines = [];
    for (var i = 0; i < _count; ++i) {
      final text = _log[i].toString();
      lines.add(
        Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyText1,
        ),
      );
    }

    // executes after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    });

    // _lines = <Widget>[Text('what?')];

    return ResponsiveRoute(
      alignment: AlignmentDirectional.bottomCenter,
      size: const Size(800.0, 600.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
              '${widget.data['char1Name']} vs ${widget.data['char2Name']}'),
        ),
        body: Container(
          margin: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: ListView(
                    shrinkWrap: true,
                    children: lines,
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      onPressed: () {},
                      child: Text(engine.locale['retry']),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        if (finished) {
                          Navigator.pop(context);
                        } else {
                          _timer?.cancel();
                          setState(() {
                            _count = _log.length;
                          });
                        }
                      },
                      child: finished
                          ? Text(engine.locale['close'])
                          : Text(engine.locale['skip']),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
