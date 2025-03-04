import 'package:flutter/material.dart';
// import 'package:samsara/extensions.dart';
import 'package:samsara/richtext.dart';

// import '../../event/ui.dart';

import '../../ui.dart';

class SelectionDialog extends StatelessWidget {
  static Future<String?> show({
    required BuildContext context,
    required dynamic selectionsData,
  }) async {
    assert(selectionsData.isNotEmpty);
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
    required this.selectionsData,
  });

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
              children: List<Widget>.from(selectionsData.keys.map(
                (key) {
                  final text = selectionsData[key]['text'];
                  assert(text is String);
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, key);
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
