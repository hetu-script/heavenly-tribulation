import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    Key? key,
    this.avatarAssetKey,
    this.size = 72.0,
    this.radius = 6.0,
  }) : super(key: key);

  final String? avatarAssetKey;

  final double size;

  final double radius;

  @override
  Widget build(BuildContext context) {
    BoxDecoration? avatarImage;
    if (avatarAssetKey != null) {
      avatarImage = BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.fill,
          image: AssetImage(avatarAssetKey!),
        ),
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        border: Border.all(color: Colors.grey.withOpacity(0.5)),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Container(decoration: avatarImage),
    );
  }
}
