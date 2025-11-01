import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/mouse_region2.dart';

// import '../../../game/ui.dart';
import '../../../state/hover_content.dart';
import '../../../global.dart';

class CurrencyBar extends StatelessWidget {
  const CurrencyBar({
    super.key,
    required this.entity,
    this.showMaterialName = true,
  });

  final dynamic entity;
  final bool showMaterialName;

  @override
  Widget build(BuildContext context) {
    final money = (entity['materials']['money'] ?? 0).toString();
    final shard = (entity['materials']['shard'] ?? 0).toString();

    return Row(
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
                Image(
                  width: 20,
                  height: 20,
                  image: AssetImage('assets/images/item/material/money.png'),
                ),
                if (showMaterialName) Text('${engine.locale('money')}:'),
                Container(
                  width: 120.0,
                  padding: const EdgeInsets.only(right: 5.0),
                  child: Text(
                    money,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(
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
                Image(
                  width: 20,
                  height: 20,
                  image: AssetImage('assets/images/item/material/shard.png'),
                ),
                if (showMaterialName) Text('${engine.locale('shard')}:'),
                Container(
                  width: 90.0,
                  padding: const EdgeInsets.only(right: 5.0),
                  child: Text(
                    shard,
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
