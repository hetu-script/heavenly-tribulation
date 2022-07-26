import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../shared/responsive_window.dart';
import '../../../global.dart';
import '../../shared/close_button.dart';
import '../character/builds/inventory.dart';
import '../../../event/events.dart';

class MerchantView extends StatefulWidget {
  static Future<bool?> show({
    required BuildContext context,
    required HTStruct merchantData,
    double priceFactor = 2.0,
    bool allowSell = true,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return MerchantView(
          merchantData: merchantData,
          priceFactor: priceFactor,
          allowSell: allowSell,
        );
      },
    );
  }

  const MerchantView({
    super.key,
    required this.merchantData,
    this.priceFactor = 2.0,
    this.allowSell = true,
  });

  final HTStruct merchantData;
  final double priceFactor;
  final bool allowSell;

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
                    engine.info(
                        '${heroData['name']} 银两只有 $restOfMoney 不足 $payment，无法购买。');
                    return;
                  }
                  engine.invoke('characterGiveMoney', positionalArgs: [
                    heroData,
                    widget.merchantData,
                    payment,
                  ]);
                  engine.invoke('enityGiveItem', positionalArgs: [
                    widget.merchantData,
                    heroData,
                    item,
                  ], namedArgs: {
                    'count': quantity,
                  });
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
                type: widget.allowSell
                    ? InventoryType.customer
                    : InventoryType.player,
                priceFactor: widget.priceFactor,
                onSell: (item, quantity) {
                  final int restOfMoney = widget.merchantData['money'];
                  final int payment = item['value'].truncate() * quantity;
                  if (restOfMoney < payment) {
                    engine.info('${widget.merchantData['name']} 银钱不足，无法出售。');
                    return;
                  }
                  engine.invoke('characterGiveMoney', positionalArgs: [
                    widget.merchantData,
                    heroData,
                    payment,
                  ]);
                  engine.invoke('enityGiveItem', positionalArgs: [
                    heroData,
                    widget.merchantData,
                    item,
                  ], namedArgs: {
                    'count': quantity,
                  });
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
