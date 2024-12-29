import 'dart:io';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_dev_tools/hetu_script_dev_tools.dart';
import 'package:pub_semver/pub_semver.dart';

final version = '0.1.0-pre29';

const source1Path = 'main/main.ht';
const source2Path = 'story/main.ht';
const out1Path = 'packages/game/assets/mods/game.mod';
const out2Path = 'packages/game/assets/mods/story.mod';

final sourceContext =
    HTFileSystemResourceContext(root: 'packages/game/scripts/');
final hetu = Hetu(
  config: HetuConfig(printPerformanceStatistics: true),
  sourceContext: sourceContext,
);

void compileGameMod(String sourcePath, String outPath,
    [String? versionString]) {
  Version? modVersion;
  if (versionString != null) {
    modVersion = Version.parse(versionString);
  }
  final source = sourceContext.getResource(sourcePath);
  print('started parsing ${source.fullName}');
  final module = hetu.bundle(source, version: modVersion);
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
    print('successfully compiled [$sourcePath] to [$outPath].');
  }
}

void main() {
  compileGameMod(source1Path, out1Path, version);
  compileGameMod(source2Path, out2Path, version);
}
