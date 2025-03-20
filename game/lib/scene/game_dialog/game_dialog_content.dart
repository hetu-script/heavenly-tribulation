import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/richtext.dart';
import 'package:provider/provider.dart';

import '../../widgets/avatar.dart';
// import '../../engine.dart';
import '../../widgets/character/profile.dart';
// import '../../event/ui.dart';
import '../../game/ui.dart';
import '../../state/game_dialog.dart';

class GameDialogContent extends StatefulWidget {
  /// 调用这个方法不会触发 GameDialogState 的改变
  ///
  /// dialog data 数据格式
  /// ```
  /// {
  ///   "lines": ["line1", "line2"],
  ///   "displayName": "displayName",
  ///   "icon": "icon.png",
  /// }
  /// ```
  static Future<void> show(BuildContext context, dynamic dialogData) {
    final resolved = dialogData is String
        ? {
            'lines': [dialogData]
          }
        : (dialogData is List ? {'lines': dialogData} : dialogData);
    assert(resolved is Map || resolved is HTStruct);
    assert(resolved['id'] == null);
    return showDialog<dynamic>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return GameDialogContent(data: resolved);
      },
    );
  }

  final dynamic data;

  const GameDialogContent({
    super.key,
    required this.data,
  }) : assert(data != null);

  @override
  State<GameDialogContent> createState() => _GameDialogContentState();
}

class _GameDialogContentState extends State<GameDialogContent> {
  Timer? timer;
  String? currentAvatar;
  String currentLine = '';
  List<String> nodes = [];
  String? displayName;
  int currentSayIndex = 0;
  int progress = 0;
  bool lineFinished = false;

  // dynamic characterData;

  final textShowController = StreamController<TextSpan>.broadcast();

  late TextStyle style;

  @override
  void initState() {
    super.initState();

    SchedulerBinding.instance.addPostFrameCallback((_) {
      startLine();
    });
  }

  @override
  void didUpdateWidget(covariant GameDialogContent oldWidget) {
    super.didUpdateWidget(oldWidget);

    SchedulerBinding.instance.addPostFrameCallback((_) {
      startLine();
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
        if (lineFinished) {
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
                            cursor: SystemMouseCursors.click,
                            displayName: displayName,
                            nameAlignment: AvatarNameAlignment.top,
                            image: currentAvatar != null
                                ? AssetImage('assets/images/$currentAvatar')
                                : null,
                            size: const Size(140.0, 140.0),
                            // characterData: characterData,
                            onPressed: (id) {
                              if (id != null) {
                                showDialog(
                                  context: context,
                                  builder: (context) =>
                                      CharacterProfileView(characterId: id),
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

  void startLine() {
    lineFinished = false;
    progress = 0;

    currentAvatar = widget.data['icon'];
    displayName = widget.data['displayName'];
    currentLine = widget.data['lines'][currentSayIndex];
    nodes = getRichTextStream(currentLine);

    style = DefaultTextStyle.of(context).style.merge(TextStyle(
          fontSize: 20,
          letterSpacing: 2,
          fontWeight: FontWeight.normal,
          color: Colors.white,
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
  }

  void nextSay() {
    ++currentSayIndex;
    if (currentSayIndex >= (widget.data?['lines']?.length ?? 0)) {
      finishDialog();
    } else {
      startLine();
    }
  }

  void finishLine() {
    timer?.cancel();
    textShowController.add(
        TextSpan(children: buildFlutterRichText(currentLine, style: style)));
    lineFinished = true;
  }

  void finishDialog() {
    // GameDialog.isGameDialogOpened = false;
    currentSayIndex = 0;
    final id = widget.data?['id'];
    if (id != null) {
      context.read<GameDialogState>().finishDialog(id);
    } else {
      Navigator.of(context).pop();
    }
  }
}
