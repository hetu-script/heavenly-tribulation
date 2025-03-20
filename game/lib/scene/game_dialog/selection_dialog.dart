import 'package:flutter/material.dart';
import 'package:samsara/richtext.dart';
import 'package:provider/provider.dart';

import '../../game/ui.dart';
import '../../state/game_dialog.dart';

class SelectionDialog extends StatefulWidget {
  /// 调用这个方法不会触发 GameDialogState 的改变
  ///
  /// selection data 数据格式：
  /// ```
  /// {
  ///   selections: {
  ///     selectKey1: 'localedText1',
  ///     selectKey2: 'localedText3',
  ///   }
  /// }
  /// ```
  static Future<String?> show(
    BuildContext context, {
    required dynamic selectionsData,
  }) async {
    return await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
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
  dynamic selectionsData;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.from(selectionsData['selections'].keys.map(
                (key) {
                  final text = selectionsData['selections'][key];
                  assert(text is String);
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    width: 300,
                    child: ElevatedButton(
                      onPressed: () {
                        if (selectionsData['taskId'] == null) {
                          Navigator.pop(context, key);
                        } else {
                          assert(selectionsData['id'] != null);
                          context.read<GameDialogState>().finishSelection(
                                selectionsData['taskId'],
                                selectionsData['id'],
                                value: key,
                              );
                        }
                      },
                      child: RichText(
                        text: TextSpan(
                          children: buildFlutterRichText(text),
                          style: TextStyle(
                            fontSize: 24,
                            fontFamily: GameUI.fontFamily,
                          ),
                        ),
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
