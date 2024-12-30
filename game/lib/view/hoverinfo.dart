import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../ui.dart';
// import '../../shared/rrect_icon.dart';
// import '../../../shared/close_button.dart';
// import '../../../common.dart';
import 'common.dart';

class HoverInfo extends StatefulWidget {
  HoverInfo({
    this.left,
    this.top,
    this.width = 200.0,
    required this.onSizeChanged,
    required this.text,
    required this.hoveringRect,
  }) : super(key: GlobalKey());

  final double? left, top;
  final double width;
  final void Function() onSizeChanged;
  final InlineSpan text;
  final Rect hoveringRect;

  @override
  State<HoverInfo> createState() => _HoverInfoState();
}

class _HoverInfoState extends State<HoverInfo> {
  double? _left, _top;

  bool _isVisible = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final screenSize = MediaQuery.sizeOf(context);
      final renderBox = (widget.key as GlobalKey)
          .currentContext!
          .findRenderObject() as RenderBox;
      final Size size = renderBox.size;
      _onSizeDetermined(size, screenSize);
    });
  }

  void _onSizeDetermined(Size infoSize, Size screenSize) {
    setState(() {
      if (infoSize.height < screenSize.height) {
        _top = math.min(
            screenSize.height - infoSize.height, widget.hoveringRect.top);
      }

      double preferredX = widget.hoveringRect.right + kEntityInfoIndent;
      if (preferredX > (screenSize.width - infoSize.width)) {
        _left = widget.hoveringRect.left - kEntityInfoIndent - infoSize.width;
      } else {
        _left = preferredX;
      }

      _isVisible = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _left ?? widget.left,
      top: _top ?? widget.top,
      child: Visibility(
        visible: _isVisible,
        child: SingleChildScrollView(
          child: Container(
            // margin: const EdgeInsets.only(right: 240.0, top: 120.0),
            padding: const EdgeInsets.all(10.0),
            width: widget.width,
            decoration: BoxDecoration(
              color: kBackgroundColor,
              borderRadius: kBorderRadius,
              border: Border.all(color: kForegroundColor),
            ),
            child: ClipRRect(
              borderRadius: kBorderRadius,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [RichText(text: widget.text)],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
