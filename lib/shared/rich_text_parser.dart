import 'package:flutter/widgets.dart';

abstract class RichTextParser {
  TextSpan parse(String text) {
    return TextSpan(
      text: text,
    );
  }
}
