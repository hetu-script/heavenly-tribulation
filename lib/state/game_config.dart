import 'dart:io';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:samsara/samsara.dart';

import '../global.dart';

const _kConfigFileName = 'config.json';

class GameConfigState with ChangeNotifier {
  /// 从程序根目录下的 config.json 加载配置。
  /// 如果文件不存在，则按当前默认配置写入后返回。
  Future<void> load() async {
    final configFile = File(_configPath);

    if (!configFile.existsSync()) {
      await save();
      return;
    }

    try {
      final content = await configFile.readAsString();
      final json = jsonDecode(content) as Map<String, dynamic>;

      final mods = <String, dynamic>{};
      if (json['mods'] is Map) {
        for (final entry in (json['mods'] as Map).entries) {
          mods[entry.key.toString()] = entry.value;
        }
      }

      engine.config = EngineConfig(
        name: json['name'] as String? ?? engine.config.name,
        developMode: json['developMode'] as bool? ?? engine.config.developMode,
        musicVolume: (json['musicVolume'] as num?)?.toDouble() ??
            engine.config.musicVolume,
        soundEffectVolume: (json['soundEffectVolume'] as num?)?.toDouble() ??
            engine.config.soundEffectVolume,
        showFps: json['showFps'] as bool? ?? engine.config.showFps,
        enableLlm: json['enableLlm'] as bool? ?? engine.config.enableLlm,
        llmModelId: json['llmModelId'] as String? ?? engine.config.llmModelId,
        mods: mods.isNotEmpty ? mods : engine.config.mods,
      );

      notifyListeners();
    } catch (e) {
      engine.error('加载配置文件失败: $e');
    }
  }

  /// 更新 engine.config 并保存到文件。
  /// 只传入需要修改的字段，未传入的字段保持不变。
  Future<void> updateConfig({
    bool? developMode,
    double? musicVolume,
    double? soundEffectVolume,
    bool? showFps,
    bool? enableLlm,
    String? llmModelId,
    Map<String, dynamic>? mods,
  }) async {
    engine.config = EngineConfig(
      name: engine.config.name,
      developMode: developMode ?? engine.config.developMode,
      musicVolume: musicVolume ?? engine.config.musicVolume,
      soundEffectVolume: soundEffectVolume ?? engine.config.soundEffectVolume,
      showFps: showFps ?? engine.config.showFps,
      enableLlm: enableLlm ?? engine.config.enableLlm,
      llmModelId: llmModelId ?? engine.config.llmModelId,
      mods: mods ?? engine.config.mods,
    );
    await save();
  }

  /// 将当前 engine.config 保存到 config.json。
  Future<void> save() async {
    try {
      final json = {
        'name': engine.config.name,
        'debugMode': engine.config.developMode,
        'musicVolume': engine.config.musicVolume,
        'soundEffectVolume': engine.config.soundEffectVolume,
        'showFps': engine.config.showFps,
        'enableLlm': engine.config.enableLlm,
        'llmModelId': engine.config.llmModelId,
        'mods': engine.config.mods,
      };

      final configFile = File(_configPath);
      if (!configFile.existsSync()) {
        configFile.createSync(recursive: true);
      }
      await configFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
      );

      notifyListeners();
    } catch (e) {
      engine.error('保存配置文件失败: $e');
    }
  }

  String get _configPath {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    return '$exeDir${Platform.pathSeparator}$_kConfigFileName';
  }
}
