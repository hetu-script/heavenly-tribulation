import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:provider/provider.dart';

import '../../game/ui.dart';
import '../../engine.dart';
import '../ui/bordered_icon_button.dart';
import '../../state/hover_content.dart';

class NewRank extends StatefulWidget {
  const NewRank({
    super.key,
    required this.rank,
  }) : assert(rank > 0);

  final int rank;

  @override
  State<NewRank> createState() => _NewRankState();
}

class _NewRankState extends State<NewRank> {
  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      width: screenSize.width,
      height: screenSize.height,
      child: Align(
        alignment: Alignment.center,
        child: SizedBox(
          width: 800.0,
          height: 450.0,
          child: Column(
            children: [
              Image(image: AssetImage('assets/images/rank_up.png')),
              BorderedIconButton(
                borderWidth: 0.0,
                size: Size(125.0, 125),
                child: Image(
                  image: AssetImage(
                      'assets/images/cultivation/cultivation${widget.rank}.png'),
                ),
                onMouseEnter: (rect) {
                  context.read<HoverContentState>().show(
                        engine.locale('cultivationRank_${widget.rank}'),
                        rect,
                        direction: HoverContentDirection.topCenter,
                      );
                },
                onMouseExit: () {
                  context.read<HoverContentState>().hide();
                },
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: fluent.FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    engine.locale('ok'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
