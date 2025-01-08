import 'package:flutter/material.dart';
import 'package:samsara/richtext/richtext_builder.dart';
import 'package:provider/provider.dart';

import '../../../ui.dart';
// import '../../shared/rrect_icon.dart';
// import '../../../shared/close_button.dart';
// import '../../../common.dart';
import 'common.dart';
import '../state/hover_info.dart';

class HoverInfo extends StatefulWidget {
  HoverInfo({
    this.maxWidth = kHoverInfoWidth,
    required this.content,
    required this.hoveringRect,
  }) : super(key: GlobalKey());

  // final double left, top;
  final double maxWidth;
  final String content;
  final Rect hoveringRect;

  @override
  State<HoverInfo> createState() => _HoverInfoState();
}

class _HoverInfoState extends State<HoverInfo> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.sizeOf(context);
      final renderObject =
          (widget.key as GlobalKey).currentContext!.findRenderObject();
      final renderBox = renderObject as RenderBox;
      final Size size = renderBox.size;

      late double left, top, width, height;

      if (size.width > widget.maxWidth) {
        width = widget.maxWidth;
      } else {
        width = size.width;
      }

      height = size.height;

      double preferredX = widget.hoveringRect.right + kHoverInfoIndent;
      double maxX = screenSize.width - size.width - kHoverInfoIndent;
      left = preferredX > maxX ? maxX : preferredX;

      double preferredY = widget.hoveringRect.top + kHoverInfoIndent;
      double maxY = screenSize.height - size.height - kHoverInfoIndent;
      top = preferredY > maxY ? maxY : preferredY;

      context
          .read<HoverInfoDeterminedRectState>()
          .set(Rect.fromLTWH(left, top, width, height));
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    final rect = context.watch<HoverInfoDeterminedRectState>().rect;

    return Positioned(
      left: rect?.left ?? screenSize.width,
      top: rect?.top ?? screenSize.height,
      // height: _height,
      child: IgnorePointer(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          constraints: BoxConstraints(maxWidth: widget.maxWidth),
          decoration: BoxDecoration(
            color: GameUI.backgroundColor,
            borderRadius: GameUI.borderRadius,
            border: Border.all(color: GameUI.foregroundColor),
          ),
          child: ClipRRect(
            borderRadius: GameUI.borderRadius,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: buildFlutterRichText(widget.content),
                style: TextStyle(
                  fontFamily: 'NotoSansMono',
                  // fontFamily: GameUI.fontFamily,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
