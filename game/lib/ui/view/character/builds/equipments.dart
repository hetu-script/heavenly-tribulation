import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../grid/entity_grid.dart';
import '../../../../config.dart';
import '../../../common.dart';

class EquipmentsView extends StatelessWidget {
  const EquipmentsView({
    super.key,
    required this.characterData,
    this.selectedIndex = 0,
    this.cooldownValue = 0.0,
    this.cooldownColor = Colors.white,
    this.onItemTapped,
  });

  final HTStruct characterData;
  final int selectedIndex;
  final double cooldownValue;
  final Color cooldownColor;
  final void Function(HTStruct item, Offset screenPosition)? onItemTapped;

  @override
  Widget build(BuildContext context) {
    final equipments = characterData['equipments'];
    final equipmentsGrid = <Widget>[];
    for (var i = 1; i < kEquipmentMax; ++i) {
      final equipment = engine.hetu.invoke('getEquipped', positionalArgs: [
        equipments[i],
        characterData,
      ]);
      equipmentsGrid.add(
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: EntityGrid(
            entityData: equipment,
            onItemTapped: onItemTapped,
            isSelected: selectedIndex == 1,
            backgroundImage:
                const AssetImage('assets/images/icon/item/bg_arcane.png'),
            showEquippedIcon: false,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: equipmentsGrid,
        ),
        // Row(
        //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
        //   children: [
        //     Column(
        //       children: [
        //         Padding(
        //           padding: const EdgeInsets.all(5.0),
        //           child: EntityGrid(
        //             entityData: defense1,
        //             onItemTapped: onItemTapped,
        //             isSelected: selectedIndex == 1,
        //             backgroundImage: const AssetImage(
        //                 'assets/images/icon/item/bg_defense.png'),
        //           ),
        //         ),
        //         Padding(
        //           padding: const EdgeInsets.all(5.0),
        //           child: EntityGrid(
        //             entityData: defense2,
        //             onItemTapped: onItemTapped,
        //             isSelected: selectedIndex == 2,
        //             backgroundImage: const AssetImage(
        //                 'assets/images/icon/item/bg_defense.png'),
        //           ),
        //         ),
        //         Padding(
        //           padding: const EdgeInsets.all(5.0),
        //           child: EntityGrid(
        //             entityData: defense3,
        //             onItemTapped: onItemTapped,
        //             isSelected: selectedIndex == 2,
        //             backgroundImage: const AssetImage(
        //                 'assets/images/icon/item/bg_defense.png'),
        //           ),
        //         ),
        //       ],
        //     ),
        //     Column(
        //       children: [
        //         Padding(
        //           padding: const EdgeInsets.all(5.0),
        //           child: EntityGrid(
        //             entityData: companion1,
        //             onItemTapped: onItemTapped,
        //             isSelected: selectedIndex == 1,
        //             backgroundImage: const AssetImage(
        //                 'assets/images/icon/item/bg_companion.png'),
        //           ),
        //         ),
        //         Padding(
        //           padding: const EdgeInsets.all(5.0),
        //           child: EntityGrid(
        //             entityData: companion2,
        //             onItemTapped: onItemTapped,
        //             isSelected: selectedIndex == 2,
        //             backgroundImage: const AssetImage(
        //                 'assets/images/icon/item/bg_companion.png'),
        //           ),
        //         ),
        //         Padding(
        //           padding: const EdgeInsets.all(5.0),
        //           child: EntityGrid(
        //             entityData: companion3,
        //             onItemTapped: onItemTapped,
        //             isSelected: selectedIndex == 2,
        //             backgroundImage: const AssetImage(
        //                 'assets/images/icon/item/bg_companion.png'),
        //           ),
        //         ),
        //       ],
        //     ),
        //   ],
        // ),
      ],
    );
  }
}
