import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../shared/responsive_window.dart';
import '../../../global.dart';
import '../../shared/close_button.dart';
import '../character/build/inventory.dart';
import '../../../event/events.dart';

class MerchantView extends StatefulWidget {
  static Future<bool?> show({
    required BuildContext context,
    required HTStruct merchantData,
    double priceFactor = 1.0,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return MerchantView(
          merchantData: merchantData,
          priceFactor: priceFactor,
        );
      },
    );
  }

  const MerchantView({
    super.key,
    required this.merchantData,
    this.priceFactor = 1.0,
  });

  final HTStruct merchantData;
  final double priceFactor;

  @override
  State<MerchantView> createState() => _MerchantViewState();
}

class _MerchantViewState extends State<MerchantView> {
  @override
  Widget build(BuildContext context) {
    final heroData = engine.invoke('getHero');

    return ResponsiveWindow(
      size: const Size(720.0, 440.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale['trade']),
          actions: const [ButtonClose()],
        ),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 320.0,
              height: 390.0,
              child: InventoryView(
                characterName: widget.merchantData['name'],
                inventoryData: widget.merchantData['inventory'],
                money: widget.merchantData['money'],
                type: InventoryType.merchant,
                priceFactor: widget.priceFactor,
                onBuy: (item, quantity) {
                  final int restOfMoney = heroData['money'];
                  final int payment =
                      (item['value'] * widget.priceFactor).truncate() *
                          quantity;
                  if (restOfMoney < payment) {
                    engine.info('${heroData['name']} 银两不足，无法购买。');
                    return;
                  }
                  engine.invoke('characterGiveMoney', positionalArgs: [
                    heroData,
                    widget.merchantData,
                    payment,
                  ]);
                  engine.invoke('characterGive', positionalArgs: [
                    widget.merchantData,
                    heroData,
                    item,
                    quantity,
                  ]);
                  Navigator.of(context).pop();
                  engine.broadcast(const UIEvent.needRebuildUI());
                  setState(() {});
                },
              ),
            ),
            const VerticalDivider(),
            SizedBox(
              width: 320.0,
              height: 390.0,
              child: InventoryView(
                characterName: heroData['name'],
                inventoryData: heroData['inventory'],
                money: heroData['money'],
                type: InventoryType.customer,
                priceFactor: widget.priceFactor,
                onSell: (item, quantity) {
                  final int restOfMoney = widget.merchantData['money'];
                  final int payment = item['value'].truncate() * quantity;
                  if (restOfMoney < payment) {
                    engine.info('${widget.merchantData['name']} 银两不足，无法出售。');
                    return;
                  }
                  engine.invoke('characterGiveMoney', positionalArgs: [
                    widget.merchantData,
                    heroData,
                    payment,
                  ]);
                  engine.invoke('characterGive', positionalArgs: [
                    heroData,
                    widget.merchantData,
                    item,
                    quantity,
                  ]);
                  Navigator.of(context).pop();
                  engine.broadcast(const UIEvent.needRebuildUI());
                  setState(() {});
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
