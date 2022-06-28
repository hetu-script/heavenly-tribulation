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
      BuildContext context, HTStruct char1, HTStruct char2, String? type) {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return Duel(
          char1: char1,
          char2: char2,
          type: type,
        );
      },
    );
  }

  final HTStruct char1;
  final HTStruct char2;
  final String? type;

  const Duel({
    super.key,
    required this.char1,
    required this.char2,
    this.type,
  });

  @override
  State<Duel> createState() => _DuelState();
}

class _DuelState extends State<Duel> {
  Timer? _timer;
  int _frames = 0;
  HTStruct? _data;
  int char1Index = 0, char2Index = 0;
  int _char1Frames = 0;
  bool _char1InRecovery = false;
  double _char1Cooldown = 0;
  HTStruct? _currentChar1Item;
  int _char2Frames = 0;
  bool _char2InRecovery = false;
  double _char2Cooldown = 0;
  HTStruct? _currentChar2Item;

  bool get finished => _data != null && _frames >= _data!['frames'];

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
    _startDuel();
  }

  void _startDuel() {
    _data = engine.invoke('Duel', positionalArgs: [
      widget.char1,
      widget.char2
    ], namedArgs: {
      'type': widget.type,
    });
    _currentChar1Item = getNextActivatedItem('char1');
    _currentChar2Item = getNextActivatedItem('char2');
    _startTimer();
  }

  // tag 取值只能是 'char1'，'char2'
  HTStruct? getNextActivatedItem(String tag) {
    if (_data!['logs'][tag].isEmpty) return null;
    if (char1Index >= _data!['logs'][tag].length) {
      char1Index = 0;
    }
    final item = _data!['logs'][tag][char1Index];
    ++char1Index;
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
      const Duration(milliseconds: 400),
      (Timer timer) {
        setState(() {
          if (finished) {
            timer.cancel();
            _frames = 0;
          } else {
            if (!_char1InRecovery) {
              final startUp = _currentChar1Item!['startUp'];
              if (_char1Frames >= startUp) {
                _char1InRecovery = true;
                _char1Frames = 0;
              }
              _char1Cooldown = _char1Frames / startUp;
            } else {
              final recovery = _currentChar1Item!['recovery'];
              if (_char1Frames >= recovery) {
                _char1InRecovery = false;
                _char1Frames = 0;
                _currentChar1Item = getNextActivatedItem('char1');
              }
              _char1Cooldown = _char1Frames / recovery;
            }
            ++_char1Frames;
            ++_frames;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> lines = [];
    if (_data != null) {
      for (var i = 0; i < _data!['messages'].length; ++i) {
        final text = _data!['messages'][i].toString();
        lines.add(
          Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        );
      }
    }
    final char1StatsPercentage = engine.invoke('getStatsPercentageOfCharacter',
        positionalArgs: [widget.char1]);
    final char2StatsPercentage = engine.invoke('getStatsPercentageOfCharacter',
        positionalArgs: [widget.char2]);

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
          title: Text(
              '${widget.char1['name']} vs ${widget.char2['name']} ($_frames)'),
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
                              name: widget.char1['name'],
                              avatarAssetKey:
                                  'assets/images/${widget.char1['avatar']}',
                            ),
                            Column(
                              children: [
                                DynamicColorProgressBar(
                                  title: '${engine.locale['life']}: ',
                                  value: char1StatsPercentage['life']['value']
                                      .toInt(),
                                  max: char1StatsPercentage['life']['max']
                                      .toInt(),
                                  size: const Size(100.0, 24.0),
                                  colors: const <Color>[
                                    Colors.red,
                                    Colors.green
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        EquipmentsView(
                          verticalMargin: 5.0,
                          horizontalMargin: 5.0,
                          data: widget.char1['equipments'],
                          selectedIndex: _currentChar1Item?['index'] ?? 0,
                          cooldown: _char1Cooldown,
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
                    width: 250.0,
                    height: 220.0,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Avatar(
                              name: widget.char2['name'],
                              avatarAssetKey:
                                  'assets/images/${widget.char2['avatar']}',
                            ),
                            Column(
                              children: [
                                DynamicColorProgressBar(
                                  title: '${engine.locale['life']}: ',
                                  value: char2StatsPercentage['life']['value']
                                      .toInt(),
                                  max: char2StatsPercentage['life']['max']
                                      .toInt(),
                                  size: const Size(100.0, 24.0),
                                  colors: const <Color>[
                                    Colors.red,
                                    Colors.green
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        EquipmentsView(
                          verticalMargin: 5.0,
                          horizontalMargin: 5.0,
                          data: widget.char2['equipments'],
                          selectedIndex: _currentChar2Item?['index'] ?? 0,
                          cooldown: _char2Cooldown,
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
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: ElevatedButton(
                      onPressed: () {
                        if (finished) {
                          Navigator.pop(context);
                        } else {
                          _timer?.cancel();
                          setState(() {
                            _frames = _data?['frames'] ?? 0;
                            // _visibleLines = _data?['messages'].length ?? 1;
                          });
                        }
                      },
                      child: finished
                          ? Text(engine.locale['close'])
                          : Text(engine.locale['skip']),
                    ),
                  ),
                  if (finished)
                    Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: ElevatedButton(
                        onPressed: () {
                          engine.invoke('rejuvenate',
                              positionalArgs: [widget.char1]);
                          engine.invoke('rejuvenate',
                              positionalArgs: [widget.char2]);
                          _startDuel();
                        },
                        child: Text(engine.locale['retry']),
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
