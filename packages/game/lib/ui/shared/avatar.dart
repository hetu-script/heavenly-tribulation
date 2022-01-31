import 'package:flutter/material.dart';
import '../shared/constants.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    Key? key,
    this.avatarAssetKey,
    this.name,
    this.size = kAvatarSize,
    this.radius = 10.0,
    this.borderColor = Colors.black38,
    this.borderWidth = 3.0,
    this.onPressed,
  }) : super(key: key);

  final String? avatarAssetKey;

  final String? name;

  final double size;

  final double radius;

  final Color borderColor;

  final double borderWidth;

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final stacked = <Widget>[];

    stacked.add(
      Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          image: avatarAssetKey != null
              ? DecorationImage(
                  fit: BoxFit.contain,
                  image: AssetImage(avatarAssetKey!),
                )
              : null,
          borderRadius: BorderRadius.all(Radius.circular(radius)),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
      ),
    );

    if (name != null) {
      stacked.add(
        Positioned(
          top: size - 15.0,
          child: Container(
            color: Colors.blueGrey,
            child: Text(name!),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onPressed,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: stacked,
        ),
      ),
    );
  }
}
