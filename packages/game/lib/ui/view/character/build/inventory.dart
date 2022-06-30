import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import 'item_grid.dart';
import 'item_info.dart';

const _kInventorySlotCount = 18;

class InventoryView extends StatelessWidget {
  const InventoryView({
    super.key,
    required this.data,
  });

  final List<dynamic> data;

  void _onItemTapped(
      BuildContext context, HTStruct item, Offset screenPosition) {
    showDialog(
        context: context,
        barrierColor: Colors.transparent,
        builder: (context) {
          return ItemInfo(
            data: item,
            left: screenPosition.dx,
            top: screenPosition.dy - 100.0,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    final skills = <ItemGrid>[];
    for (var i = 0; i < math.max(_kInventorySlotCount, data.length); ++i) {
      if (i < data.length) {
        skills.add(ItemGrid(
          data: data[i],
          onSelect: (item, screenPosition) =>
              _onItemTapped(context, item, screenPosition),
        ));
      } else {
        skills.add(ItemGrid(
          onSelect: (item, screenPosition) =>
              _onItemTapped(context, item, screenPosition),
        ));
      }
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(top: 15.0),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: Wrap(
                children: skills,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
