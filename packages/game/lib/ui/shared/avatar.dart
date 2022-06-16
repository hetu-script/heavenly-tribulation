import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    Key? key,
    this.margin,
    this.avatarAssetKey,
    this.name,
    this.size = const Size(100.0, 100.0),
    this.radius = 10.0,
    this.borderColor = Colors.white,
    this.borderWidth = 2.0,
    this.onPressed,
  }) : super(key: key);

  final EdgeInsetsGeometry? margin;

  final String? avatarAssetKey;

  final String? name;

  final Size size;

  final double radius;

  final Color borderColor;

  final double borderWidth;

  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    final stacked = <Widget>[];

    stacked.add(
      ClipRRect(
        borderRadius: BorderRadius.all(Radius.circular(radius)),
        child: Container(
          margin: margin,
          width: size.width,
          height: size.height,
          decoration: BoxDecoration(
            image: avatarAssetKey != null
                ? DecorationImage(
                    fit: BoxFit.fill,
                    image: AssetImage(avatarAssetKey!),
                  )
                : null,
            borderRadius: BorderRadius.all(Radius.circular(radius)),
            border: Border.all(color: borderColor, width: borderWidth),
          ),
        ),
      ),
    );

    if (name != null) {
      stacked.add(
        Positioned(
          top: size.height - 15.0,
          child: Container(
            color: Colors.blueGrey,
            child: Text(name!),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onPressed,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Stack(
            children: stacked,
          ),
        ),
      ),
    );
  }
}
