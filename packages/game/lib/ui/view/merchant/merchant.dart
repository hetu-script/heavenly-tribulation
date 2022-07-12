import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../shared/responsive_window.dart';
import '../../../global.dart';
import '../../shared/close_button.dart';
import '../character/build/inventory.dart';

class MerchantView extends StatefulWidget {
  static Future<bool?> show({
    required BuildContext context,
    required HTStruct merchantData,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return MerchantView(
          merchantData: merchantData,
        );
      },
    );
  }

  const MerchantView({
    super.key,
    required this.merchantData,
  });

  final HTStruct merchantData;

  @override
  State<MerchantView> createState() => _MerchantViewState();
}

class _MerchantViewState extends State<MerchantView> {
  @override
  Widget build(BuildContext context) {
    final heroData = engine.invoke('getHero');

    return ResponsiveWindow(
      size: const Size(700.0, 400.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale['merchant']),
          actions: const [ButtonClose()],
        ),
        body: Row(children: [
          const SizedBox(
            width: 340.0,
            height: 390.0,
          ),
          const VerticalDivider(),
          SizedBox(
            width: 340.0,
            height: 390.0,
            child: InventoryView(
              inventoryData: heroData['inventory'],
            ),
          ),
        ]),
      ),
    );
  }
}
