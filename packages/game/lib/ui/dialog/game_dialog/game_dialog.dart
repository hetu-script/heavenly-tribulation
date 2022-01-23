import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'game_dialog_data.dart';
import '../../shared/avatar.dart';

class GameDialog extends StatefulWidget {
  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> jsonData,
  ) async {
    final dlgData = GameDialogData.fromJson(jsonData);
    return await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return GameDialog(data: dlgData);
      },
      barrierColor: Colors.transparent,
      barrierDismissible: false,
    );
  }

  final GameDialogData data;

  const GameDialog({
    Key? key,
    required this.data,
  }) : super(key: key);

  @override
  _GameDialogState createState() => _GameDialogState();
}

class _GameDialogState extends State<GameDialog> {
  GameDialogData get _data => widget.data;
  Timer? _timer;
  String? _currentAvatar;
  String _currentSay = '';
  int _currentContentIndex = 0;
  int _currentSayIndex = 0;
  int _letterCount = 0;
  bool _finished = false;

  final _textShowController = StreamController<String>.broadcast();

  @override
  void initState() {
    assert(_data.contents.isNotEmpty);
    assert(_data.contents.first.lines.isNotEmpty);
    _startTalk();
    super.initState();
  }

  @override
  void dispose() {
    _textShowController.close();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (_finished) {
          _nextSay();
        } else {
          _finishLine();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              const Spacer(),
              Container(
                height: 240,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: <Widget>[
                      Avatar(
                        avatarAssetKey: 'assets/images/$_currentAvatar',
                        size: 200.0,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 20.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: <Widget>[
                            StreamBuilder(
                              stream: _textShowController.stream,
                              builder:
                                  (context, AsyncSnapshot<String> snapshot) {
                                return SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  physics: const BouncingScrollPhysics(),
                                  child: Text(
                                    snapshot.data ?? '',
                                    style: const TextStyle(fontSize: 24),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startTalk() {
    setState(() {
      _finished = false;
      _letterCount = 0;
      final currentContent = _data.contents[_currentContentIndex];
      _currentAvatar = currentContent.avatar;
      _currentSay = currentContent.lines[_currentSayIndex];
      _timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
        _letterCount++;
        if (_letterCount > _currentSay.length) {
          _finishLine();
        } else {
          _textShowController.add(_currentSay.substring(0, _letterCount));
        }
      });
    });
  }

  void _nextSay() {
    ++_currentSayIndex;
    if (_currentSayIndex >= _data.contents[_currentContentIndex].lines.length) {
      _nextContent();
    } else {
      _startTalk();
    }
  }

  void _finishLine() {
    _timer?.cancel();
    _textShowController.add(_currentSay);
    _finished = true;
  }

  void _nextContent() {
    _currentSayIndex = 0;
    ++_currentContentIndex;
    if (_currentContentIndex < _data.contents.length) {
      _startTalk();
    } else {
      _currentContentIndex = 0;
      _finishDialog();
    }
  }

  void _finishDialog() {
    SchedulerBinding.instance!.addPostFrameCallback((_) {
      Navigator.pop(context);
    });
  }
}
