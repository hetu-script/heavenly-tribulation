import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';

import 'item_grid.dart';
// import 'entity_info.dart';
// import '../../../engine.dart';
// import '../../../../event/ui.dart';
// import 'package:samsara/ui/integer_input_field.dart';
// import 'package:samsara/ui/empty_placeholder.dart';
// import '../../../common.dart';

enum InventoryType {
  player,
  npc,
  merchant,
  customer,
}

/// 如果是玩家自己的物品栏，则传入characterData
class Inventory extends StatelessWidget {
  Inventory({
    super.key,
    required this.type,
    required this.inventoryData,
    required this.height,
    this.characterName,
    // this.style = GridStyle.icon,
    // this.money,
    this.priceFactor = 1.0,
    this.onBuy,
    this.onSell,
    // this.onEquipChanged,
    List<dynamic> filter = const [],
    this.minSlotCount = 36,
    this.gridCountPerLine = 6,
    this.onMouseEnterItemGrid,
    this.onMouseExitItemGrid,
    this.onItemTapped,
    this.onItemSecondaryTapped,
  }) : filter = List<String>.from(filter);

  final double height;
  final dynamic inventoryData;
  // final GridStyle style;
  final String? characterName;
  // final int? money;
  final InventoryType type;
  final double priceFactor;
  final void Function(dynamic item, int quantity)? onBuy, onSell;
  // final VoidCallback? onEquipChanged;
  final List<String> filter;
  final int minSlotCount, gridCountPerLine;
  final void Function(dynamic itemData, Rect gridRenderBox)?
      onMouseEnterItemGrid;
  final void Function()? onMouseExitItemGrid;
  final void Function(dynamic itemData, Offset screenPosition)? onItemTapped;
  final void Function(dynamic itemData, Offset screenPosition)?
      onItemSecondaryTapped;

//   @override
//   State<InventoryView> createState() => _InventoryViewState();
// }

// class _InventoryViewState extends State<InventoryView> {
  // final _scrollController = ScrollController();
  // final _textEditingController = TextEditingController();

  // dynamic _hero;

  // @override
  // void initState() {
  //   if (widget.type == InventoryType.player) {
  //     _hero = engine.hetu.interpreter.fetch('hero');
  //   }
  //   super.initState();
  // }

  // void _onItemTapped(dynamic itemData, Offset screenPosition) {
  //   final sellable = itemData['isUnsellable'] != true;

  //   showDialog(
  //     context: context,
  //     barrierColor: Colors.transparent,
  //     builder: (context) {
  //       final List<Widget> actions = [];
  //       switch (widget.type) {
  //         case InventoryType.player:
  //           if (itemData['isConsumable'] ?? false) {
  //             actions.add(
  //               Padding(
  //                 padding: const EdgeInsets.all(5.0),
  //                 child: ElevatedButton(
  //                   onPressed: () {
  //                     engine.hetu
  //                         .invoke('consume', positionalArgs: [_hero, itemData]);
  //                     Navigator.of(context).pop();
  //                     // engine.emit(const UIEvent.needRebuildUI());
  //                     setState(() {});
  //                   },
  //                   child: Text(engine.locale('consume')),
  //                 ),
  //               ),
  //             );
  //           } else if (itemData['isEquippable'] != null) {
  //             if (itemData['equippedPosition'] == null) {
  //               actions.add(
  //                 Padding(
  //                   padding: const EdgeInsets.all(5.0),
  //                   child: ElevatedButton(
  //                     onPressed: () {
  //                       engine.hetu
  //                           .invoke('equip', positionalArgs: [_hero, itemData]);
  //                       Navigator.of(context).pop();
  //                       // engine.emit(const UIEvent.needRebuildUI());
  //                       if (widget.onEquipChanged != null) {
  //                         widget.onEquipChanged!();
  //                       }
  //                     },
  //                     child: Text(engine.locale('equip')),
  //                   ),
  //                 ),
  //               );
  //             } else {
  //               actions.add(
  //                 Padding(
  //                   padding: const EdgeInsets.all(5.0),
  //                   child: ElevatedButton(
  //                     onPressed: () {
  //                       engine.hetu.invoke('unequip',
  //                           positionalArgs: [_hero, itemData]);
  //                       Navigator.of(context).pop();
  //                       // engine.emit(const UIEvent.needRebuildUI());
  //                       if (widget.onEquipChanged != null) {
  //                         widget.onEquipChanged!();
  //                       }
  //                     },
  //                     child: Text(engine.locale('unequip')),
  //                   ),
  //                 ),
  //               );
  //             }
  //           }
  //         case InventoryType.npc:
  //           actions.add(
  //             Padding(
  //               padding: const EdgeInsets.all(5.0),
  //               child: ElevatedButton(
  //                 onPressed: () {
  //                   engine.hetu.invoke('characterSteal',
  //                       positionalArgs: [_hero, itemData]);
  //                   Navigator.of(context).pop();
  //                   // engine.emit(const UIEvent.needRebuildUI());
  //                   setState(() {});
  //                 },
  //                 child: Text(engine.locale('steal')),
  //               ),
  //             ),
  //           );
  //         case InventoryType.merchant:
  //           _textEditingController.text = '1';
  //           actions.addAll(
  //             [
  //               Material(
  //                 type: MaterialType.transparency,
  //                 child: SizedBox(
  //                   width: 120.0,
  //                   child: IntegerInputField(
  //                     min: 1,
  //                     max: itemData['stackSize'],
  //                     controller: _textEditingController,
  //                   ),
  //                 ),
  //               ),
  //               Padding(
  //                 padding: const EdgeInsets.all(5.0),
  //                 child: ElevatedButton(
  //                   onPressed: () {
  //                     var quantity =
  //                         int.tryParse(_textEditingController.text) ?? 1;
  //                     if (quantity <= 0) {
  //                       quantity = 1;
  //                     }
  //                     if (widget.onBuy != null) {
  //                       widget.onBuy!(itemData, quantity);
  //                     }
  //                   },
  //                   child: Text(engine.locale('buy')),
  //                 ),
  //               ),
  //             ],
  //           );
  //         case InventoryType.customer:
  //           if (sellable) {
  //             _textEditingController.text = itemData['stackSize'].toString();
  //             actions.addAll(
  //               [
  //                 Material(
  //                   type: MaterialType.transparency,
  //                   child: SizedBox(
  //                     width: 120.0,
  //                     child: IntegerInputField(
  //                       min: 1,
  //                       max: itemData['stackSize'],
  //                       controller: _textEditingController,
  //                     ),
  //                   ),
  //                 ),
  //                 Padding(
  //                   padding: const EdgeInsets.all(5.0),
  //                   child: ElevatedButton(
  //                     onPressed: () {
  //                       var quantity =
  //                           int.tryParse(_textEditingController.text) ?? 1;
  //                       if (quantity <= 0) {
  //                         quantity = 1;
  //                       }
  //                       if (widget.onSell != null) {
  //                         widget.onSell!(itemData, quantity);
  //                       }
  //                     },
  //                     child: Text(engine.locale('sell')),
  //                   ),
  //                 ),
  //               ],
  //             );
  //           }
  //       }

  //       return EntityInfo(
  //         entityData: itemData,
  //         left: screenPosition.dx,
  //         actions: actions,
  //         priceFactor:
  //             widget.type == InventoryType.merchant ? widget.priceFactor : 1.0,
  //         showPrice: (widget.type == InventoryType.merchant ||
  //                 widget.type == InventoryType.customer) &&
  //             sellable,
  //       );
  //     },
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    final grids = <Widget>[];
    var index = -1;
    int maxGridCount;
    // if (style == GridStyle.icon) {
    if (inventoryData.length < minSlotCount) {
      maxGridCount = minSlotCount;
    } else {
      maxGridCount = inventoryData.length ~/ gridCountPerLine + 1;
    }
    // } else {
    //   maxGridCount = inventoryData.length;
    // }
    while (grids.length < maxGridCount) {
      ++index;
      if (index < inventoryData.length) {
        final itemData = inventoryData.values.elementAt(index);
        // final entityType = itemData['entityType'];
        if (itemData['equippedPosition'] != null) {
          continue;
        }

        // if (widget.type == InventoryType.merchant) {
        //   if (itemData['equippedPosition'] != null) {
        //     continue;
        //   }
        // }

        // if (widget.type == InventoryType.customer) {
        //   if (itemData['equippedPosition'] != null) {
        //     continue;
        //   }
        // }

        // final isEquipped = itemData['isEquippable'] == true &&
        //     itemData['equippedPosition'] != null;

        // Widget? action;
        // if (widget.type == InventoryType.player) {
        //   action = Column(
        //     children: [
        //       ElevatedButton(
        //         onPressed: () {
        //           final isEquipped = itemData['isEquippable'] == true &&
        //               itemData['equippedPosition'] != null;
        //           if (isEquipped) {
        //             engine.hetu
        //                 .invoke('unequip', positionalArgs: [_hero, itemData]);
        //             // engine.emit(const UIEvent.needRebuildUI());
        //             if (widget.onEquipChanged != null) {
        //               widget.onEquipChanged!();
        //             }
        //           } else {
        //             engine.hetu
        //                 .invoke('equip', positionalArgs: [_hero, itemData]);
        //             // engine.emit(const UIEvent.needRebuildUI());
        //             if (widget.onEquipChanged != null) {
        //               widget.onEquipChanged!();
        //             }
        //           }
        //         },
        //         child: Text(
        //           engine.locale(isEquipped ? 'bench' : 'equip'),
        //         ),
        //       ),
        //     ],
        //   );
        // }

        grids.add(
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: ItemGrid(
              itemData: itemData,
              // style: style,
              onTapped: onItemTapped,
              onSecondaryTapped: onItemSecondaryTapped,
            ),
          ),
        );
      } else {
        grids.add(
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: ItemGrid(
                // style: style,
                ),
          ),
        );
      }
    }

    return SingleChildScrollView(
      // controller: _scrollController,
      child: Container(
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.only(left: 5.0, top: 5.0, right: 5.0),
        width: 60.0 * gridCountPerLine,
        height: height,
        child: ListView(
          shrinkWrap: true,
          children: [
            // style == GridStyle.icon
            //     ?
            Wrap(
              alignment: WrapAlignment.center,
              children: grids,
            )
            // : grids.isEmpty
            //     ? Center(
            //         child: EmptyPlaceholder(
            //           engine.locale('empty'),
            //         ),
            //       )
            //     : Container(
            //         padding: const EdgeInsets.symmetric(horizontal: 10.0),
            //         child: Column(
            //           children: grids,
            //         ),
            //       ),
          ],
        ),
      ),
    );
  }
}
