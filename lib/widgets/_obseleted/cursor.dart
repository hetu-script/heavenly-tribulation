import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';

import '../../state/cursor.dart';

class CustomCursor extends StatelessWidget {
  const CustomCursor({
    super.key,
    required this.width,
    required this.height,
  });

  final double width, height;

  @override
  Widget build(BuildContext context) {
    final cursorName = context.watch<CursorState>().cursor;
    return MouseRegion(
      opaque: false,
      cursor: cursorName != null
          ? FlutterCustomMemoryImageCursor(key: cursorName)
          : MouseCursor.defer,
    );
  }
}
