import 'package:flutter/material.dart';
import 'package:samsara/ui/bordered_icon_button.dart';
import 'package:samsara/ui/responsive_view.dart';

import '../../game/ui.dart';
import '../../engine.dart';

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
        child: Container(
          width: 800.0,
          height: 400.0,
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
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
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
