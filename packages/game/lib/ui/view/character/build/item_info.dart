import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../../global.dart';
import '../../../shared/rrect_icon.dart';
// import '../../../shared/close_button.dart';

const _kItemInfoWidth = 390.0;

const kEquipTypeOffense = 'offense';

const kEntityCategoryWeapon = 'weapon';

class ItemInfo extends StatelessWidget {
  const ItemInfo({
    super.key,
    required this.itemData,
    this.left,
    // required this.onClose,
  });

  final HTStruct itemData;

  final double? left;

  // final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    double? actualLeft;
    if (left != null) {
      actualLeft = left;
      final contextSize = MediaQuery.of(context).size;
      if (contextSize.width - left! < _kItemInfoWidth) {
        final l = contextSize.width - _kItemInfoWidth;
        actualLeft = l > 0 ? l : 0;
      }
    }

    final category = itemData['category'];
    final equipType = itemData['equipType'];

    final attributes = itemData['attributes'];
    final stats = itemData['stats'];

    final effectData = itemData['stats']['effects'];
    final effects = <Widget>[];
    for (final name in effectData) {
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
      child: Stack(
        alignment: AlignmentDirectional.topEnd,
        children: [
          Positioned(
            left: actualLeft,
            top: 80.0,
            child: Container(
              // margin: const EdgeInsets.only(right: 240.0, top: 120.0),
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
                        Padding(
                          padding:
                              const EdgeInsets.only(right: 10.0, bottom: 10.0),
                          child: RRectIcon(
                            avatarAssetKey: 'assets/images/${itemData['icon']}',
                            size: const Size(80.0, 80.0),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                itemData['name'],
                              ),
                              const Divider(),
                              Text(
                                itemData['description'],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Text(
                        '${engine.locale[itemData['category']]} - ${engine.locale[itemData['kind']]}'),
                    if (category == kEntityCategoryWeapon)
                      Text(
                          '${engine.locale['durability']}: ${stats['life']}/${attributes['life']}'),
                    if (equipType == kEquipTypeOffense)
                      Text(
                          '${engine.locale['damage']}: ${stats['damage'].toStringAsFixed(2)}'),
                    if (equipType == kEquipTypeOffense)
                      Text('${engine.locale['speed']}: ${stats['speed']}f'),
                    if (effects.isNotEmpty) const Divider(),
                    ...effects,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
