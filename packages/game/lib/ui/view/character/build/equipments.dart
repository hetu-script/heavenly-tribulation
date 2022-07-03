import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import 'item_grid.dart';
import 'item_info.dart';

class EquipmentsView extends StatelessWidget {
  const EquipmentsView({
    super.key,
    required this.equipmentsData,
    this.selectedIndex = 0,
    this.cooldownValue = 0.0,
    this.cooldownColor = Colors.white,
  });

  final HTStruct equipmentsData;

  final int selectedIndex;

  final double cooldownValue;

  final Color cooldownColor;

  void _onItemTapped(
      BuildContext context, HTStruct item, Offset screenPosition) {
    showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) {
          return ItemInfo(
            itemData: item,
            left: screenPosition.dx,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
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
                    padding: const EdgeInsets.all(10.0),
                    child: ItemGrid(
                      itemData: equipmentsData['offense'][1],
                      onSelect: (item, screenPosition) =>
                          _onItemTapped(context, item, screenPosition),
                      isSelected: selectedIndex == 1,
                      backgroundImage: const AssetImage(
                          'assets/images/icon/item/bg_armor.png'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ItemGrid(
                      itemData: equipmentsData['offense'][2],
                      onSelect: (item, screenPosition) =>
                          _onItemTapped(context, item, screenPosition),
                      isSelected: selectedIndex == 2,
                      backgroundImage: const AssetImage(
                          'assets/images/icon/item/bg_boots.png'),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ItemGrid(
                      itemData: equipmentsData['offense'][1],
                      onSelect: (item, screenPosition) =>
                          _onItemTapped(context, item, screenPosition),
                      isSelected: selectedIndex == 1,
                      backgroundImage: const AssetImage(
                          'assets/images/icon/item/bg_talismam.png'),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: ItemGrid(
                      itemData: equipmentsData['offense'][2],
                      onSelect: (item, screenPosition) =>
                          _onItemTapped(context, item, screenPosition),
                      isSelected: selectedIndex == 2,
                      backgroundImage: const AssetImage(
                          'assets/images/icon/item/bg_talismam.png'),
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
                padding: const EdgeInsets.all(10.0),
                child: ItemGrid(
                  itemData: equipmentsData['offense'][1],
                  onSelect: (item, screenPosition) =>
                      _onItemTapped(context, item, screenPosition),
                  isSelected: selectedIndex == 1,
                  backgroundImage:
                      const AssetImage('assets/images/icon/item/bg_weapon.png'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ItemGrid(
                  itemData: equipmentsData['offense'][2],
                  onSelect: (item, screenPosition) =>
                      _onItemTapped(context, item, screenPosition),
                  isSelected: selectedIndex == 2,
                  backgroundImage:
                      const AssetImage('assets/images/icon/item/bg_weapon.png'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ItemGrid(
                  itemData: equipmentsData['offense'][3],
                  onSelect: (item, screenPosition) =>
                      _onItemTapped(context, item, screenPosition),
                  isSelected: selectedIndex == 3,
                  backgroundImage:
                      const AssetImage('assets/images/icon/item/bg_weapon.png'),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ItemGrid(
                  itemData: equipmentsData['offense'][4],
                  onSelect: (item, screenPosition) =>
                      _onItemTapped(context, item, screenPosition),
                  isSelected: selectedIndex == 4,
                  backgroundImage:
                      const AssetImage('assets/images/icon/item/bg_weapon.png'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
