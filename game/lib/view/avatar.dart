import 'package:flutter/material.dart';

import 'package:samsara/ui/rrect_icon.dart';
import '../engine.dart';
import '../ui.dart';
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
    this.displayName,
    this.nameAlignment = AvatarNameAlignment.inside,
    this.margin,
    this.image,
    this.borderImage,
    this.showBorder = false,
    this.color = Colors.transparent,
    this.size = const Size(100.0, 100.0),
    this.radius = 15.0,
    this.borderColor = Colors.transparent,
    this.borderWidth,
    this.characterId,
    this.characterData,
    this.onPressed,
  }) : showHandCursor = onPressed != null;

  final AvatarNameAlignment nameAlignment;

  final String? displayName;

  final EdgeInsetsGeometry? margin;

  final ImageProvider<Object>? image, borderImage;

  final bool showBorder;

  final Color color;

  final bool showHandCursor;

  final Size size;

  final double radius;

  final Color borderColor;

  final double? borderWidth;

  final String? characterId;

  final dynamic characterData;

  final void Function(String? charId)? onPressed;

  @override
  Widget build(BuildContext context) {
    Widget? icon, border;

    String? name = displayName;
    ImageProvider<Object>? iconImg = image;
    ImageProvider<Object>? borderImg = borderImage;

    dynamic charData = characterData;

    if (characterId != null) {
      charData =
          engine.hetu.invoke('getCharacterById', positionalArgs: [characterId]);
    }

    if (charData != null) {
      name ??= charData['name'];
      iconImg ??= AssetImage('assets/images/illustration/${charData['icon']}');
    }

    if (iconImg != null) {
      icon = RRectIcon(
        backgroundColor: color,
        image: iconImg,
        size: (name != null && nameAlignment != AvatarNameAlignment.inside)
            ? Size(size.width - kNameHeight, size.height - kNameHeight)
            : size,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        // borderColor: borderColor,
        borderWidth: borderWidth ?? 0.0,
      );
    }

    if (showBorder && iconImg != null) {
      borderImg ??= const AssetImage('assets/images/illustration/border.png');
      border = RRectIcon(
        backgroundColor: Colors.transparent,
        image: borderImg,
        size: (name != null && nameAlignment != AvatarNameAlignment.inside)
            ? Size(size.width - kNameHeight, size.height - kNameHeight)
            : size,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        borderColor: borderColor,
        borderWidth: borderWidth ?? 0.0,
      );
    }

    final widgets = <Widget>[];

    final outsideNameWidget = Text(
      name.toString(),
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 20,
      ),
    );

    if (nameAlignment != AvatarNameAlignment.inside) {
      if (name != null && nameAlignment == AvatarNameAlignment.top) {
        widgets.add(Container(
          alignment: Alignment.topCenter,
          child: outsideNameWidget,
        ));
      }
      if (icon != null) {
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

        if (showBorder) {
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
      }
      if (name != null && nameAlignment == AvatarNameAlignment.bottom) {
        widgets.add(Container(
          alignment: Alignment.bottomCenter,
          child: outsideNameWidget,
        ));
      }
    } else {
      if (icon != null) {
        widgets.add(icon);
      }
      if (name != null) {
        final br = Radius.circular(radius);
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
              name,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kBackgroundColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
      }
      if (showBorder) {
        widgets.add(border!);
      }
    }

    return GestureDetector(
      onTap: () => onPressed?.call(characterId ?? charData?['id']),
      child: MouseRegion(
        cursor: showHandCursor
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
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
