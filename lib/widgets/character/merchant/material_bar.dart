import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/mouse_region2.dart';

// import '../../../game/ui.dart';
import '../../../state/hover_content.dart';
import '../../../engine.dart';

class CurrencyBar extends StatelessWidget {
  const CurrencyBar({
    super.key,
    required this.entity,
  });

  final dynamic entity;

  @override
  Widget build(BuildContext context) {
    final money = (entity['materials']['money'] ?? 0).toString();
    final shard = (entity['materials']['shard'] ?? 0).toString();

    return Container(
      width: 300.0,
      padding: const EdgeInsets.only(bottom: 5.0, top: 5.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.only(right: 5.0),
            child: MouseRegion2(
              onEnter: (rect) {
                context
                    .read<HoverContentState>()
                    .show(engine.locale('money_description'), rect);
              },
              onExit: () {
                context.read<HoverContentState>().hide();
              },
              child: Row(
                children: [
                  Container(
                    width: 150.0,
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
              onEnter: (rect) {
                context
                    .read<HoverContentState>()
                    .show(engine.locale('shard_description'), rect);
              },
              onExit: () {
                context.read<HoverContentState>().hide();
              },
              child: Row(
                children: [
                  Container(
                    width: 90.0,
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
        ],
      ),
    );
  }
}
