import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:hetu_script/utils/uid.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path;
import 'package:samsara/utils/json.dart';

import '../config.dart';
import '../datetime.dart';
import '../common.dart';

Future<SaveInfo> createSaveInfo(String worldId, [String? saveName]) async {
  saveName ??= randomUID4(2);
  final directory = await path.getApplicationDocumentsDirectory();
  final savePath = path.join(directory.path, GameConfig.gameTitle, 'save',
      '$worldId.$saveName$kGameSaveFileExtension');
  return SaveInfo(
    saveName: saveName,
    savePath: savePath,
    worldId: worldId,
  );
}

class SaveInfo {
  final String saveName;
  final String savePath;
  final String worldId;
  String? timestamp;

  SaveInfo({
    required this.saveName,
    required this.savePath,
    required this.worldId,
    this.timestamp,
  });
}

class Saves with ChangeNotifier {
  final Map<String, SaveInfo> saves = {};

  Future<void> loadSavesList([String folder = 'save']) async {
    saves.clear();

    final appDirectory = await path.getApplicationDocumentsDirectory();
    final saveFolder =
        path.join(appDirectory.path, GameConfig.gameTitle, folder);

    final saveDirectory = Directory(saveFolder);
    if (saveDirectory.existsSync()) {
      for (final entity in saveDirectory.listSync()) {
        if (entity is File &&
            path.extension(entity.path) == kGameSaveFileExtension) {
          final finalName = path.basenameWithoutExtension(entity.path);
          final split = finalName.split('.');
          final worldId = split.first;
          final saveName = split.last;
          final timestamp =
              entity.lastModifiedSync().toLocal().toMeaningfulString();
          final saveInfo = SaveInfo(
            saveName: saveName,
            timestamp: timestamp,
            savePath: entity.path,
            worldId: worldId,
          );
          saves[saveName] = saveInfo;
        }
      }
    }

    notifyListeners();
  }

  Future<SaveInfo> saveGame(String worldId, [String? saveName]) async {
    late SaveInfo info;
    if (saveName != null && saves.containsKey(saveName)) {
      info = saves[saveName]!;
    } else {
      saveName ??= DateTime.now().toMeaningfulString(useUnderscore: true);
      info = await createSaveInfo(worldId, saveName);
      saves[info.saveName] = info;
    }

    engine.info('保存游戏至：[${info.savePath}]');

    IOSink sink;
    final saveFile1 = File(info.savePath);
    if (!saveFile1.existsSync()) {
      saveFile1.createSync(recursive: true);
    }
    final gameJsonData = engine.hetu.invoke('getGameJsonData');
    final gameStringData = jsonEncodeWithIndent(gameJsonData);
    sink = saveFile1.openWrite();
    sink.write(gameStringData);
    await sink.flush();
    await sink.close();

    final timestamp =
        saveFile1.lastModifiedSync().toLocal().toMeaningfulString();

    final saveFile2 = File('${info.savePath}$kUniverseSaveFilePostfix');
    if (!saveFile2.existsSync()) {
      saveFile2.createSync(recursive: true);
    }
    final universeJsonData = engine.hetu.invoke('getUniverseJsonData');
    final universeStringData = jsonEncodeWithIndent(universeJsonData);
    sink = saveFile2.openWrite();
    sink.write(universeStringData);
    await sink.flush();
    await sink.close();

    final saveFile3 = File('${info.savePath}$kHistorySaveFilePostfix');
    if (!saveFile3.existsSync()) {
      saveFile3.createSync(recursive: true);
    }
    final historyJsonData = engine.hetu.invoke('getHistoryJsonData');
    final historyStringData = jsonEncodeWithIndent(historyJsonData);
    sink = saveFile3.openWrite();
    sink.write(historyStringData);
    await sink.flush();
    await sink.close();

    info.timestamp = timestamp;
    notifyListeners();
    return info;
  }
}
