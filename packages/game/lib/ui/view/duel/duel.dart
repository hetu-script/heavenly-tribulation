import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import '../../shared/responsive_route.dart';
import '../character/build/equipments.dart';
import '../../shared/avatar.dart';
import '../../shared/dynamic_color_progressbar.dart';

class Duel extends StatefulWidget {
  static Future<void> show(BuildContext context, HTStruct char1, HTStruct char2,
      String? type, HTStruct? data) {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return Duel(
          char1: char1,
          char2: char2,
          type: type,
          data: data,
        );
      },
    );
  }

  final HTStruct char1;
  final HTStruct char2;
  final String? type;
  final HTStruct? data;

  const Duel({
    super.key,
    required this.char1,
    required this.char2,
    this.type,
    this.data,
  });

  @override
  State<Duel> createState() => _DuelState();
}

class _DuelState extends State<Duel> {
  Timer? _timer;
  HTStruct? _data;
  int _frames = 0;
  List<String> _messages = [];
  int _char1ActionIter = 0, _char2ActionIter = 0;
  int _char1Ticks = 0, _char2Ticks = 0;
  double _char1Cooldown = 0, _char2Cooldown = 0;
  bool _char1InRecovery = false, _char2InRecovery = false;
  HTStruct? _currentChar1Item, _currentChar2Item;
  HTStruct? _char1StatsPercentage, _char2StatsPercentage;
  late num _char1Health, _char2Health;
  late int _char1HealthMax, _char2HealthMax;

  bool get finished => _data != null && _frames > _data!['frames'];

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

    _char1StatsPercentage = engine.invoke('getStatsPercentageOfCharacter',
        positionalArgs: [widget.char1]);
    _char2StatsPercentage = engine.invoke('getStatsPercentageOfCharacter',
        positionalArgs: [widget.char2]);
    _startDuel(data: widget.data);
  }

  void _reset() {
    _char1ActionIter = 0;
    _char2ActionIter = 0;
    _char1Ticks = 0;
    _char2Ticks = 0;
    _char1Cooldown = 0;
    _char2Cooldown = 0;
    _char1InRecovery = false;
    _char2InRecovery = false;
  }

  void _startDuel({HTStruct? data}) {
    _frames = 0;
    _messages = [];
    _data = data ??
        engine.invoke('Duel', positionalArgs: [
          widget.char1,
          widget.char2
        ], namedArgs: {
          'type': widget.type,
        });
    _reset();
    _char1Health = _char1StatsPercentage!['life']['value'].toInt();
    _char1HealthMax = _char1StatsPercentage!['life']['max'].toInt();
    _char2Health = _char2StatsPercentage!['life']['value'].toInt();
    _char2HealthMax = _char2StatsPercentage!['life']['max'].toInt();
    _currentChar1Item = getNextChar1ActivatedItem();
    _currentChar2Item = getNextChar2ActivatedItem();
    _startTimer();
  }

  HTStruct? getNextChar1ActivatedItem() {
    if (_data!['actions']['char1'].isEmpty) return null;
    if (_char1ActionIter >= _data!['actions']['char1'].length) {
      _char1ActionIter = 0;
    }
    final item = _data!['actions']['char1'][_char1ActionIter];
    ++_char1ActionIter;
    return item;
  }

  HTStruct? getNextChar2ActivatedItem() {
    if (_data!['actions']['char2'].isEmpty) return null;
    if (_char2ActionIter >= _data!['actions']['char2'].length) {
      _char2ActionIter = 0;
    }
    final item = _data!['actions']['char2'][_char2ActionIter];
    ++_char2ActionIter;
    return item;
  }

  void _startTimer() {
    assert(_data != null);
    assert(_currentChar1Item != null);
    assert(_currentChar2Item != null);
    _frames = 0;
    // _visibleLines = 0;
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (Timer timer) {
        setState(() {
          if (finished) {
            timer.cancel();
            _reset();
          } else {
            if (!_char1InRecovery) {
              final startUp = _currentChar1Item!['startUp'];
              if (_char1Ticks >= startUp) {
                _char1Ticks = 0;
                _char1InRecovery = true;
                _char1Cooldown = 0;
                _messages.add(_currentChar1Item!['message']);
                final newHP = _char2Health - _currentChar1Item!['damage'];
                _char2Health = newHP >= 0 ? newHP : 0;
              } else {
                ++_char1Ticks;
              }
              _char1Cooldown = startUp > 0 ? _char1Ticks / startUp : 1.0;
            } else {
              final recovery = _currentChar1Item!['recovery'];
              if (_char1Ticks >= recovery) {
                _char1Ticks = 0;
                _char1InRecovery = false;
                _currentChar1Item = getNextChar1ActivatedItem();
                _char1Cooldown = 0;
              } else {
                ++_char1Ticks;
              }
              _char1Cooldown = recovery > 0 ? _char1Ticks / recovery : 1.0;
            }

            if (!_char2InRecovery) {
              final startUp = _currentChar2Item!['startUp'];
              if (_char2Ticks >= startUp) {
                _char2Ticks = 0;
                _char2InRecovery = true;
                _char2Cooldown = 0;
                _messages.add(_currentChar2Item!['message']);
                final newHP = _char1Health - _currentChar2Item!['damage'];
                _char1Health = newHP >= 0 ? newHP : 0;
              } else {
                ++_char2Ticks;
              }
              _char2Cooldown = startUp > 0 ? _char2Ticks / startUp : 1.0;
            } else {
              final recovery = _currentChar2Item!['recovery'];
              if (_char2Ticks >= recovery) {
                _char2Ticks = 0;
                _char2InRecovery = false;
                _currentChar2Item = getNextChar2ActivatedItem();
                _char2Cooldown = 0;
              } else {
                ++_char2Ticks;
              }
              _char2Cooldown = recovery > 0 ? _char2Ticks / recovery : 1.0;
            }
            ++_frames;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // List<Widget> lines = [];
    // if (_data != null) {
    //   for (var i = 0; i < _data!['messages'].length; ++i) {
    //     final text = _data!['messages'][i].toString();
    //     lines.add(
    //       Text(
    //         text,
    //         textAlign: TextAlign.center,
    //         style: Theme.of(context).textTheme.bodyText1,
    //       ),
    //     );
    //   }
    // }

    // execute after build completed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    });

    return ResponsiveRoute(
      alignment: AlignmentDirectional.center,
      size: const Size(800.0, 600.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('${widget.char1['name']} vs ${widget.char2['name']}'),
          toolbarHeight: 40.0,
        ),
        body: Container(
          margin: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    width: 270.0,
                    height: 270.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Avatar(
                          name: widget.char1['name'],
                          avatarAssetKey:
                              'assets/images/${widget.char1['avatar']}',
                        ),
                        DynamicColorProgressBar(
                          size: const Size(175.0, 24.0),
                          value: _char1Health.truncate(),
                          max: _char1HealthMax,
                          showPercentage: false,
                          colors: const <Color>[Colors.red, Colors.green],
                        ),
                        EquipmentsView(
                          verticalMargin: 5.0,
                          horizontalMargin: 5.0,
                          data: widget.char1['equipments'],
                          selectedIndex: _currentChar1Item?['index'] ?? 0,
                          cooldownValue: _char1Cooldown,
                          cooldownColor:
                              _char1InRecovery ? Colors.blue : Colors.yellow,
                        ),
                      ],
                    ),
                  ),
                  const Image(
                    width: 80.0,
                    fit: BoxFit.contain,
                    image: AssetImage('assets/images/battle/versus.png'),
                  ),
                  SizedBox(
                    width: 270.0,
                    height: 270.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Avatar(
                          name: widget.char2['name'],
                          avatarAssetKey:
                              'assets/images/${widget.char2['avatar']}',
                        ),
                        DynamicColorProgressBar(
                          size: const Size(175.0, 24.0),
                          value: _char2Health.truncate(),
                          max: _char2HealthMax,
                          showPercentage: false,
                          colors: const <Color>[Colors.red, Colors.green],
                        ),
                        EquipmentsView(
                          verticalMargin: 5.0,
                          horizontalMargin: 5.0,
                          data: widget.char2['equipments'],
                          selectedIndex: _currentChar2Item?['index'] ?? 0,
                          cooldownValue: _char2Cooldown,
                          cooldownColor:
                              _char2InRecovery ? Colors.blue : Colors.yellow,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    height: 100.0,
                    width: 570.0,
                    decoration: BoxDecoration(
                      borderRadius: kBorderRadius,
                      border: Border.all(color: kForegroundColor),
                    ),
                    child: SingleChildScrollView(
                      controller: _scrollController,
                      child: Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: ListView(
                          shrinkWrap: true,
                          children:
                              _messages.map((line) => Text(line)).toList(),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (finished)
                        Padding(
                          padding: const EdgeInsets.all(5.0),
                          child: ElevatedButton(
                            onPressed: () {
                              _timer?.cancel();
                              engine.invoke('rejuvenate',
                                  positionalArgs: [widget.char1]);
                              engine.invoke('rejuvenate',
                                  positionalArgs: [widget.char2]);
                              _startDuel();
                            },
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
                                _reset();
                                _messages =
                                    List<String>.from(_data!['messages']);
                                _char1Health = _data!['stats']['char1']['life'];
                                _char2Health = _data!['stats']['char2']['life'];
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
            ],
          ),
        ),
      ),
    );
  }
}
