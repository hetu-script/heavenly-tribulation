import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/mouse_region2.dart';

import '../../ui/bordered_icon_button.dart';
// import '../../../game/ui.dart';
import '../../../state/hover_content.dart';
import '../../../engine.dart';
import '../../../state/character.dart';

/// 显示货币数量，以及一个可选的物价系数
/// [priceFactor] 物价系数，仅对于资源有影响
class CurrencyBar extends StatelessWidget {
  const CurrencyBar({
    super.key,
    required this.entity,
    this.priceFactor,
    this.merchantType = MerchantType.location,
  });

  final dynamic entity;
  final dynamic priceFactor;
  final MerchantType merchantType;

  @override
  Widget build(BuildContext context) {
    final money = (entity['materials']['money'] ?? 0).toString();
    final shard = (entity['materials']['shard'] ?? 0).toString();

    final priceFactorDescription = StringBuffer();

    void printPriceFactor(String key, double value) {
      if (value > 1.0) {
        if (value < 1.3) {
          priceFactorDescription.writeln(
              '${engine.locale(key)}: <color=#FE9696>${engine.locale('expensiveSmall')} ${engine.config.debugMode ? '×$value' : ''}</>');
        } else if (value < 1.6) {
          priceFactorDescription.writeln(
              '${engine.locale(key)}: <color=#FF6161>${engine.locale('expensiveMedium')} ${engine.config.debugMode ? '×$value' : ''}</>');
        } else {
          priceFactorDescription.writeln(
              '${engine.locale(key)}: <color=#FF2222>${engine.locale('expensiveLarge')} ${engine.config.debugMode ? '×$value' : ''}</>');
        }
      } else if (value < 1.0) {
        if (value > 0.7) {
          priceFactorDescription.writeln(
              '${engine.locale(key)}: <color=#96FF96>${engine.locale('cheapSmall')} ${engine.config.debugMode ? '×$value' : ''}</>');
        } else if (value > 0.4) {
          priceFactorDescription.writeln(
              '${engine.locale(key)}: <color=#61FF61>${engine.locale('cheapMedium')} ${engine.config.debugMode ? '×$value' : ''}</>');
        } else {
          priceFactorDescription.writeln(
              '${engine.locale(key)}: <color=#22FF22>${engine.locale('cheapLarge')} ${engine.config.debugMode ? '×$value' : ''}</>');
        }
      }
    }

    if (priceFactor != null) {
      if (priceFactor['base'] != null) {
        final double value = priceFactor['base'];
        printPriceFactor('basePriceFactor', value);
      }
      if (priceFactor['sell'] != null) {
        final double value = priceFactor['sell'];
        printPriceFactor('sellPriceFactor', value * 2.0);
      }
      if (priceFactor['category'] != null) {
        for (final key in priceFactor['category'].keys) {
          final double value = priceFactor['category'][key];
          printPriceFactor(key, value);
        }
      }
      if (priceFactor['kind'] != null) {
        for (final key in priceFactor['kind'].keys) {
          final double value = priceFactor['kind'][key];
          printPriceFactor(key, value);
        }
      }
    }

    return Container(
      width: 280.0,
      padding: const EdgeInsets.only(left: 10.0, bottom: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(right: 5.0),
            child: MouseRegion2(
              onMouseEnter: (rect) {
                context
                    .read<HoverContentState>()
                    .show(engine.locale('money_description'), rect);
              },
              onMouseExit: () {
                context.read<HoverContentState>().hide();
              },
              child: Row(
                children: [
                  Container(
                    width: 100.0,
                    padding: const EdgeInsets.only(right: 5.0),
                    child: Text(
                      money,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  Image(
                    width: 20,
                    height: 20,
                    image: AssetImage('assets/images/item/material/money.png'),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.only(right: 5.0),
            child: MouseRegion2(
              onMouseEnter: (rect) {
                context
                    .read<HoverContentState>()
                    .show(engine.locale('shard_description'), rect);
              },
              onMouseExit: () {
                context.read<HoverContentState>().hide();
              },
              child: Row(
                children: [
                  Container(
                    width: 100.0,
                    padding: const EdgeInsets.only(right: 5.0),
                    child: Text(
                      shard,
                      textAlign: TextAlign.end,
                    ),
                  ),
                  Image(
                    width: 20,
                    height: 20,
                    image: AssetImage('assets/images/item/material/shard.png'),
                  ),
                ],
              ),
            ),
          ),
          if (priceFactor != null)
            BorderedIconButton(
              size: const Size(20.0, 20.0),
              onMouseEnter: (rect) {
                final StringBuffer content = StringBuffer();
                if (priceFactorDescription.isNotEmpty) {
                  if (merchantType == MerchantType.location) {
                    content.writeln(
                        '${engine.locale('priceFactor')}\n${engine.locale('priceFactor_description_location')}\n \n${priceFactorDescription.toString()}');
                  } else if (merchantType == MerchantType.character) {
                    content.writeln(
                        '${engine.locale('priceFactor')}\n${engine.locale('priceFactor_description_character')}\n \n${priceFactorDescription.toString()}');
                  } else {
                    content.writeln(
                        '${engine.locale('priceFactor')}\n \n${priceFactorDescription.toString()}');
                  }
                } else {
                  content.writeln(
                      '${engine.locale('priceFactor')}\n \n${engine.locale('none')}');
                }
                context
                    .read<HoverContentState>()
                    .show(content.toString(), rect);
              },
              onMouseExit: () {
                context.read<HoverContentState>().hide();
              },
              child: const Image(
                image: AssetImage('assets/images/icon/quest.png'),
              ),
            ),
        ],
      ),
    );
  }
}
