import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/rrect_icon.dart';
import 'package:samsara/widgets/ui/mouse_region2.dart';

import '../../ui.dart';
import '../../global.dart';
import '../../data/game.dart';
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
    this.color = GameUI.backgroundColor,
    this.size = const Size(100.0, 100.0),
    this.radius = const Radius.circular(10.0),
    this.borderColor = GameUI.borderColor,
    this.borderWidth = 2.0,
    this.characterId,
    this.characterData,
    this.onPressed,
    this.onEnter,
    this.onExit,
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
  final Radius radius;
  final Color borderColor;
  final double borderWidth;
  final String? characterId;
  final dynamic characterData;
  final void Function(dynamic character)? onPressed;
  final void Function(Rect)? onEnter;
  final void Function()? onExit;

  @override
  Widget build(BuildContext context) {
    Widget? icon, border;

    String? displayName = name;
    ImageProvider<Object>? iconImg = image;
    ImageProvider<Object>? borderImg = borderImage;

    dynamic character;

    if (characterId != null) {
      character = GameData.getCharacter(characterId!);
    } else if (characterData != null) {
      character = characterData;
    }

    if (displayName == null && character != null) {
      if (character != GameData.hero) {
        final haveMet = engine.hetu
            .invoke('haveMet', positionalArgs: [GameData.hero, character]);
        if (haveMet != null) {
          displayName = character['name'];
        } else {
          displayName = '???';
        }
      } else {
        displayName = engine.locale('you');
      }
    }

    if (iconImg == null) {
      if (character != null) {
        iconImg = AssetImage('assets/images/${character['icon']}');
      } else if (showPlaceholder) {
        iconImg = AssetImage('assets/images/illustration/placeholder.png');
      }
    }

    if (iconImg != null) {
      icon = RRectIcon(
        backgroundColor: color,
        image: iconImg,
        size:
            (displayName != null && nameAlignment != AvatarNameAlignment.inside)
                ? Size(size.width - kNameHeight, size.height - kNameHeight)
                : size,
        borderRadius: BorderRadius.all(radius),
        borderColor: borderColor,
        borderWidth: borderWidth,
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
        borderRadius: BorderRadius.all(radius),
        borderColor: borderColor,
        borderWidth: borderWidth,
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

    if (nameAlignment == AvatarNameAlignment.inside) {
      if (icon != null) {
        widgets.add(icon);
      }
      if (displayName != null) {
        widgets.add(Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: size.width,
            decoration: BoxDecoration(
              color: Colors.white70,
              borderRadius:
                  BorderRadius.only(bottomLeft: radius, bottomRight: radius),
              border: Border.symmetric(
                  horizontal: BorderSide(color: GameUI.borderColor)),
            ),
            child: Text(
              displayName,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: GameUI.backgroundColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ));
      }
      if (showBorderImage) {
        widgets.add(border!);
      }
    } else {
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
    }

    return GestureDetector(
      onTap: () => onPressed?.call(character),
      child: MouseRegion2(
        onEnter: onEnter,
        onExit: onExit,
        cursor: cursor ?? GameUI.cursor.resolve({WidgetState.hovered}),
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
