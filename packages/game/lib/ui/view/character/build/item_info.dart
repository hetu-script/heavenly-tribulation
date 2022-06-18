import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../../global.dart';
import '../../../shared/rrect_icon.dart';
// import '../../../shared/close_button.dart';

class ItemInfo extends StatelessWidget {
  const ItemInfo({
    Key? key,
    required this.data,
    this.left,
    this.top,
    // required this.onClose,
  }) : super(key: key);

  final HTStruct data;

  final double? left, top;

  // final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final stats = data['stats'];

    return GestureDetector(
      onTap: () {
        Navigator.of(context).pop();
      },
      child: Stack(alignment: AlignmentDirectional.topEnd, children: [
        // Positioned(
        //   left: left,
        //   top: top,
        //   child:
        Container(
          margin: const EdgeInsets.only(right: 240.0, top: 120.0),
          padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 15.0),
          width: 240.0,
          decoration: BoxDecoration(
            color: kBackgroundColor,
            borderRadius: kBorderRadius,
            border: Border.all(color: kForegroundColor),
          ),
          child: ClipRRect(
            borderRadius: kBorderRadius,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data['name'],
                ),
                RRectIcon(
                  margin: const EdgeInsets.all(10.0),
                  avatarAssetKey: 'assets/images/' + data['icon'],
                ),
                Text('${engine.locale['speed']}: ${stats['speed']}'),
                Text(
                    '${engine.locale['damage']}: ${stats['damage'].toStringAsFixed(2)}'),
                Text(
                    '${engine.locale['damageType']}: ${engine.locale[stats['damageType']]}'),
              ],
            ),
          ),
        ),
        // ),
      ]),
    );
  }
}
