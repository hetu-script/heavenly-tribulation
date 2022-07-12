import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../entity_grid.dart';
import '../../entity_info.dart';
import '../../../../global.dart';

class EquipmentsView extends StatelessWidget {
  const EquipmentsView({
    super.key,
    required this.characterData,
    this.selectedIndex = 0,
    this.cooldownValue = 0.0,
    this.cooldownColor = Colors.white,
  });

  final HTStruct characterData;

  final int selectedIndex;

  final double cooldownValue;

  final Color cooldownColor;

  void _onItemTapped(
      BuildContext context, HTStruct item, Offset screenPosition) {
    showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) {
          return EntityInfo(
            entityData: item,
            left: screenPosition.dx,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final talismans = characterData['equipments']['talisman'];
    final talisman1 = engine.invoke('getEquippedEntity', positionalArgs: [
      talismans[1],
      characterData,
    ]);
    final talisman2 = engine.invoke('getEquippedEntity', positionalArgs: [
      talismans[2],
      characterData,
    ]);
    final talisman3 = engine.invoke('getEquippedEntity', positionalArgs: [
      talismans[3],
      characterData,
    ]);
    final arcanes = characterData['equipments']['arcane'];
    final arcane1 = engine.invoke('getEquippedEntity', positionalArgs: [
      arcanes[1],
      characterData,
    ]);
    final arcane2 = engine.invoke('getEquippedEntity', positionalArgs: [
      arcanes[2],
      characterData,
    ]);
    final arcane3 = engine.invoke('getEquippedEntity', positionalArgs: [
      arcanes[3],
      characterData,
    ]);
    final offenses = characterData['equipments']['offense'];
    final offense1 = engine.invoke('getEquippedEntity', positionalArgs: [
      offenses[1],
      characterData,
    ]);
    final offense2 = engine.invoke('getEquippedEntity', positionalArgs: [
      offenses[2],
      characterData,
    ]);
    final offense3 = engine.invoke('getEquippedEntity', positionalArgs: [
      offenses[3],
      characterData,
    ]);
    final offense4 = engine.invoke('getEquippedEntity', positionalArgs: [
      offenses[4],
      characterData,
    ]);
    final companions = characterData['equipments']['companion'];
    final companion1 = engine.invoke('getEquippedEntity', positionalArgs: [
      companions[1],
      characterData,
    ]);
    final companion2 = engine.invoke('getEquippedEntity', positionalArgs: [
      companions[2],
      characterData,
    ]);
    final companion3 = engine.invoke('getEquippedEntity', positionalArgs: [
      companions[3],
      characterData,
    ]);
    final companion4 = engine.invoke('getEquippedEntity', positionalArgs: [
      companions[4],
      characterData,
    ]);

    return Container(
      width: 390.0,
      height: 390.0,
      padding: const EdgeInsets.only(left: 25.0, right: 25.0, bottom: 25.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: EntityGrid(
                      entityData: talisman1,
                      onSelect: (item, screenPosition) =>
                          _onItemTapped(context, item, screenPosition),
                      isSelected: selectedIndex == 1,
                      backgroundImage: const AssetImage(
                          'assets/images/icon/item/bg_talisman.png'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: EntityGrid(
                      entityData: talisman2,
                      onSelect: (item, screenPosition) =>
                          _onItemTapped(context, item, screenPosition),
                      isSelected: selectedIndex == 2,
                      backgroundImage: const AssetImage(
                          'assets/images/icon/item/bg_talisman.png'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: EntityGrid(
                      entityData: talisman3,
                      onSelect: (item, screenPosition) =>
                          _onItemTapped(context, item, screenPosition),
                      isSelected: selectedIndex == 2,
                      backgroundImage: const AssetImage(
                          'assets/images/icon/item/bg_talisman.png'),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: EntityGrid(
                      entityData: arcane1,
                      onSelect: (item, screenPosition) =>
                          _onItemTapped(context, item, screenPosition),
                      isSelected: selectedIndex == 1,
                      backgroundImage: const AssetImage(
                          'assets/images/icon/item/bg_arcane.png'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: EntityGrid(
                      entityData: arcane2,
                      onSelect: (item, screenPosition) =>
                          _onItemTapped(context, item, screenPosition),
                      isSelected: selectedIndex == 2,
                      backgroundImage: const AssetImage(
                          'assets/images/icon/item/bg_arcane.png'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: EntityGrid(
                      entityData: arcane3,
                      onSelect: (item, screenPosition) =>
                          _onItemTapped(context, item, screenPosition),
                      isSelected: selectedIndex == 2,
                      backgroundImage: const AssetImage(
                          'assets/images/icon/item/bg_arcane.png'),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: EntityGrid(
                  entityData: offense1,
                  onSelect: (item, screenPosition) =>
                      _onItemTapped(context, item, screenPosition),
                  isSelected: selectedIndex == 1,
                  backgroundImage:
                      const AssetImage('assets/images/icon/item/bg_weapon.png'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: EntityGrid(
                  entityData: offense2,
                  onSelect: (item, screenPosition) =>
                      _onItemTapped(context, item, screenPosition),
                  isSelected: selectedIndex == 2,
                  backgroundImage:
                      const AssetImage('assets/images/icon/item/bg_weapon.png'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: EntityGrid(
                  entityData: offense3,
                  onSelect: (item, screenPosition) =>
                      _onItemTapped(context, item, screenPosition),
                  isSelected: selectedIndex == 3,
                  backgroundImage:
                      const AssetImage('assets/images/icon/item/bg_weapon.png'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: EntityGrid(
                  entityData: offense4,
                  onSelect: (item, screenPosition) =>
                      _onItemTapped(context, item, screenPosition),
                  isSelected: selectedIndex == 4,
                  backgroundImage:
                      const AssetImage('assets/images/icon/item/bg_weapon.png'),
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: EntityGrid(
                  entityData: companion1,
                  onSelect: (item, screenPosition) =>
                      _onItemTapped(context, item, screenPosition),
                  isSelected: selectedIndex == 1,
                  backgroundImage: const AssetImage(
                      'assets/images/icon/item/bg_companion.png'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: EntityGrid(
                  entityData: companion2,
                  onSelect: (item, screenPosition) =>
                      _onItemTapped(context, item, screenPosition),
                  isSelected: selectedIndex == 2,
                  backgroundImage: const AssetImage(
                      'assets/images/icon/item/bg_companion.png'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: EntityGrid(
                  entityData: companion3,
                  onSelect: (item, screenPosition) =>
                      _onItemTapped(context, item, screenPosition),
                  isSelected: selectedIndex == 3,
                  backgroundImage: const AssetImage(
                      'assets/images/icon/item/bg_companion.png'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(5.0),
                child: EntityGrid(
                  entityData: companion4,
                  onSelect: (item, screenPosition) =>
                      _onItemTapped(context, item, screenPosition),
                  isSelected: selectedIndex == 4,
                  backgroundImage: const AssetImage(
                      'assets/images/icon/item/bg_companion.png'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
