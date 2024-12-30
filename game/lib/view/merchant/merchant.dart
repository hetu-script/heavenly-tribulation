import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import 'package:samsara/ui/responsive_window.dart';
import '../../engine.dart';
import 'package:samsara/ui/close_button.dart';
import '../character/equipments/inventory.dart';
// import '../../../event/ui.dart';

class MerchantView extends StatefulWidget {
  static Future<bool?> show({
    required BuildContext context,
    required HTStruct merchantData,
    double priceFactor = 2.0,
    bool allowSell = true,
    List<dynamic> sellableCategory = const [],
    List<dynamic> sellableKind = const [],
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return MerchantView(
          merchantData: merchantData,
          priceFactor: priceFactor,
          allowSell: allowSell,
          sellableCategory: List<String>.from(sellableCategory),
          sellableKind: List<String>.from(sellableKind),
        );
      },
    );
  }

  const MerchantView({
    super.key,
    required this.merchantData,
    this.priceFactor = 2.0,
    this.allowSell = true,
    this.sellableCategory = const [],
    this.sellableKind = const [],
  });

  final HTStruct merchantData;
  final double priceFactor;
  final bool allowSell;
  final List<String> sellableCategory;
  final List<String> sellableKind;

  @override
  State<MerchantView> createState() => _MerchantViewState();
}

class _MerchantViewState extends State<MerchantView> {
  @override
  Widget build(BuildContext context) {
    final heroData = engine.hetu.fetch('hero');

    return ResponsiveWindow(
      size: const Size(720.0, 440.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('trade')),
          actions: const [CloseButton2()],
        ),
        body: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 320.0,
              height: 390.0,
              child: InventoryView(
                height: 350,
                characterName: widget.merchantData['name'],
                inventoryData: widget.merchantData['inventory'],
                // money: widget.merchantData['money'],
                type: InventoryType.merchant,
                priceFactor: widget.priceFactor,
                onBuy: (item, quantity) {
                  // final int restOfMoney =
                  //     heroData['inventory']['bronzeCoin'] ?? 0;
                  final int payment =
                      (item['value'] * widget.priceFactor).truncate() *
                          quantity;
                  // if (restOfMoney < payment) {
                  //   engine.info(
                  //       '${heroData['name']} 银两只有 $restOfMoney 不足 $payment，无法购买。');
                  //   return;
                  // }
                  final result = engine.hetu.invoke(
                    'giveMoney',
                    positionalArgs: [
                      heroData,
                      widget.merchantData,
                      payment,
                    ],
                  );
                  if (result) {
                    engine.hetu.invoke(
                      'give',
                      positionalArgs: [
                        widget.merchantData,
                        heroData,
                        item['id'],
                      ],
                      namedArgs: {
                        'count': quantity,
                      },
                    );
                  } else {
                    // TODO: 提示金钱不足
                  }
                  Navigator.of(context).pop();
                  // engine.emit(const UIEvent.needRebuildUI());
                  setState(() {});
                },
              ),
            ),
            const VerticalDivider(),
            SizedBox(
              width: 320.0,
              height: 390.0,
              child: InventoryView(
                height: 350,
                characterName: heroData['name'],
                inventoryData: heroData['inventory'],
                // money: heroData['money'],
                type: widget.allowSell
                    ? InventoryType.customer
                    : InventoryType.player,
                priceFactor: widget.priceFactor,
                onSell: (item, quantity) {
                  // final int restOfMoney = widget.merchantData['money'];
                  final int payment = item['value'].truncate() * quantity;
                  // if (restOfMoney < payment) {
                  //   engine.info('${widget.merchantData['name']} 银钱不足，无法出售。');
                  //   return;
                  // }
                  final result = engine.hetu.invoke(
                    'giveMoney',
                    positionalArgs: [
                      widget.merchantData,
                      heroData,
                      payment,
                    ],
                  );
                  if (result) {
                    engine.hetu.invoke('give', positionalArgs: [
                      heroData,
                      widget.merchantData,
                      item['id'],
                    ], namedArgs: {
                      'count': quantity,
                    });
                  } else {
                    // TODO: 提示金钱不足
                  }
                  Navigator.of(context).pop();
                  // engine.emit(const UIEvent.needRebuildUI());
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
