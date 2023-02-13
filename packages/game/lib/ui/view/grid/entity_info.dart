import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/util.dart';

import '../../../global.dart';
// import '../../shared/rrect_icon.dart';
// import '../../../shared/close_button.dart';
import '../../common.dart';

const _kInfoPanelWidth = 300.0;

class EntityInfo extends StatelessWidget {
  const EntityInfo({
    super.key,
    required this.entityData,
    this.left,
    this.actions = const [],
    this.priceFactor = 1.0,
    this.showPrice = false,
  });

  final HTStruct entityData;
  final double? left;
  final List<Widget> actions;
  final double priceFactor;
  final bool showPrice;

  @override
  Widget build(BuildContext context) {
    double? actualLeft;
    if (left != null) {
      actualLeft = left;
      final contextSize = MediaQuery.of(context).size;
      if (contextSize.width - left! < _kInfoPanelWidth) {
        final l = contextSize.width - _kInfoPanelWidth;
        actualLeft = l > 0 ? l : 0;
      }
    }

    final titleColor = HexColor.fromHex(entityData['color']);

    final stackSize = entityData['stackSize'] ?? 1;

    // final entityType = entityData['entityType'];
    final category = entityData['category'];
    final equipType = entityData['equipType'];

    // String? levelString;
    // String? expString;
    // if (entityType == kEntityTypeSkill) {
    //   final int level = entityData['level'];
    //   final int levelMax = entityData['levelMax'];
    //   final int exp = entityData['exp'];
    //   final int expForNextLevel = entityData['expForNextLevel'];
    //   levelString = '${level + 1}/${levelMax + 1}';
    //   expString = '$exp/$expForNextLevel';
    // }

    final stats = entityData['stats'];

    final effects = <Widget>[];
    if (stats != null) {
      final effectData = stats['effects'] ?? {};
      for (final effect in effectData.values) {
        final values = <String>[];
        for (final value in effect['values']) {
          final v = value['value'] as num;
          final type = value['type'];
          if (type == null || type == kValueTypeInt) {
            values.add(v.toString());
          } else if (type == kValueTypeFloat) {
            values.add(v.toStringAsFixed(2));
          } else if (type == kValueTypePercentage) {
            values.add(v.toPercentageString());
          } else {
            engine.error('未知的效果数据类型：[$type]，效果对象数据：$entityData');
          }
        }
        final description = engine.locale
            .getLocaleString(effect['description'], interpolations: values);
        effects.add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 2.0),
                  width: 275.0,
                  child: Text(description),
                ),
              ],
            ),
          ),
        );
      }
    }

    return Material(
      type: MaterialType.transparency,
      child: GestureDetector(
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
                width: _kInfoPanelWidth,
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
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            entityData['name'],
                            style: TextStyle(color: titleColor),
                          ),
                        ],
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                              '${engine.locale[category]} - ${engine.locale[entityData['kind']]}'),
                          if (entityData['rarity'] != null)
                            Text(engine.locale[entityData['rarity']]),
                        ],
                      ),
                      if (entityData['description'] != null &&
                          entityData['description'].isNotEmpty)
                        Text(
                          entityData['description'],
                          style: const TextStyle(color: Colors.grey),
                        ),
                      const Divider(),
                      if (showPrice)
                        Text(
                            '${engine.locale['price']}: ${(entityData['value'] * priceFactor).truncate()}'),
                      if (stackSize > 1)
                        Text('${engine.locale['stackSize']}: $stackSize'),
                      if (equipType == kEquipTypeCompanion)
                        Text(
                            '${engine.locale['coordination']}: ${entityData['coordination']}'),
                      // if (entityType == kEntityTypeSkill) ...[
                      //   Text('${engine.locale['level']}: $levelString'),
                      //   Text('${engine.locale['exp']}: $expString'),
                      // ],
                      if (equipType == kEquipTypeCompanion)
                        Text(
                            '${engine.locale['life']}: ${stats['life']}/${stats['lifeMax']}'),
                      if (equipType == kEquipTypeOffense ||
                          equipType == kEquipTypeDefense)
                        Text(
                            '${engine.locale['durability']}: ${stats['life']}/${stats['lifeMax']}'),
                      if (equipType == kEquipTypeOffense) ...[
                        Text('${engine.locale['damage']}: ${stats['damage']}'),
                        Text(
                            '${engine.locale['damageType']}: ${engine.locale[entityData['damageType']]}'),
                        Text('${engine.locale['speed']}: ${stats['speed']}f'),
                      ],
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
      ),
    );
  }
}
