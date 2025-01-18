import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:samsara/richtext/richtext_builder.dart';
import 'package:provider/provider.dart';
import 'package:hetu_script/values.dart';

import '../../../data.dart';
import '../../../ui.dart';
import '../../../engine.dart';
// import '../../shared/rrect_icon.dart';
// import '../../../shared/close_button.dart';
// import '../../../common.dart';
import 'common.dart';
import '../state/hover_info.dart';

class HoverInfo extends StatefulWidget {
  HoverInfo({
    this.maxWidth = kHoverInfoWidth,
    required this.data,
    required this.hoveringRect,
    this.direction = HoverInfoDirection.bottomCenter,
  }) : super(key: GlobalKey());

  // final double left, top;
  final double maxWidth;
  final dynamic data;
  final Rect hoveringRect;
  final HoverInfoDirection direction;

  @override
  State<HoverInfo> createState() => _HoverInfoState();
}

class _HoverInfoState extends State<HoverInfo> {
  final _focusNode = FocusNode();

  dynamic _heroData;

  @override
  void initState() {
    super.initState();

    _heroData = engine.hetu.fetch('hero');

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

      context
          .read<HoverInfoDeterminedRectState>()
          .set(Rect.fromLTWH(left, top, width, height));
    });
  }

  String _decode(dynamic data, {bool isDetailed = false}) {
    if (data is HTStruct) {
      if (data['entityType'] == 'item') {
        final description =
            GameData.getDescriptiomFromItemData(data, isDetailed: isDetailed);

        return description;
      } else if (data['entityType'] == 'battle_card') {
        final (_, description) = GameData.getDescriptionFromCardData(
          data,
          isDetailed: isDetailed,
          characterData: _heroData,
        );

        return description;
      }
    }

    return data.toString();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);
    final rect = context.watch<HoverInfoDeterminedRectState>().rect;
    final isDetailed = context.watch<HoverInfoContentState>().isDetailed;
    final content = _decode(widget.data, isDetailed: isDetailed);

    _focusNode.requestFocus();

    return Positioned(
      left: rect?.left ?? screenSize.width,
      top: rect?.top ?? screenSize.height,
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
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: buildFlutterRichText(content),
                  style: TextStyle(
                    // fontFamily: 'NotoSansMono',
                    fontFamily: GameUI.fontFamily,
                    fontSize: 16.0,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
