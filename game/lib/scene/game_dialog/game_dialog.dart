import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
// import 'package:hetu_script/values.dart';
import 'package:samsara/richtext.dart';

import '../../widgets/avatar.dart';
import '../../engine.dart';
import '../../widgets/character/profile.dart';
// import '../../event/ui.dart';
import '../../ui.dart';

class GameDialog extends StatefulWidget {
  static bool isGameDialogOpened = false;

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
  String currentLine = '';
  List<String> nodes = [];
  String? displayName;
  int currentSayIndex = 0;
  int progress = 0;
  bool finished = false;

  dynamic characterData;
  bool isNpc = false;

  final textShowController = StreamController<TextSpan>.broadcast();

  late TextStyle style;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      startTalk();
    });
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
                builder: (context, AsyncSnapshot<TextSpan> snapshot) {
                  return Container(
                    width: 880,
                    height: 190,
                    padding: const EdgeInsets.only(top: 10.0),
                    decoration: BoxDecoration(
                      color: GameUI.backgroundColor,
                      borderRadius: GameUI.borderRadius,
                      border: Border.all(color: GameUI.foregroundColor),
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
                                    'assets/images/illustration/$currentAvatar')
                                : null,
                            size: const Size(140.0, 140.0),
                            characterData: characterData,
                            onPressed: (id) {
                              if (id != null) {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      CharacterProfilePanel(characterId: id),
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
                              RichText(
                                text: snapshot.data ?? const TextSpan(),
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
    GameDialog.isGameDialogOpened = true;
    finished = false;
    progress = 0;

    final characterId = widget.dialogData['characterId'];
    if (characterId != null) {
      characterData =
          engine.hetu.invoke('getCharacterById', positionalArgs: [characterId]);
    } else {
      characterData = widget.dialogData['characterData'];
    }

    currentAvatar = widget.dialogData['icon'];
    currentLine = widget.dialogData['lines'][currentSayIndex];

    nodes = getRichTextStream(currentLine);

    displayName = widget.dialogData['displayName'];

    style = DefaultTextStyle.of(context).style.merge(TextStyle(
          fontSize: 20,
          letterSpacing: 2,
          fontWeight: FontWeight.normal,
          color: (displayName != null || characterId != null)
              ? Colors.lightGreen
              : Colors.white70,
          fontFamily: GameUI.fontFamily,
          decoration: TextDecoration.none,
        ));

    timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        progress++;
        if (progress >= nodes.length) {
          finishLine();
        } else {
          textShowController.add(
            TextSpan(
              children: buildFlutterRichText(
                nodes.sublist(0, progress).join(),
                style: style,
              ),
            ),
          );
        }
      },
    );
    setState(() {});
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
    textShowController.add(
        TextSpan(children: buildFlutterRichText(currentLine, style: style)));
    finished = true;
  }

  void finishDialog() {
    GameDialog.isGameDialogOpened = false;
    // SchedulerBinding.instance.addPostFrameCallback((_) {
    Navigator.pop(context, widget.returnValue);
  }
}
