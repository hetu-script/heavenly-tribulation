import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:samsara/richtext/richtext_builder.dart';
import 'package:provider/provider.dart';

import '../../../ui.dart';
import '../../../engine.dart';
import 'common.dart';
import '../state/hoverinfo.dart';

class HoverInfo extends StatefulWidget {
  HoverInfo({
    required this.data,
    required this.hoveringRect,
    this.maxWidth = kHoverInfoMaxWidth,
    this.textAlign = TextAlign.center,
    this.direction = HoverInfoDirection.bottomCenter,
  }) : super(key: GlobalKey());

  final dynamic data;
  final Rect hoveringRect;
  final double maxWidth;
  final TextAlign textAlign;
  final HoverInfoDirection direction;

  @override
  State<HoverInfo> createState() => _HoverInfoState();
}

class _HoverInfoState extends State<HoverInfo> {
  final _focusNode = FocusNode();

  Rect? _rect;

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

      double preferredX, preferredY;

      switch (widget.direction) {
        case HoverInfoDirection.topLeft:
          preferredX = widget.hoveringRect.left;
          preferredY = widget.hoveringRect.top - height - kHoverInfoIndent;
        case HoverInfoDirection.topCenter:
          preferredX = widget.hoveringRect.left +
              (widget.hoveringRect.width - width) / 2;
          preferredY = widget.hoveringRect.top - height - kHoverInfoIndent;
        case HoverInfoDirection.topRight:
          preferredX = widget.hoveringRect.right - width;
          preferredY = widget.hoveringRect.top - height - kHoverInfoIndent;
        case HoverInfoDirection.leftTop:
          preferredX = widget.hoveringRect.left - width - kHoverInfoIndent;
          preferredY = widget.hoveringRect.top;
        case HoverInfoDirection.leftCenter:
          preferredX = widget.hoveringRect.left - width - kHoverInfoIndent;
          preferredY = widget.hoveringRect.top +
              (widget.hoveringRect.height - height) / 2;
        case HoverInfoDirection.leftBottom:
          preferredX = widget.hoveringRect.left - width - kHoverInfoIndent;
          preferredY = widget.hoveringRect.bottom - height - kHoverInfoIndent;
        case HoverInfoDirection.rightTop:
          preferredX = widget.hoveringRect.right + kHoverInfoIndent;
          preferredY = widget.hoveringRect.top;
        case HoverInfoDirection.rightCenter:
          preferredX = widget.hoveringRect.right + kHoverInfoIndent;
          preferredY = widget.hoveringRect.top +
              (widget.hoveringRect.height - height) / 2;
        case HoverInfoDirection.rightBottom:
          preferredX = widget.hoveringRect.right + kHoverInfoIndent;
          preferredY = widget.hoveringRect.bottom - height - kHoverInfoIndent;
        case HoverInfoDirection.bottomLeft:
          preferredX = widget.hoveringRect.left;
          preferredY = widget.hoveringRect.bottom + kHoverInfoIndent;
        case HoverInfoDirection.bottomCenter:
          preferredX = widget.hoveringRect.left +
              (widget.hoveringRect.width - width) / 2;
          preferredY = widget.hoveringRect.bottom + kHoverInfoIndent;
        case HoverInfoDirection.bottomRight:
          preferredX = widget.hoveringRect.right - width - kHoverInfoIndent;
          preferredY = widget.hoveringRect.bottom + kHoverInfoIndent;
      }

      double maxX = screenSize.width - size.width - kHoverInfoIndent;
      left = preferredX > maxX ? maxX : preferredX;

      double maxY = screenSize.height - size.height - kHoverInfoIndent;
      top = preferredY > maxY ? maxY : preferredY;

      setState(() {
        _rect = Rect.fromLTWH(left, top, width, height);
      });
      // context
      //     .read<HoverInfoDeterminedRectState>()
      //     .set();
    });
  }

  Widget? _decode(dynamic data, {bool isDetailed = false}) {
    Widget? content;
    if (data is String) {
      content = RichText(
        textAlign: widget.textAlign,
        text: TextSpan(
          children: buildFlutterRichText(data),
          style: TextStyle(
            fontFamily: GameUI.fontFamily,
            fontSize: 16.0,
          ),
        ),
      );
    } else if (data is Widget) {
      content = data;
    }

    return content;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    final isDetailed = context.watch<HoverInfoContentState>().isDetailed;
    final content = _decode(widget.data, isDetailed: isDetailed);

    _focusNode.requestFocus();

    return Positioned(
      left: _rect?.left ?? screenSize.width,
      top: _rect?.top ?? screenSize.height,
      // height: _height,
      child: IgnorePointer(
        child: KeyboardListener(
          autofocus: true,
          focusNode: _focusNode,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (kDebugMode) {
                engine.debug('keydown: ${event.logicalKey.keyLabel}');
              }
              switch (event.logicalKey) {
                case LogicalKeyboardKey.controlLeft:
                case LogicalKeyboardKey.controlRight:
                  context.read<HoverInfoContentState>().switchDetailed();
              }
            }
          },
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            constraints: BoxConstraints(maxWidth: widget.maxWidth),
            decoration: BoxDecoration(
              color: GameUI.backgroundColor,
              borderRadius: GameUI.borderRadius,
              border: Border.all(color: GameUI.foregroundColor),
            ),
            child: ClipRRect(
              borderRadius: GameUI.borderRadius,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
