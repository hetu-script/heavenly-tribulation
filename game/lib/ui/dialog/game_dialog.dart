import 'dart:async';

import 'package:flutter/material.dart';
// import 'package:flutter/scheduler.dart';
// import 'package:hetu_script/values.dart';

import '../avatar.dart';
import '../../config.dart';
import '../../event/ui.dart';
import '../view/character/information/character.dart';
import '../view/character/npc.dart';

// dialogData: {
//   "contents": [
//     {
//       "lines": [
//         engine.locale[
//             'deckbuilding.requiredCardsPrompt']
//       ],
//     },
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return GameDialog(dialogData: dialogData, returnValue: returnValue);
      },
    );
  }

  final dynamic dialogData;

  final dynamic returnValue;

  const GameDialog({
    super.key,
    required this.dialogData,
    this.returnValue,
  });

  @override
  State<GameDialog> createState() => _GameDialogState();
}

class _GameDialogState extends State<GameDialog> {
  Timer? timer;
  String? currentAvatar;
  String currentSay = '';
  String? displayName;
  int currentContentIndex = 0;
  dynamic currentContent;
  int currentSayIndex = 0;
  int letterCount = 0;
  bool finished = false;

  dynamic characterData;
  bool isNpc = false;

  final textShowController = StreamController<String>.broadcast();

  @override
  void initState() {
    startTalk();
    super.initState();
  }

  @override
  void dispose() {
    textShowController.close();
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BoxDecoration? backgroundImage;
    if (currentContent != null) {
      final cg = currentContent!['background'];
      if (cg != null) {
        backgroundImage = BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/${cg!}'),
            fit: BoxFit.cover,
          ),
        );
      }
    }

    final screenSize = View.of(context).physicalSize;

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
            Container(
              width: screenSize.width,
              height: screenSize.height,
              decoration: backgroundImage,
            ),
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
                        Avatar(
                          name: displayName,
                          preferNameOnTop: true,
                          image: currentAvatar != null
                              ? AssetImage(
                                  'assets/images/avatar/$currentAvatar')
                              : null,
                          size: const Size(140.0, 140.0),
                          onPressed: () {
                            if (characterData != null) {
                              if (isNpc) {
                                showDialog(
                                  context: context,
                                  barrierColor: Colors.transparent,
                                  builder: (context) {
                                    return NpcView(npcData: characterData!);
                                  },
                                );
                              } else {
                                showDialog(
                                  context: context,
                                  barrierColor: Colors.transparent,
                                  builder: (context) {
                                    return CharacterView(
                                        characterData: characterData);
                                  },
                                );
                              }

                              showDialog(
                                context: context,
                                barrierColor: Colors.transparent,
                                builder: (context) {
                                  return CharacterView(
                                      characterData: characterData);
                                },
                              );
                            }
                          },
                        ),
                        Container(
                          // color: Colors.blue,
                          width: 720,
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                snapshot.data ?? '',
                                style: const TextStyle(fontSize: 18),
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
      currentContent = widget.dialogData['contents'][currentContentIndex];

      final characterId = currentContent!['characterId'];
      if (characterId != null) {
        if (widget.dialogData['isMajorCharacter'] ?? false) {
          characterData = engine.hetu
              .invoke('getCharacterById', positionalArgs: [characterId]);
          isNpc = false;
        } else {
          characterData =
              engine.hetu.invoke('getNpcById', positionalArgs: [characterId]);
          isNpc = true;
        }
      }

      currentAvatar = currentContent!['icon'];
      currentSay = currentContent!['lines'][currentSayIndex];
      displayName = currentContent!['displayName'];
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
    if (currentSayIndex >= currentContent!['lines'].length) {
      nextContent();
    } else {
      startTalk();
    }
  }

  void finishLine() {
    timer?.cancel();
    textShowController.add(currentSay);
    finished = true;
  }

  void nextContent() {
    currentSayIndex = 0;
    ++currentContentIndex;
    if (currentContentIndex < widget.dialogData['contents'].length) {
      startTalk();
    } else {
      currentContentIndex = 0;
      finishDialog();
    }
  }

  void finishDialog() {
    // SchedulerBinding.instance.addPostFrameCallback((_) {
    Navigator.pop(context, widget.returnValue);
    engine.emit(const UIEvent.needRebuildUI());
    // });
  }
}
