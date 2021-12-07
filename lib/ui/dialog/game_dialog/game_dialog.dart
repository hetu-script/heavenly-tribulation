import 'dart:async';

import 'package:flutter/material.dart';

import 'game_dialog_data.dart';

class GameDialog extends StatefulWidget {
  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> data,
  ) async {
    final dlgData = GameDialogData.fromJson(data);
    return await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return GameDialog(data: dlgData);
      },
      barrierDismissible: false,
    );
  }

  final GameDialogData data;

  // final Function? onFinished;

  const GameDialog({
    Key? key,
    required this.data,
    // this.onFinished,
  }) : super(key: key);

  @override
  _GameDialogState createState() => _GameDialogState();
}

class _GameDialogState extends State<GameDialog> {
  GameDialogData get _data => widget.data;
  Timer? _timer;
  String _currentSay = '';
  int _currentContentIndex = 0;
  int _currentSayIndex = 0;
  int _letterCount = 0;
  bool _finished = false;

  final _textShowController = StreamController<String>.broadcast();

  @override
  void initState() {
    assert(_data.contents.isNotEmpty);
    assert(_data.contents.first.saying.isNotEmpty);
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
      child: Container(
        color: Colors.transparent,
        height: MediaQuery.of(context).size.height,
        width: MediaQuery.of(context).size.width,
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Expanded(
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: Colors.white.withOpacity(0.5)),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: StreamBuilder(
                      stream: _textShowController.stream,
                      builder: (context, AsyncSnapshot<String> snapshot) {
                        return SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          physics: const BouncingScrollPhysics(),
                          child: Text(
                            snapshot.hasData ? snapshot.data.toString() : '',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startTalk() {
    setState(() {
      _finished = false;
      _letterCount = 0;
      _currentSay =
          _data.contents[_currentContentIndex].saying[_currentSayIndex];
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

  String? _nextSay() {
    ++_currentSayIndex;
    if (_currentSayIndex >=
        _data.contents[_currentContentIndex].saying.length) {
      _nextContent();
    } else {
      _startTalk();
    }
  }

  void _finishLine() {
    _timer?.cancel();
    _textShowController.add(_currentSay);
    // _letterCount = 0;
    _finished = true;
  }

  void _nextContent() {
    _currentSayIndex = 0;
    ++_currentContentIndex;
    if (_currentContentIndex < _data.contents.length) {
      _startTalk();
    } else {
      _finishDialog();
    }
  }

  void _finishDialog() {
    // if (widget.onFinished != null) {
    //   widget.onFinished!();
    // }
    Navigator.pop(context);
  }
}
