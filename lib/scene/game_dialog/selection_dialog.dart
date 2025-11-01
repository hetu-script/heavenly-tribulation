import 'package:flutter/material.dart';
import 'package:samsara/richtext.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../ui.dart';
import '../../state/game_dialog.dart';
import '../../global.dart';
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
      barrierColor: GameUI.barrierColor,
      builder: (BuildContext context) {
        return SelectionDialog(
          data: selectionsData,
          withBarrier: true,
        );
      },
    );
  }

  const SelectionDialog({
    super.key,
    required this.data,
    this.withBarrier = true,
  }) : assert(data != null);

  final dynamic data;
  final bool withBarrier;

  @override
  State<SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<SelectionDialog> {
  void _onSelection([String? key]) {
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
  }

  @override
  Widget build(BuildContext context) {
    final errorMsg = engine.locale('invalidSelectionData');
    final selectionData = widget.data?['selections'] ?? {'error': errorMsg};

    return MouseRegion(
      cursor: GameUI.cursor,
      hitTestBehavior: HitTestBehavior.translucent,
      child: Material(
        color: Colors.transparent,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (widget.withBarrier)
              ModalBarrier(
                color: GameUI.barrierColor,
                onDismiss: _onSelection,
              ),
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
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      width: 300,
                      child: fluent.Button(
                        style: FluentButtonStyles.slim,
                        onPressed: () {
                          context.read<HoverContentState>().hide();
                          _onSelection(key);
                        },
                        child: Label(
                          text,
                          textStyle: GameUI.textTheme.bodyLarge,
                          width: 300,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16.0, vertical: 8.0),
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
      ),
    );
  }
}
