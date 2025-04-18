import 'package:flutter/material.dart';
import 'package:samsara/ui/rrect_icon.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';

import '../game/ui.dart';
import '../game/data.dart';
// import 'character/profile.dart';

enum AvatarNameAlignment {
  inside,
  top,
  bottom,
}

const kNameHeight = 20.0;

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.name,
    this.nameAlignment = AvatarNameAlignment.inside,
    this.cursor,
    this.margin,
    this.image,
    this.borderImage,
    this.showPlaceholder = false,
    this.showBorderImage = false,
    this.color = Colors.transparent,
    this.size = const Size(100.0, 100.0),
    this.borderRadius = 0.0,
    this.borderColor = Colors.transparent,
    this.borderWidth,
    this.characterId,
    this.characterData,
    this.onPressed,
  });

  final MouseCursor? cursor;
  final AvatarNameAlignment nameAlignment;
  final String? name;
  final EdgeInsetsGeometry? margin;
  final ImageProvider<Object>? image, borderImage;
  final bool showPlaceholder;
  final bool showBorderImage;
  final Color color;
  final Size size;
  final double borderRadius;
  final Color borderColor;
  final double? borderWidth;
  final String? characterId;
  final dynamic characterData;
  final void Function(String? charId)? onPressed;

  @override
  Widget build(BuildContext context) {
    Widget? icon, border;

    String? displayName = name;
    ImageProvider<Object>? iconImg = image;
    ImageProvider<Object>? borderImg = borderImage;

    dynamic charData = characterData;

    if (characterId != null) {
      charData = GameData.getCharacter(characterId!);
      displayName ??= charData['name'];
    }

    if (charData != null) {
      iconImg ??= AssetImage('assets/images/${charData['icon']}');
    } else if (showPlaceholder) {
      iconImg ??= AssetImage('assets/images/illustration/placeholder.png');
    }

    if (iconImg != null) {
      icon = RRectIcon(
        backgroundColor: color,
        image: iconImg,
        size:
            (displayName != null && nameAlignment != AvatarNameAlignment.inside)
                ? Size(size.width - kNameHeight, size.height - kNameHeight)
                : size,
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        // borderColor: borderColor,
        borderWidth: borderWidth ?? 0.0,
      );
    }

    if (showBorderImage) {
      borderImg ??= const AssetImage('assets/images/illustration/border.png');
      border = RRectIcon(
        backgroundColor: Colors.transparent,
        image: borderImg,
        size:
            (displayName != null && nameAlignment != AvatarNameAlignment.inside)
                ? Size(size.width - kNameHeight, size.height - kNameHeight)
                : size,
        borderRadius: BorderRadius.all(Radius.circular(borderRadius)),
        borderColor: borderColor,
        borderWidth: borderWidth ?? 0.0,
      );
    }

    final widgets = <Widget>[];

    final outsideNameWidget = Text(
      displayName.toString(),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 20,
      ),
    );

    if (nameAlignment != AvatarNameAlignment.inside) {
      if (displayName != null && nameAlignment == AvatarNameAlignment.top) {
        widgets.add(Container(
          alignment: Alignment.topCenter,
          child: outsideNameWidget,
        ));
      }
      widgets.add(
        Positioned.fill(
          top: nameAlignment == AvatarNameAlignment.top ? kNameHeight : 0.0,
          child: Container(
            alignment: nameAlignment == AvatarNameAlignment.top
                ? Alignment.bottomCenter
                : nameAlignment == AvatarNameAlignment.bottom
                    ? Alignment.topCenter
                    : Alignment.center,
            child: icon,
          ),
        ),
      );

      if (showBorderImage) {
        widgets.add(
          Positioned.fill(
            top: nameAlignment == AvatarNameAlignment.top ? kNameHeight : 0.0,
            child: Container(
              alignment: nameAlignment == AvatarNameAlignment.top
                  ? Alignment.bottomCenter
                  : nameAlignment == AvatarNameAlignment.bottom
                      ? Alignment.topCenter
                      : Alignment.center,
              child: border,
            ),
          ),
        );
      }
      if (displayName != null && nameAlignment == AvatarNameAlignment.bottom) {
        widgets.add(Container(
          alignment: Alignment.bottomCenter,
          child: outsideNameWidget,
        ));
      }
    } else {
      if (icon != null) {
        widgets.add(icon);
      }
      if (displayName != null) {
        final br = Radius.circular(borderRadius);
        widgets.add(Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: size.width,
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius: BorderRadius.only(bottomLeft: br, bottomRight: br),
              border:
                  Border.symmetric(horizontal: BorderSide(color: Colors.grey)),
            ),
            child: Text(
              displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GameUI.backgroundColor2,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
      }
      if (showBorderImage) {
        widgets.add(border!);
      }
    }

    return GestureDetector(
      onTap: () => onPressed?.call(characterId ?? charData?['id']),
      child: MouseRegion(
        cursor: cursor ?? FlutterCustomMemoryImageCursor(key: 'click'),
        child: Container(
          margin: margin,
          width: size.width,
          height: nameAlignment != AvatarNameAlignment.inside
              ? size.height + kNameHeight
              : size.height,
          child: Stack(
            children: widgets,
          ),
        ),
      ),
    );
  }
}
