import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/ui/label.dart';

import '../../ui.dart';

class BattleCard extends StatefulWidget {
  BattleCard({
    required this.cardData,
    this.onMouseEnter,
    this.onMouseExit,
  }) : super(key: GlobalKey());

  final HTStruct cardData;
  final Function(dynamic cardData, Rect? widgetRect)? onMouseEnter;
  final Function()? onMouseExit;

  @override
  State<BattleCard> createState() => _BattleCardState();
}

class _BattleCardState extends State<BattleCard> {
  Rect? _renderRect;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _renderRect = getWidgetRenderRect(widget.key as GlobalKey);
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Card(
        shadowColor: Colors.black26,
        child: Ink(
          decoration: BoxDecoration(
            border: Border.fromBorderSide(
              BorderSide(
                color: Colors.white,
                width: 1.0,
              ),
            ),
            borderRadius: kBorderRadius,
            // image: DecorationImage(
            //   image: AssetImage(
            //       'assets/images/cultivation/battlecard/illustration/${cardData['image']}'),
            //   fit: BoxFit.fill,
            // ),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: () {}, // 必须有这个，否则无法触发onHover
              onHover: (bool entered) {
                if (entered) {
                  widget.onMouseEnter?.call(widget.cardData, _renderRect);
                } else {
                  widget.onMouseExit?.call();
                }
              },
              borderRadius: kBorderRadius,
              child: Container(
                alignment: Alignment.centerLeft,
                padding: EdgeInsets.only(left: 5),
                child: Label(
                  height: 20,
                  widget.cardData['name'],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
