import 'package:flutter/material.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';

import '../../game/ui.dart';

class SiteCard extends StatelessWidget {
  const SiteCard({
    super.key,
    required this.siteData,
    this.imagePath,
    this.onTap,
    this.onSecondaryTap,
  });

  final dynamic siteData;
  final String? imagePath;
  final void Function(String siteId)? onTap;
  final void Function(String siteId, TapUpDetails details)? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 90,
      height: 140,
      child: Card(
        elevation: 8.0,
        shadowColor: Colors.black26,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: GameUI.borderRadius,
            image: imagePath != null
                ? DecorationImage(
                    image: AssetImage('assets/images/$imagePath'),
                    fit: BoxFit.fill,
                  )
                : null,
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              mouseCursor: FlutterCustomMemoryImageCursor(key: 'click'),
              borderRadius: GameUI.borderRadius,
              onTap: () => onTap?.call(siteData['id']),
              onSecondaryTapUp: (details) =>
                  onSecondaryTap?.call(siteData['id'], details),
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Theme.of(context).primaryColor.withAlpha(128),
                child: Text(
                  siteData['name'],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
