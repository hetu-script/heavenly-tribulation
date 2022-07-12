import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import '../../shared/responsive_window.dart';
import 'battle_cards.dart';
import '../../avatar.dart';
import '../../shared/dynamic_color_progressbar.dart';
import '../character/character.dart';
import '../character/npc.dart';
import '../../../event/events.dart';
import '../entity_info.dart';

const kEntityTypeCharacter = 'character';

class Duel extends StatefulWidget {
  static Future<bool?> show(
      {required BuildContext context,
      required HTStruct char1,
      required HTStruct char2,
      String? type,
      HTStruct? data}) {
    return showDialog<bool>(
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
  int _char1ActionIter = 0, _char2ActionIter = 0;
  int _char1Ticks = 0, _char2Ticks = 0;
  double _char1Cooldown = 0, _char2Cooldown = 0;
  HTStruct? _char1ActivatedOffenseItem, _char2ActivatedOffenseItem;
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
    _char1ActivatedOffenseItem = getNextChar1ActivatedItem();
    _char2ActivatedOffenseItem = getNextChar2ActivatedItem();
    _finished = false;
    _startTimer();
  }

  void _reset() {
    _char1ActionIter = 0;
    _char2ActionIter = 0;
    _char1Ticks = 0;
    _char2Ticks = 0;
    _char1Cooldown = 0;
    _char2Cooldown = 0;
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
    if (!(_data!['started'] ?? false)) return;
    _frames = 0;
    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (Timer timer) {
        setState(() {
          if (_frames > _data!['frames']) {
            timer.cancel();
            _finished = true;
          } else {
            if (_char1ActivatedOffenseItem != null) {
              final char1speed = _char1ActivatedOffenseItem!['speed'];
              if (_char1Ticks >= char1speed) {
                _char1Ticks = 0;
                _char1Cooldown = 0;
                _messages.add(_char1ActivatedOffenseItem!['message']);
                final newHP = _char2Stats!['life'] -
                    _char1ActivatedOffenseItem!['damage'];
                _char2Stats!['life'] = newHP >= 0 ? newHP : 0;
                _char1ActivatedOffenseItem = getNextChar1ActivatedItem();
              } else {
                ++_char1Ticks;
              }
              _char1Cooldown = char1speed > 0 ? _char1Ticks / char1speed : 1.0;
            }

            if (_char2ActivatedOffenseItem != null) {
              final char2speed = _char2ActivatedOffenseItem!['speed'];
              if (_char2Ticks >= char2speed) {
                _char2Ticks = 0;
                _char2Cooldown = 0;
                _messages.add(_char2ActivatedOffenseItem!['message']);
                final newHP = _char1Stats!['life'] -
                    _char2ActivatedOffenseItem!['damage'];
                _char1Stats!['life'] = newHP >= 0 ? newHP : 0;
                _char2ActivatedOffenseItem = getNextChar2ActivatedItem();
              } else {
                ++_char2Ticks;
              }
              _char2Cooldown = char2speed > 0 ? _char2Ticks / char2speed : 1.0;
            }
            ++_frames;
          }
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final char1EntityType = widget.char1['entityType'];
    final char2EntityType = widget.char2['entityType'];

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
          margin: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      Avatar(
                        name: widget.char1['name'],
                        avatarAssetKey: 'assets/images/${widget.char1['icon']}',
                        onPressed: () {
                          if (char1EntityType == kEntityTypeCharacter) {
                            showDialog(
                              context: context,
                              barrierColor: Colors.transparent,
                              builder: (context) {
                                return CharacterView(
                                    characterData: widget.char1);
                              },
                            );
                          } else if (char1EntityType == kEntityTypeNpc) {
                            showDialog(
                              context: context,
                              barrierColor: Colors.transparent,
                              builder: (context) {
                                return NpcView(npcData: widget.char1);
                              },
                            );
                          }
                        },
                      ),
                      DynamicColorProgressBar(
                        width: 175.0,
                        height: 20.0,
                        value: _char1Stats!['life'],
                        max: _char1Stats!['lifeMax'],
                        showNumberAsPercentage: false,
                        colors: const <Color>[Colors.red, Colors.green],
                      ),
                      BattleCards(
                        characterData: widget.char1,
                        activatedIndex:
                            _char1ActivatedOffenseItem?['activatedIndex'] ?? 0,
                        cooldownValue: _char1Cooldown,
                        cooldownColor: Colors.blue,
                      ),
                    ],
                  ),
                  const Image(
                    width: 80.0,
                    fit: BoxFit.contain,
                    image: AssetImage('assets/images/battle/versus.png'),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Avatar(
                        name: widget.char2['name'],
                        avatarAssetKey: 'assets/images/${widget.char2['icon']}',
                        onPressed: () {
                          if (char2EntityType == kEntityTypeCharacter) {
                            showDialog(
                              context: context,
                              barrierColor: Colors.transparent,
                              builder: (context) {
                                return CharacterView(
                                    characterData: widget.char2);
                              },
                            );
                          } else if (char2EntityType == kEntityTypeNpc) {
                            showDialog(
                              context: context,
                              barrierColor: Colors.transparent,
                              builder: (context) {
                                return NpcView(npcData: widget.char2);
                              },
                            );
                          }
                        },
                      ),
                      DynamicColorProgressBar(
                        width: 175.0,
                        height: 20.0,
                        value: _char2Stats!['life'],
                        max: _char2Stats!['lifeMax'],
                        showNumberAsPercentage: false,
                        colors: const <Color>[Colors.red, Colors.green],
                      ),
                      BattleCards(
                        characterData: widget.char2,
                        activatedIndex:
                            _char2ActivatedOffenseItem?['activatedIndex'] ?? 0,
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
                          children:
                              _messages.map((line) => Text(line)).toList(),
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
                              Navigator.pop(context, _data?['result'] ?? false);
                              engine.broadcast(const UIEvent.needRebuildUI());
                            } else {
                              _timer?.cancel();
                              setState(() {
                                _reset();
                                _finished = true;
                                _messages =
                                    List<String>.from(_data!['messages']);
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
