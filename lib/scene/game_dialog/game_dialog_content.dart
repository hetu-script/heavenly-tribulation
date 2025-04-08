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
  static Future<void> show(BuildContext context, dynamic dialogData,
      {TextStyle? style}) {
    final resolved = dialogData is String
        ? {
            'lines': dialogData.split('\n'),
          }
        : (dialogData is List ? {'lines': dialogData} : dialogData);
    assert(resolved is Map || resolved is HTStruct);
    assert(resolved['id'] == null);
    return showDialog<dynamic>(
      context: context,
      barrierColor: GameUI.backgroundColor,
      builder: (BuildContext context) {
        return GameDialogContent(
          data: resolved,
          style: style,
        );
      },
    );
  }

  final dynamic data;
  final TextStyle? style;

  const GameDialogContent({
    super.key,
    required this.data,
    this.style,
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

    style = TextStyle(
      fontSize: 20,
      letterSpacing: 2,
      fontWeight: FontWeight.normal,
      color: Colors.white,
      fontFamily: GameUI.fontFamily,
      decoration: TextDecoration.none,
    ).merge(widget.style ?? TextStyle());

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
                      color: GameUI.backgroundColor2,
                      // borderRadius: GameUI.borderRadius,
                      // border: Border.all(color: GameUI.foregroundColor),
                    ),
                    child: Row(
                      children: [
                        Avatar(
                          margin: const EdgeInsets.only(left: 20.0),
                          // cursor: SystemMouseCursors.click,
                          // displayName: displayName,
                          // nameAlignment: AvatarNameAlignment.top,
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
                        Container(
                          width: 640,
                          height: 190,
                          padding: const EdgeInsets.only(left: 20.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 10.0),
                                child: Label(
                                  displayName ?? '',
                                  textStyle: TextStyle(fontSize: 20),
                                  textAlign: TextAlign.left,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: RichText(
                                  text: snapshot.data ?? const TextSpan(),
                                ),
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

    timer = Timer.periodic(
      const Duration(milliseconds: 100),
      (timer) {
        progress++;
        if (progress >= nodes.length) {
          finishLine();
        } else {
          if (!textShowController.isClosed) {
            textShowController.add(
              TextSpan(
                children: buildFlutterRichText(
                  nodes.sublist(0, progress).join(),
                  style: style,
                ),
              ),
            );
          } else {
            timer.cancel();
            return;
          }
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
    if (!textShowController.isClosed) {
      textShowController.add(
          TextSpan(children: buildFlutterRichText(currentLine, style: style)));
    }
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
