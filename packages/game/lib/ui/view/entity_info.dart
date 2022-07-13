import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/util.dart';

import '../../global.dart';
import '../shared/rrect_icon.dart';
// import '../../../shared/close_button.dart';

const _kInfoPanelWidth = 390.0;

// entityType决定了该对象的数据结构和保存位置
const kEntityTypeCharacter = 'character'; //game.characters
const kEntityTypeNpc = 'npc'; //game.npcs
const kEntityTypeItem = 'item'; //character.inventory
const kEntityTypeSkill = 'skill'; //character.skill

// category是界面上显示的对象类型文字
const kEntityCategoryCharacter = 'character';
const kEntityCategoryBeast = 'beast';
const kEntityCategoryWeapon = 'weapon';
const kEntityCategoryProtect = 'protect';
const kEntityCategoryTalisman = 'talisman';
const kEntityCategoryConsumable = 'consumable';
const kEntityCategoryFightSkill = 'fightSkill';

const kEntityConsumableKindMedicine = 'medicine';
const kEntityConsumableKindBeverage = 'beverage';
const kEntityConsumableKindElixir = 'elixir';

const kEquipTypeOffense = 'offense';
const kEquipTypeSupport = 'support';
const kEquipTypeDefense = 'defense';
const kEquipTypeCompanion = 'companion';

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

    final entityType = entityData['entityType'];
    final category = entityData['category'];
    final equipType = entityData['equipType'];

    final attributes = entityData['attributes'];
    final stats = entityData['stats'];

    final effectData = entityData['effects'] ?? [];
    final effects = <Widget>[];
    for (final data in effectData) {
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
                            avatarAssetKey:
                                'assets/images/${entityData['icon']}',
                            size: const Size(80.0, 80.0),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entityData['name'],
                                style: TextStyle(color: titleColor),
                              ),
                              const Divider(),
                              Text(
                                entityData['description'],
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
                            '${engine.locale[category]} - ${engine.locale[entityData['kind']]}'),
                        if (entityType == kEntityTypeItem)
                          Text(engine.locale[entityData['rarity']]),
                      ],
                    ),
                    if (showPrice)
                      Text(
                          '${engine.locale['price']}: ${(entityData['value'] * priceFactor).truncate()}'),
                    if (stackSize > 1)
                      Text('${engine.locale['stackSize']}: $stackSize'),
                    if (category == kEntityCategoryWeapon ||
                        category == kEntityCategoryProtect)
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
