import 'package:flutter/material.dart';

import 'package:samsara/ui/rrect_icon.dart';
import '../config.dart';
// import 'character/profile.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.displayName,
    this.preferNameOnTop = false,
    this.margin,
    this.image,
    this.borderImage,
    this.showBorder = true,
    this.color = Colors.transparent,
    this.showHandCursor = true,
    this.size = const Size(100.0, 100.0),
    this.radius = 15.0,
    this.borderColor = Colors.transparent,
    this.borderWidth,
    this.characterId,
    this.characterData,
    this.onPressed,
  });

  final bool preferNameOnTop;

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

  final void Function(String charId)? onPressed;

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
      iconImg ??= AssetImage('assets/images/avatar/${charData['icon']}');
    }

    if (iconImg != null) {
      icon = RRectIcon(
        backgroundColor: color,
        image: iconImg,
        size: (name != null && preferNameOnTop)
            ? Size(size.width - 30, size.height - 30)
            : size,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        // borderColor: borderColor,
        borderWidth: borderWidth ?? 0.0,
      );
    }

    if (showBorder && iconImg != null) {
      borderImg ??= const AssetImage('assets/images/avatar/border.png');
      border = RRectIcon(
        backgroundColor: Colors.transparent,
        image: borderImg,
        size: (name != null && preferNameOnTop)
            ? Size(size.width - 30, size.height - 30)
            : size,
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        borderColor: borderColor,
        borderWidth: borderWidth ?? 0.0,
      );
    }

    final widgets = <Widget>[];

    if (preferNameOnTop) {
      if (name != null) {
        widgets.add(
          Align(
            alignment: Alignment.topCenter,
            child: Text(
              name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }
      if (icon != null) {
        widgets.add(
          Positioned.fill(
            top: 30.0,
            child: Container(
              alignment: Alignment.bottomCenter,
              padding: const EdgeInsets.only(bottom: 10.0),
              child: icon,
            ),
          ),
        );

        if (showBorder) {
          widgets.add(
            Positioned.fill(
              top: 30.0,
              child: Container(
                alignment: Alignment.bottomCenter,
                padding: const EdgeInsets.only(bottom: 10.0),
                child: border,
              ),
            ),
          );
        }
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
            padding: const EdgeInsets.only(bottom: 5.0),
            decoration: BoxDecoration(
              color: Colors.white54,
              borderRadius: BorderRadius.only(bottomLeft: br, bottomRight: br),
              border: Border.symmetric(
                  horizontal: BorderSide(color: Colors.grey.shade400)),
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
      onTap: () {
        if (onPressed != null) {
          onPressed!(characterId ?? charData?['id']);
        }
      },
      child: MouseRegion(
        cursor: showHandCursor
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: Container(
          margin: margin,
          width: size.width,
          height: size.height,
          child: Stack(
            children: widgets,
          ),
        ),
      ),
    );
  }
}
