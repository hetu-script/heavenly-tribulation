import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hetu_script/utils/uid.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path;
// import 'package:samsara/utils/json.dart';
import 'package:hetu_script/values.dart';
import 'package:json5/json5.dart';

import '../engine.dart';
import '../datetime.dart';
import '../common.dart';
import '../game/data.dart';

Future<SaveInfo> createSaveInfo(String currentWorldId,
    [String? saveName]) async {
  saveName ??= randomUID();
  final directory = await path.getApplicationDocumentsDirectory();
  final savePath = path.join(
      directory.path, engine.name, 'save', '$saveName$kGameSaveFileExtension');
  return SaveInfo(
    saveName: saveName,
    savePath: savePath,
    currentWorldId: currentWorldId,
  );
}

class SaveInfo {
  final String savePath;
  final String saveName;
  String currentWorldId;
  String? timestamp;

  SaveInfo({
    required this.savePath,
    required this.saveName,
    required this.currentWorldId,
    this.timestamp,
  });
}

class GameSavesState with ChangeNotifier {
  final Map<String, SaveInfo> saves = {};

  Future<void> loadList([String folder = 'save']) async {
    saves.clear();

    final appDirectory = await path.getApplicationDocumentsDirectory();
    final saveFolder = path.join(appDirectory.path, engine.name, folder);

    final saveDirectory = Directory(saveFolder);
    if (saveDirectory.existsSync()) {
      for (final entity in saveDirectory.listSync()) {
        if (entity is File &&
            path.extension(entity.path) == kGameSaveFileExtension) {
          final gameSave = await entity.open();
          final gameDataString = utf8.decoder
              .convert((await gameSave.read(await gameSave.length())).toList());
          await gameSave.close();
          final gameData = json5Decode(gameDataString);
          final currentWorldId = (gameData as Map)['currentWorldId'];
          final fileName = path.basenameWithoutExtension(entity.path);
          final timestamp =
              entity.lastModifiedSync().toLocal().toMeaningfulString();
          final saveInfo = SaveInfo(
            saveName: fileName,
            timestamp: timestamp,
            savePath: entity.path,
            currentWorldId: currentWorldId,
          );
          saves[fileName] = saveInfo;
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
    engine.debug('保存游戏至：[${info.savePath}]');
    info.currentWorldId = worldId;

    final gameJSONData = (GameData.game as HTStruct).toJSON();
    final gameStringData = json5Encode(gameJSONData, space: 2);

    IOSink sink;
    final saveFile1 = File(info.savePath);
    if (!saveFile1.existsSync()) {
      saveFile1.createSync(recursive: true);
    }
    sink = saveFile1.openWrite();
    sink.write(gameStringData);
    await sink.flush();
    await sink.close();

    final timestamp =
        saveFile1.lastModifiedSync().toLocal().toMeaningfulString();

    final universeJsonData = (GameData.universe as HTStruct).toJSON();
    final universeStringData = json5Encode(universeJsonData, space: 2);

    final saveFile2 = File('${info.savePath}$kUniverseSaveFilePostfix');
    if (!saveFile2.existsSync()) {
      saveFile2.createSync(recursive: true);
    }
    sink = saveFile2.openWrite();
    sink.write(universeStringData);
    await sink.flush();
    await sink.close();

    final historyJsonData = (GameData.history as HTStruct).toJSON();
    final historyStringData = json5Encode(historyJsonData, space: 2);

    final saveFile3 = File('${info.savePath}$kHistorySaveFilePostfix');
    if (!saveFile3.existsSync()) {
      saveFile3.createSync(recursive: true);
    }
    sink = saveFile3.openWrite();
    sink.write(historyStringData);
    await sink.flush();
    await sink.close();

    info.timestamp = timestamp;

    return info;
  }
}
