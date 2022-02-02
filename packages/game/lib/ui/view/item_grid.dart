import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

const kItemGridDefaultSize = 64.0;

class ItemGrid extends StatelessWidget {
  const ItemGrid({
    Key? key,
    this.size = kItemGridDefaultSize,
    this.margin = 5.0,
    this.data,
  }) : super(key: key);

  final double size;
  final double margin;
  final HTStruct? data;

  @override
  Widget build(BuildContext context) {
    final iconAssetKey = data?['icon'];

    return GestureDetector(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: data?['name'] ?? '',
          child: Container(
            width: size,
            height: size,
            margin: EdgeInsets.all(margin),
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(
                color: Colors.white54,
                width: 2,
              ),
              image: iconAssetKey != null
                  ? DecorationImage(
                      fit: BoxFit.contain,
                      image: AssetImage('assets/images/$iconAssetKey'),
                    )
                  : null,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ),
      ),
    );
  }
}
