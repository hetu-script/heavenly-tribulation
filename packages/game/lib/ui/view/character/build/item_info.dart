import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../../global.dart';
import '../../../shared/rrect_icon.dart';
// import '../../../shared/close_button.dart';

class ItemInfo extends StatelessWidget {
  const ItemInfo({
    super.key,
    required this.data,
    this.left,
    this.top,
    // required this.onClose,
  });

  final HTStruct data;

  final double? left, top;

  // final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isAttackItem = data['isAttackItem'] ?? false;

    final attributes = data['attributes'];
    final stats = data['stats'];

    final effectData = data['stats']['effects'];
    final effects = <Widget>[];
    for (final name in effectData.keys) {
      final List valueData = effectData[name];
      final List<String> values = [];
      for (final data in valueData) {
        final v = data['value'] as num;
        if (data['type'] == kValueTypeInt) {
          values.add(v.toString());
        } else if (data['type'] == kValueTypeFloat) {
          values.add(v.toStringAsFixed(2));
        } else if (data['type'] == kValueTypePercentage) {
          values.add(v.toPercentageString());
        }
      }
      final description = engine.locale.getString('${name}Description', values);
      effects.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.only(top: 4.0),
                width: 60.0,
                child: Text('${engine.locale[name]}: '),
              ),
              Container(
                padding: const EdgeInsets.only(top: 4.0),
                width: 200.0,
                child: Text(description),
              ),
            ],
          ),
        ),
      );
    }

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
          padding: const EdgeInsets.all(10.0),
          width: 300.0,
          decoration: BoxDecoration(
            color: kBackgroundColor,
            borderRadius: kBorderRadius,
            border: Border.all(color: kForegroundColor),
          ),
          child: ClipRRect(
            borderRadius: kBorderRadius,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RRectIcon(
                      margin: const EdgeInsets.only(right: 10.0, bottom: 10.0),
                      avatarAssetKey: 'assets/images/${data['icon']}',
                      size: const Size(80.0, 80.0),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['name'],
                          ),
                          const Divider(),
                          Text(
                            data['description'],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                Text(
                    '${engine.locale[data['category']]} - ${engine.locale[data['type']]}'),
                Text(
                    '${engine.locale['durability']}: ${stats['durability']}/${attributes['durability']}'),
                if (isAttackItem)
                  Text(
                      '${engine.locale['damage']}: ${stats['damage'].toStringAsFixed(2)}'),
                Text('${engine.locale['startUp']}: ${stats['startUp']}f'),
                Text('${engine.locale['recovery']}: ${stats['recovery']}f'),
                if (effects.isNotEmpty) const Divider(),
                ...effects,
              ],
            ),
          ),
        ),
        // ),
      ]),
    );
  }
}
