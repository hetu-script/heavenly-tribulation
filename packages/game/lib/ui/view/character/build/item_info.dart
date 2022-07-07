import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/util.dart';

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
    this.actions = const [],
  });

  final HTStruct itemData;

  final double? left;

  final List<Widget> actions;

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

    final titleColor = HexColor.fromHex(itemData['color']);

    final stackSize = itemData['stackSize'] ?? 1;

    final category = itemData['category'];
    final equipType = itemData['equipType'];

    final attributes = itemData['attributes'];
    final stats = itemData['stats'];

    final effectData = itemData['effects'] ?? [];
    final effects = <Widget>[];
    for (final data in effectData) {
      final String? name = data['name'];
      final values = <String>[];
      for (final value in data['values']) {
        final v = value['value'] as num;
        final type = value['type'];
        if (type == null || type == kValueTypeInt) {
          values.add(v.toString());
        } else if (type == kValueTypeFloat) {
          values.add(v.toStringAsFixed(2));
        } else if (type == kValueTypePercentage) {
          values.add(v.toPercentageString(2));
        }
      }
      final description = engine.locale.getString(data['description'], values);
      effects.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                                style: TextStyle(color: titleColor),
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                            '${engine.locale[category]} - ${engine.locale[itemData['kind']]}'),
                        Text(engine.locale[itemData['rarity']]),
                      ],
                    ),
                    if (stackSize > 1)
                      Text('${engine.locale['stackSize']}: $stackSize'),
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
                    if (actions.isNotEmpty) const Divider(),
                    if (actions.isNotEmpty)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: actions,
                      ),
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
