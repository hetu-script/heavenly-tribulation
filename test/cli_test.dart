import 'dart:io';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';

const source1Path = 'game/main.ht';
const source2Path = 'story/main.ht';
const out1Path = 'packages/game/assets/game.mod';
const out2Path = 'packages/game/assets/story.mod';

final sourceContext =
    HTFileSystemResourceContext(root: 'packages/game/scripts/');
final hetu = Hetu(
  config: HetuConfig(debugPerformance: true),
  sourceContext: sourceContext,
);

void testCompile(String sourcePath, String outPath) {
  final source = sourceContext.getResource(sourcePath);
  print('started parsing ${source.fullName}');
  final module = hetu.bundle(source);
  print(
      '${module.errors.length} syntactic error(s) occurred while parsing [game/main.ht].');
  if (module.errors.isNotEmpty) {
    for (final err in module.errors) {
      print(err);
    }
  } else {
    final bytes = hetu.compiler.compile(module);
    final outFile = File(outPath);
    if (!outFile.existsSync()) {
      outFile.createSync(recursive: true);
    }
    outFile.writeAsBytesSync(bytes);
    print('successfully written to [$outPath].');
  }
}

void main() {
  testCompile(source1Path, out1Path);
  testCompile(source2Path, out2Path);
}
