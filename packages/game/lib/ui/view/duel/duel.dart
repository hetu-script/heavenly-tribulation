import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import 'package:samsara/flutter_ui/responsive_window.dart';
import 'battle_panel.dart';
import '../../../event/events.dart';

const kDuelTypePractice = 'practice';

class Duel extends StatefulWidget {
  static Future<HTStruct?> show(
      {required BuildContext context,
      required HTStruct char1,
      required HTStruct char2,
      String? type,
      HTStruct? data}) {
    return showDialog<HTStruct?>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return Duel(
          char1: char1,
          char2: char2,
          type: type,
          duelData: data,
        );
      },
    );
  }

  final HTStruct char1;
  final HTStruct char2;
  final String? type;
  final HTStruct? duelData;

  const Duel({
    super.key,
    required this.char1,
    required this.char2,
    this.type,
    this.duelData,
  });

  @override
  State<Duel> createState() => _DuelState();
}

class _DuelState extends State<Duel> {
  Timer? _timer;
  HTStruct? _data;
  int _frames = 0;
  List<String> _messages = [];
  int _char1Ticks = 0, _char2Ticks = 0;
  double _char1Cooldown = 0, _char2Cooldown = 0;
  HTStruct? _action, _char1Action, _char2Action;
  int _actionIter = 0;
  HTStruct? _char1InitialStats,
      _char1Stats,
      _char1ResultStats,
      _char2InitialStats,
      _char2Stats,
      _char2ResultStats;

  bool _finished = false;

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

    _startDuel(duelData: widget.duelData);
  }

  void _startDuel({HTStruct? duelData}) {
    _frames = 0;
    _messages = [];
    _data = duelData ??
        engine.invoke('Duel', positionalArgs: [
          widget.char1,
          widget.char2
        ], namedArgs: {
          'type': widget.type,
        });
    assert(_data != null);
    _char1InitialStats = _data!['initialStats']['char1'];
    _char2InitialStats = _data!['initialStats']['char2'];
    _char1Stats = _char1InitialStats!.clone();
    _char2Stats = _char2InitialStats!.clone();
    _char1ResultStats = _data!['resultStats']['char1'];
    _char2ResultStats = _data!['resultStats']['char2'];
    _reset();
    _action = getNextAction();
    _finished = false;
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (Timer timer) {
        setState(() {
          if (_action != null) {
            final int speed = _action!['speed'];
            if (_action?['isChar1Action'] == true) {
              _char1Action = _action;
              if (_char1Ticks >= speed) {
                _char1Ticks = 0;
                _char1Cooldown = 0;
                _messages.add(_action!['message']);
                _entityTakeDamage(_char2Stats!, _action!['damage']);
                int? equipmentIndex = _action!['equipmentIndex'];
                if (equipmentIndex != null) {
                  _entityTakeDamage(_char2Stats!['equipments'][equipmentIndex],
                      _action!['sharedDamage']);
                }
                _action = getNextAction();
              }
              _char1Cooldown = speed > 0 ? _char1Ticks / speed : 1.0;
            } else {
              _char2Action = _action;
              if (_char2Ticks >= speed) {
                _char2Ticks = 0;
                _char2Cooldown = 0;
                _messages.add(_action!['message']);
                _entityTakeDamage(_char1Stats!, _action!['damage']);
                int? equipmentIndex = _action!['equipmentIndex'];
                if (equipmentIndex != null) {
                  _entityTakeDamage(_char1Stats!['equipments'][equipmentIndex],
                      _action!['sharedDamage']);
                }
                _action = getNextAction();
              }
              _char2Cooldown = speed > 0 ? _char2Ticks / speed : 1.0;
            }
          }

          ++_frames;
          ++_char1Ticks;
          ++_char2Ticks;

          if (_frames > _data!['frames']) {
            timer.cancel();
            _char1Cooldown = 0;
            _char2Cooldown = 0;
            _finished = true;
            _addDuelResult();
          }
        });
      },
    );
  }

  void _addDuelResult() {
    if (_data!['result']) {
      _messages.add(
        engine.locale.getLocaleString(
          'duelVistory',
          interpolations: [
            _data!['char1Name'],
            _data!['char2Name'],
          ],
        ),
      );
    } else {
      _messages.add(
        engine.locale.getLocaleString(
          'duelVistory',
          interpolations: [
            _data!['char2Name'],
            _data!['char1Name'],
          ],
        ),
      );
    }
  }

  void _reset() {
    _frames = 0;
    _actionIter = 0;
    _char1Ticks = 0;
    _char2Ticks = 0;
    _char1Cooldown = 0;
    _char2Cooldown = 0;
  }

  HTStruct? getNextAction() {
    if (_data!['actions'].isEmpty) return null;
    if (_actionIter >= _data!['actions'].length) {
      _actionIter = 0;
    }
    final action = _data?['actions'][_actionIter];
    ++_actionIter;
    return action;
  }

  void _entityTakeDamage(HTStruct data, num damage) {
    final newHP = data['life'] - damage;
    data['life'] = newHP >= 0 ? newHP : 0;
  }

  @override
  Widget build(BuildContext context) {
    // execute after build completed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn,
      );
    });

    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      size: const Size(800.0, 600.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text('${widget.char1['name']} vs ${widget.char2['name']}'),
          toolbarHeight: 40.0,
        ),
        body: Container(
          margin: const EdgeInsets.all(5.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      BattlePanel(
                        characterData: widget.char1,
                        statsData: _char1Stats!,
                        activatedOffenseIndex:
                            _char1Action?['activatedOffenseIndex'] ?? 0,
                        cooldownValue: _char1Cooldown,
                        cooldownColor: Colors.blue,
                      ),
                    ],
                  ),
                  const Image(
                    width: 60.0,
                    fit: BoxFit.contain,
                    image: AssetImage('assets/images/battle/versus.png'),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      BattlePanel(
                        characterData: widget.char2,
                        statsData: _char2Stats!,
                        activatedOffenseIndex:
                            _char2Action?['activatedOffenseIndex'] ?? 0,
                        cooldownValue: _char2Cooldown,
                        cooldownColor: Colors.blue,
                      ),
                    ],
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
                          children: _messages
                              .map((line) => Text(
                                    line,
                                    style: const TextStyle(fontSize: 14.0),
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      if (_finished)
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
                            if (_finished) {
                              Navigator.pop(context, _data?['resultStats']);
                              engine.broadcast(const UIEvent.needRebuildUI());
                            } else {
                              _timer?.cancel();
                              setState(() {
                                _reset();
                                _finished = true;
                                _messages =
                                    List<String>.from(_data!['messages']);
                                _addDuelResult();
                                _char1Stats = _char1ResultStats;
                                _char2Stats = _char2ResultStats;
                              });
                            }
                          },
                          child: _finished
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
