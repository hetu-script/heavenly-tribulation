import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:samsara/richtext/richtext_builder.dart';
import 'package:provider/provider.dart';
import 'package:hetu_script/values.dart';

import '../game/ui.dart';
import '../../../engine.dart';
import 'common.dart';
import '../state/hover_content.dart';
import '../game/data.dart';

class HoverInfo extends StatefulWidget {
  HoverInfo(this.content) : super(key: GlobalKey());

  final HoverContent content;

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

      if (size.width > widget.content.maxWidth) {
        width = widget.content.maxWidth;
      } else {
        width = size.width;
      }
      height = size.height;

      double preferredX, preferredY;

      switch (widget.content.direction) {
        case HoverContentDirection.topLeft:
          preferredX = widget.content.rect.left;
          preferredY = widget.content.rect.top - height - kHoverInfoIndent;
        case HoverContentDirection.topCenter:
          preferredX = widget.content.rect.left +
              (widget.content.rect.width - width) / 2;
          preferredY = widget.content.rect.top - height - kHoverInfoIndent;
        case HoverContentDirection.topRight:
          preferredX = widget.content.rect.right - width;
          preferredY = widget.content.rect.top - height - kHoverInfoIndent;
        case HoverContentDirection.leftTop:
          preferredX = widget.content.rect.left - width - kHoverInfoIndent;
          preferredY = widget.content.rect.top;
        case HoverContentDirection.leftCenter:
          preferredX = widget.content.rect.left - width - kHoverInfoIndent;
          preferredY = widget.content.rect.top +
              (widget.content.rect.height - height) / 2;
        case HoverContentDirection.leftBottom:
          preferredX = widget.content.rect.left - width - kHoverInfoIndent;
          preferredY = widget.content.rect.bottom - height - kHoverInfoIndent;
        case HoverContentDirection.rightTop:
          preferredX = widget.content.rect.right + kHoverInfoIndent;
          preferredY = widget.content.rect.top;
        case HoverContentDirection.rightCenter:
          preferredX = widget.content.rect.right + kHoverInfoIndent;
          preferredY = widget.content.rect.top +
              (widget.content.rect.height - height) / 2;
        case HoverContentDirection.rightBottom:
          preferredX = widget.content.rect.right + kHoverInfoIndent;
          preferredY = widget.content.rect.bottom - height - kHoverInfoIndent;
        case HoverContentDirection.bottomLeft:
          preferredX = widget.content.rect.left;
          preferredY = widget.content.rect.bottom + kHoverInfoIndent;
        case HoverContentDirection.bottomCenter:
          preferredX = widget.content.rect.left +
              (widget.content.rect.width - width) / 2;
          preferredY = widget.content.rect.bottom + kHoverInfoIndent;
        case HoverContentDirection.bottomRight:
          preferredX = widget.content.rect.right - width - kHoverInfoIndent;
          preferredY = widget.content.rect.bottom + kHoverInfoIndent;
      }

      double maxX = screenSize.width - size.width - kHoverInfoIndent;
      left = preferredX > maxX ? maxX : (preferredX < 0 ? 0 : preferredX);

      double maxY = screenSize.height - size.height - kHoverInfoIndent;
      top = preferredY > maxY ? maxY : (preferredY < 0 ? 0 : preferredY);

      setState(() {
        _rect = Rect.fromLTWH(left, top, width, height);
      });
      // context
      //     .read<HoverInfoDeterminedRectState>()
      //     .set();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    final isDetailed = context.watch<HoverContentState>().isDetailed;

    Widget? content;
    dynamic data = widget.content.data;
    if (data is HTStruct) {
      switch (data['entityType']) {
        case 'item':
          String description;
          switch (widget.content.type) {
            case ItemType.none:
            case ItemType.npc:
              description = GameData.getItemDescription(
                data,
                isDetailed: isDetailed,
              );
            case ItemType.player:
              description = GameData.getItemDescription(
                data,
                isInventory: true,
                isDetailed: isDetailed,
              );
            case ItemType.customer:
              description = GameData.getItemDescription(
                data,
                priceFactor: widget.content.data2,
                isSell: true,
                isDetailed: isDetailed,
              );
            case ItemType.merchant:
              description = GameData.getItemDescription(
                data,
                priceFactor: widget.content.data2,
                isSell: false,
                isDetailed: isDetailed,
              );
          }
          data = description;
        case 'battle_card':
          final (_, description) = GameData.getBattleCardDescription(
            showRequirement: widget.content.type == ItemType.player,
            widget.content.data,
            isDetailed: isDetailed,
            showDebugId: engine.config.debugMode,
          );
          data = description;
      }
    }

    if (data is String) {
      content = RichText(
        textAlign: widget.content.textAlign,
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

    _focusNode.requestFocus();

    return Positioned(
      left: _rect?.left ?? screenSize.width,
      top: _rect?.top ?? screenSize.height,
      // height: _height,
      child: IgnorePointer(
        child: KeyboardListener(
          focusNode: _focusNode,
          onKeyEvent: (event) {
            if (event is KeyDownEvent) {
              if (engine.config.debugMode) {
                engine.debug('keydown: ${event.logicalKey.debugName}');
              }
              switch (event.logicalKey) {
                case LogicalKeyboardKey.controlLeft:
                case LogicalKeyboardKey.controlRight:
                  context.read<HoverContentState>().switchDetailed();
                case LogicalKeyboardKey.keyC:
                  if (widget.content.data is String) {
                    final String text =
                        (widget.content.data as String).split('\n').last;
                    Clipboard.setData(ClipboardData(text: text));
                    engine.debug('copied string: [$text]');
                  } else if (widget.content.data is HTStruct) {
                    Clipboard.setData(
                        ClipboardData(text: widget.content.data['id']));
                    engine.debug(
                        'copied hetu object id: [${widget.content.data['id']}]');
                  }
              }
            }
          },
          child: Container(
            color: GameUI.backgroundColorOpaque.withAlpha(200),
            padding:
                const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            constraints: BoxConstraints(maxWidth: widget.content.maxWidth),
            child: content,
          ),
        ),
      ),
    );
  }
}
