import 'package:flutter/material.dart';

// const _kEndOfStyledTextMark = '</>';

const _kSupportedTags = <String>{
  'bold',
  'color',
};

class HMLParser {
  static RichText parse(String content) {
    final children = <TextSpan>[];
    final iter = content.characters.iterator;
    final textBuffer = StringBuffer();
    var isTagStarted = false;
    // final currentStyle = {};
    String currentTag;
    while (iter.moveNext()) {
      final currentCharacter = iter.current;
      if (currentCharacter == '<') {
        if (isTagStarted) {
          throw 'HMLParser error: Started another styled text within style label';
        }
        if (textBuffer.isNotEmpty) {
          children.add(TextSpan(text: textBuffer.toString()));
          textBuffer.clear();
        }
        isTagStarted = true;
      } else if (currentCharacter == '=') {
        if (isTagStarted) {
          currentTag = textBuffer.toString();
          textBuffer.clear();
          if (!_kSupportedTags.contains(currentTag)) {
            throw 'HMLParser error: Unrecognized tag: <$currentTag>';
          }
        }
      } else {
        textBuffer.write(currentCharacter);
      }
    }

    return RichText(text: TextSpan(children: children));
  }
}
