import 'package:flutter/material.dart';
import 'package:samsara/richtext.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../game/ui.dart';
import '../../state/game_dialog.dart';
import '../../engine.dart';
import '../../state/hover_content.dart';

class SelectionDialog extends StatefulWidget {
  /// selection data 数据格式：
  /// ```
  /// {
  ///   selections: {
  ///     // 可以只有一个单独的文本
  ///     selectKey1: 'localedText1',
  ///     // 也可以是文本加一个描述文本
  ///     selectKey2: { text: 'localedText3', description: 'localedText4' },
  ///   }
  /// }
  static Future<String?> show(
    BuildContext context, {
    required dynamic selectionsData,
  }) async {
    return await showDialog<String>(
      context: context,
      barrierColor: GameUI.backgroundColor,
      builder: (BuildContext context) {
        return SelectionDialog(data: selectionsData);
      },
    );
  }

  final dynamic data;

  const SelectionDialog({
    super.key,
    required this.data,
  }) : assert(data != null);

  @override
  State<SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<SelectionDialog> {
  @override
  Widget build(BuildContext context) {
    final errorMsg = engine.locale('invalidSelectionData');
    final selectionData = widget.data?['selections'] ?? {'error': errorMsg};

    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.from(selectionData.keys.map(
                (key) {
                  String text;
                  if (selectionData[key] == null) {
                    text = errorMsg;
                  } else if (selectionData[key] is String) {
                    text = selectionData[key];
                  } else {
                    text = selectionData[key]['text'] ?? errorMsg;
                  }
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    width: 300,
                    child: fluent.FilledButton(
                      onPressed: () {
                        context.read<HoverContentState>().hide();
                        if (widget.data['taskId'] == null) {
                          Navigator.pop(context, key);
                        } else {
                          assert(widget.data['id'] != null);
                          context.read<GameDialog>().finishSelection(
                                widget.data['taskId'],
                                widget.data['id'],
                                value: key,
                              );
                        }
                      },
                      child: Label(
                        text,
                        textStyle: GameUI.textTheme.bodyLarge,
                        width: 300,
                        onMouseEnter: (rect) {
                          if (selectionData[key] != null &&
                              selectionData[key] is! String) {
                            final description =
                                selectionData[key]['description'];
                            context.read<HoverContentState>().show(
                                  description,
                                  rect,
                                  direction: HoverContentDirection.topCenter,
                                );
                          }
                        },
                        onMouseExit: () {
                          context.read<HoverContentState>().hide();
                        },
                      ),
                    ),
                  );
                },
              )),
            ),
          ),
        ],
      ),
    );
  }
}
