import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:hetu_script/values.dart';

import '../../view/avatar.dart';
import '../../config.dart';
import '../../view/character/profile.dart';
// import '../../event/ui.dart';

// dialogData: {
//   "lines": [
//      engine.locale(
//       'deckbuilding.requiredCardsPrompt']
//   ],
// },

class GameDialog extends StatefulWidget {
  static Future<void> show({
    required BuildContext context,
    required dynamic dialogData,
    dynamic returnValue,
  }) {
    return showDialog<dynamic>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return GameDialog(dialogData: dialogData, returnValue: returnValue);
      },
    );
  }

  final dynamic dialogData;

  final dynamic returnValue;

  final bool showProfileOnTap;

  const GameDialog({
    super.key,
    required this.dialogData,
    this.returnValue,
    this.showProfileOnTap = true,
  });

  @override
  State<GameDialog> createState() => _GameDialogState();
}

class _GameDialogState extends State<GameDialog> {
  Timer? timer;
  String? currentAvatar;
  String currentSay = '';
  String? displayName;
  int currentSayIndex = 0;
  int letterCount = 0;
  bool finished = false;

  dynamic characterData;
  bool isNpc = false;

  final textShowController = StreamController<String>.broadcast();

  @override
  void initState() {
    super.initState();

    startTalk();
  }

  @override
  void dispose() {
    super.dispose();
    textShowController.close();
    timer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (finished) {
          nextSay();
        } else {
          finishLine();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: AlignmentDirectional.bottomCenter,
          children: [
            Positioned(
              bottom: 20.0,
              child: StreamBuilder(
                stream: textShowController.stream,
                builder: (context, AsyncSnapshot<String> snapshot) {
                  return Container(
                    width: 880,
                    height: 160,
                    padding: const EdgeInsets.only(top: 10.0),
                    decoration: BoxDecoration(
                      color: kBackgroundColor,
                      borderRadius: kBorderRadius,
                      border: Border.all(color: kForegroundColor),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 10.0),
                          child: Avatar(
                            displayName: displayName,
                            nameAlignment: AvatarNameAlignment.top,
                            image: currentAvatar != null
                                ? AssetImage(
                                    'assets/images/avatar/$currentAvatar')
                                : null,
                            size: const Size(140.0, 140.0),
                            characterData: characterData,
                            onPressed: (id) {
                              if (id != null) {
                                showDialog(
                                  context: context,
                                  builder: (context) => ProfileView(
                                    characterId: id,
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        Container(
                          // color: Colors.blue,
                          width: 640,
                          padding: const EdgeInsets.only(left: 20.0, top: 15.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snapshot.data ?? '',
                                style: const TextStyle(fontSize: 24),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void startTalk() {
    setState(() {
      finished = false;
      letterCount = 0;

      final characterId = widget.dialogData['characterId'];
      if (characterId != null) {
        characterData = engine.hetu
            .invoke('getCharacterById', positionalArgs: [characterId]);
      }

      currentAvatar = widget.dialogData['icon'];
      currentSay = widget.dialogData['lines'][currentSayIndex];
      displayName = widget.dialogData['displayName'];
      // if (displayName != null) {
      //   _currentSay = '$displayName: $_currentSay';
      // }
      timer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
        letterCount++;
        if (letterCount > currentSay.length) {
          finishLine();
        } else {
          textShowController.add(currentSay.substring(0, letterCount));
        }
      });
    });
  }

  void nextSay() {
    ++currentSayIndex;
    if (currentSayIndex >= widget.dialogData['lines'].length) {
      finishDialog();
    } else {
      startTalk();
    }
  }

  void finishLine() {
    timer?.cancel();
    textShowController.add(currentSay);
    finished = true;
  }

  void finishDialog() {
    // SchedulerBinding.instance.addPostFrameCallback((_) {
    Navigator.pop(context, widget.returnValue);
  }
}
