import 'dart:async';

import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/state/new_prompt.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:provider/provider.dart';

import '../../global.dart';
import '../ui/bordered_icon_button.dart';
import '../../state/hover_content.dart';
import '../../data/common.dart';
import '../ui/responsive_view.dart';

class NewRank extends StatefulWidget {
  const NewRank({
    super.key,
    required this.rank,
    this.completer,
  }) : assert(rank > 0 && rank <= kCultivationRankMax);

  final int rank;
  final Completer? completer;

  @override
  State<NewRank> createState() => _NewRankState();
}

class _NewRankState extends State<NewRank> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      barrierColor: null,
      borderWidth: 0.0,
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
            onEnter: (rect) {
              context.read<HoverContentState>().show(
                    engine.locale('cultivationRank_${widget.rank}'),
                    rect,
                    direction: HoverContentDirection.topCenter,
                  );
            },
            onExit: () {
              context.read<HoverContentState>().hide();
            },
          ),
          Padding(
            padding: const EdgeInsets.only(top: 20.0),
            child: fluent.Button(
              onPressed: () {
                widget.completer?.complete();
                context.read<RankPromptState>().update();
                Navigator.of(context).pop();
              },
              child: Text(
                engine.locale('ok'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
