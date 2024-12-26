import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/extensions.dart';

import '../../../config.dart';
// import '../../shared/rrect_icon.dart';
// import '../../../shared/close_button.dart';
// import '../../../common.dart';

class EntityInfo extends StatefulWidget {
  EntityInfo({
    required this.entityData,
    this.left,
    this.top,
    this.priceFactor = 1.0,
    this.showPrice = false,
    this.width = 300.0,
    this.showHint = true,
    this.onHeightCalculated,
  }) : super(key: GlobalKey());

  final double? left, top;
  final HTStruct entityData;
  final double priceFactor;
  final bool showPrice;
  final double width;
  final bool showHint;
  final void Function(Size infoSize, Size screenSize)? onHeightCalculated;

  @override
  State<EntityInfo> createState() => _EntityInfoState();
}

class _EntityInfoState extends State<EntityInfo> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    if (widget.onHeightCalculated != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final screenSize = MediaQuery.sizeOf(context);
        final renderBox = (widget.key as GlobalKey)
            .currentContext!
            .findRenderObject() as RenderBox;
        final Size size = renderBox.size;
        widget.onHeightCalculated?.call(size, screenSize);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // double? actualLeft;
    // if (left != null) {
    //   actualLeft = left;
    //   final contextSize = MediaQuery.of(context).size;
    //   if (contextSize.width - left! < _kInfoPanelWidth) {
    //     final l = contextSize.width - _kInfoPanelWidth;
    //     actualLeft = l > 0 ? l : 0;
    //   }
    // }

    final titleColor = HexColor.fromString(widget.entityData['color']);

    final stackSize = widget.entityData['stackSize'] ?? 1;

    // final entityType = entityData['entityType'];
    final category = widget.entityData['category'];
    // final equipType = widget.entityData['equipType'];

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

    final stats = widget.entityData['stats'];

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
            engine.error('未知的效果数据类型：[$type]，效果对象数据：${widget.entityData}');
          }
        }
        final description =
            engine.locale(effect['description'], interpolations: values);
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

    return Positioned(
      left: widget.left,
      top: widget.top,
      child: SingleChildScrollView(
        child: Container(
          // margin: const EdgeInsets.only(right: 240.0, top: 120.0),
          padding: const EdgeInsets.all(10.0),
          width: widget.width,
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
                      GameConfig.isDebugMode
                          ? '${widget.entityData['name']}(${widget.entityData['id']})'
                          : widget.entityData['name'],
                      style: TextStyle(color: titleColor),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                        '${engine.locale(category)} - ${engine.locale(widget.entityData['kind'])}'),
                    if (widget.entityData['rarity'] != null)
                      Text(engine.locale(widget.entityData['rarity'])),
                  ],
                ),
                if (widget.entityData['description'] != null)
                  Text(
                    widget.entityData['description'],
                    style: const TextStyle(color: Colors.grey),
                  ),
                if (widget.showHint &&
                    widget.entityData['hint'] != null &&
                    (widget.entityData['hint'] as String).isNotBlank &&
                    widget.entityData['equippedPosition'] == null)
                  Text(
                    widget.entityData['hint'],
                    style: const TextStyle(color: Colors.yellow),
                  ),
                if (widget.showHint &&
                    widget.entityData['equippedPosition'] != null)
                  Text(
                    engine.locale('unequippableHint'),
                    style: const TextStyle(color: Colors.yellow),
                  ),
                if (widget.showPrice || stackSize > 1) const Divider(),
                if (widget.showPrice)
                  Text(
                      '${engine.locale('price')}: ${(widget.entityData['value'] * widget.priceFactor).truncate()}'),
                if (stackSize > 1)
                  Text(
                      '${engine.locale('stackSize')}: $stackSize'), // // if (entityType == kEntityTypeSkill) ...[
                // //   Text('${engine.locale('level')}: $levelString'),
                // //   Text('${engine.locale('exp')}: $expString'),
                // // ],
                // if (equipType == kEquipTypeCompanion)
                //   Text(
                //       '${engine.locale('life')}: ${stats['life']}/${stats['lifeMax']}'),
                // if (equipType == kEquipTypeOffense ||
                //     equipType == kEquipTypeDefense)
                //   Text(
                //       '${engine.locale('durability')}: ${stats['life']}/${stats['lifeMax']}'),
                // if (equipType == kEquipTypeOffense) ...[
                //   Text('${engine.locale('damage')}: ${stats['damage']}'),
                //   Text(
                //       '${engine.locale('damageType')}: ${engine.locale(widget.entityData['damageType'])}'),
                //   Text('${engine.locale('speed')}: ${stats['speed']}f'),
                // ],
                if (effects.isNotEmpty) const Divider(),
                ...effects,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
