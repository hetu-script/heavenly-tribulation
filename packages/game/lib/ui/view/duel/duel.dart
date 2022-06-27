import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import '../../shared/responsive_route.dart';
import '../character/build/equipments.dart';
import '../../shared/avatar.dart';
import '../../shared/dynamic_color_progressbar.dart';

class Duel extends StatefulWidget {
  static Future<void> show(
      BuildContext context, HTStruct hero, HTStruct enemy, String? type) {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return Duel(
          hero: hero,
          enemy: enemy,
          type: type,
        );
      },
    );
  }

  final HTStruct hero;
  final HTStruct enemy;
  final String? type;

  const Duel({
    super.key,
    required this.hero,
    required this.enemy,
    this.type,
  });

  @override
  State<Duel> createState() => _DuelState();
}

class _DuelState extends State<Duel> {
  Timer? _timer;
  int _count = 1;
  HTStruct? _result;

  bool get finished => _result != null && _count >= _result!['log'].length;

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
    _result = _getDuelResult();
    _startTimer();
  }

  HTStruct _getDuelResult() {
    return engine.invoke('Duel', positionalArgs: [
      widget.hero,
      widget.enemy
    ], namedArgs: {
      'type': widget.type,
    });
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
    if (_result != null) {
      for (var i = 0; i < _count; ++i) {
        final text = _result!['log'][i].toString();
        lines.add(
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        );
      }
    }
    final heroStatsPercentage = engine
        .invoke('getStatsPercentageOfCharacter', positionalArgs: [widget.hero]);
    final enemyStatsPercentage = engine.invoke('getStatsPercentageOfCharacter',
        positionalArgs: [widget.enemy]);

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
      alignment: AlignmentDirectional.center,
      size: const Size(800.0, 600.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('${widget.hero['name']} vs ${widget.enemy['name']}'),
        ),
        body: Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 250.0,
                    height: 220.0,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Avatar(
                              name: widget.hero['name'],
                              avatarAssetKey:
                                  'assets/images/${widget.hero['avatar']}',
                            ),
                            Column(
                              children: [
                                DynamicColorProgressBar(
                                  title: '${engine.locale['life']}: ',
                                  value: heroStatsPercentage['life']['value']
                                      .toInt(),
                                  max: heroStatsPercentage['life']['max']
                                      .toInt(),
                                  size: const Size(100.0, 24.0),
                                  colors: const <Color>[
                                    Colors.red,
                                    Colors.green
                                  ],
                                ),
                                DynamicColorProgressBar(
                                  title: '${engine.locale['stamina']}: ',
                                  value: heroStatsPercentage['stamina']['value']
                                      .toInt(),
                                  max: heroStatsPercentage['stamina']['max']
                                      .toInt(),
                                  size: const Size(100.0, 24.0),
                                  colors: const <Color>[
                                    Colors.yellow,
                                    Colors.blue
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        EquipmentsView(
                          verticalMargin: 10.0,
                          horizontalMargin: 5.0,
                          data: widget.hero['talismans']['equipments'],
                          cooldown1: 0.1,
                        ),
                        EquipmentsView(
                          verticalMargin: 0.0,
                          horizontalMargin: 5.0,
                          data: widget.hero['skills']['equipments'],
                        ),
                      ],
                    ),
                  ),
                  const Image(
                    width: 80.0,
                    fit: BoxFit.contain,
                    image: AssetImage('assets/images/maze/versus.png'),
                  ),
                  SizedBox(
                    width: 250.0,
                    height: 220.0,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Avatar(
                              name: widget.enemy['name'],
                              avatarAssetKey:
                                  'assets/images/${widget.enemy['avatar']}',
                            ),
                            Column(
                              children: [
                                DynamicColorProgressBar(
                                  title: '${engine.locale['life']}: ',
                                  value: enemyStatsPercentage['life']['value']
                                      .toInt(),
                                  max: enemyStatsPercentage['life']['max']
                                      .toInt(),
                                  size: const Size(100.0, 24.0),
                                  colors: const <Color>[
                                    Colors.red,
                                    Colors.green
                                  ],
                                ),
                                DynamicColorProgressBar(
                                  title: '${engine.locale['stamina']}: ',
                                  value: enemyStatsPercentage['stamina']
                                          ['value']
                                      .toInt(),
                                  max: enemyStatsPercentage['stamina']['max']
                                      .toInt(),
                                  size: const Size(100.0, 24.0),
                                  colors: const <Color>[
                                    Colors.yellow,
                                    Colors.blue
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        EquipmentsView(
                          verticalMargin: 10.0,
                          horizontalMargin: 5.0,
                          data: widget.hero['talismans']['equipments'],
                        ),
                        EquipmentsView(
                          verticalMargin: 0.0,
                          horizontalMargin: 5.0,
                          data: widget.hero['skills']['equipments'],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                margin: const EdgeInsets.all(10.0),
                height: 120.0,
                width: 480.0,
                decoration: BoxDecoration(
                  borderRadius: kBorderRadius,
                  border: Border.all(color: kForegroundColor),
                ),
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ListView(
                      shrinkWrap: true,
                      children: lines,
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (finished)
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: ElevatedButton(
                        onPressed: () {},
                        child: Text(engine.locale['retry']),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ElevatedButton(
                      onPressed: () {
                        if (finished) {
                          Navigator.pop(context);
                        } else {
                          _timer?.cancel();
                          setState(() {
                            _count = _result?['log'].length ?? 1;
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
