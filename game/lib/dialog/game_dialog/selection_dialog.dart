import 'package:flutter/material.dart';
import 'package:samsara/extensions.dart';

// import '../../event/ui.dart';

/// selectionData

class SelectionDialog extends StatelessWidget {
  static Future<String> show({
    required BuildContext context,
    required dynamic selectionsData,
  }) async {
    assert(selectionsData.isNotEmpty);
    return await showDialog<String>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (BuildContext context) {
        return SelectionDialog(selectionsData: selectionsData);
      },
      barrierDismissible: false,
    ) as String;
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
              children: selectionsData.keys.map(
                (key) {
                  final data = selectionsData[key];
                  final String? colorString = selectionsData[key]['color'];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context, key);
                      },
                      child: Text(
                        data['text'].toString(),
                        style: TextStyle(
                          fontSize: 24,
                          color: colorString != null
                              ? HexColor.fromString(colorString)
                              : null,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
