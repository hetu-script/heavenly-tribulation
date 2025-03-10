import 'package:flutter/material.dart';
import 'package:samsara/richtext.dart';
import 'package:provider/provider.dart';

import '../../ui.dart';
import '../../state/game_dialog.dart';

class SelectionDialog extends StatefulWidget {
  static Future<String?> show({
    required BuildContext context,
    required dynamic selectionsData,
  }) async {
    return await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return SelectionDialog(selectionsData: selectionsData);
      },
    );
  }

  final dynamic selectionsData;

  const SelectionDialog({
    super.key,
    this.selectionsData,
  });

  @override
  State<SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<SelectionDialog> {
  dynamic selectionsData;

  @override
  Widget build(BuildContext context) {
    selectionsData = widget.selectionsData ??
        context.watch<GameDialogState>().selectionsData;

    return selectionsData == null
        ? Container()
        : Material(
            color: Colors.transparent,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children:
                        List<Widget>.from(selectionsData['selections'].keys.map(
                      (key) {
                        final text = selectionsData['selections'][key];
                        assert(text is String);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
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
