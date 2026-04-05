import 'package:flutter/material.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../global.dart';
// import '../../ui.dart';
import '../../widgets/ui/close_button2.dart';
import '../../widgets/ui/responsive_view.dart';

/// 需要重启才能生效的选项集合
// const _kRestartRequiredKeys = {'debugMode', 'enableLlm', 'llmModelId'};

class GameSettingsDialog extends StatefulWidget {
  const GameSettingsDialog({super.key});

  @override
  State<GameSettingsDialog> createState() => _GameSettingsDialogState();
}

class _GameSettingsDialogState extends State<GameSettingsDialog> {
  late bool _debugMode;
  late double _musicVolume;
  late double _soundEffectVolume;
  late bool _showFps;
  late bool _enableLlm;
  late String _llmModelId;

  /// 记录初始值，用于判断是否有重启选项被修改
  late final bool _initialDebugMode;
  late final bool _initialEnableLlm;
  late final String _initialLlmModelId;

  bool _needRestart = false;

  @override
  void initState() {
    super.initState();
    final config = engine.config;
    _debugMode = config.debugMode;
    _musicVolume = config.musicVolume;
    _soundEffectVolume = config.soundEffectVolume;
    _showFps = config.showFps;
    _enableLlm = config.enableLlm;
    _llmModelId = config.llmModelId ?? '';

    _initialDebugMode = _debugMode;
    _initialEnableLlm = _enableLlm;
    _initialLlmModelId = _llmModelId;
  }

  void _checkRestartNeeded() {
    _needRestart = _debugMode != _initialDebugMode ||
        _enableLlm != _initialEnableLlm ||
        _llmModelId != _initialLlmModelId;
  }

  Future<void> _applySettings() async {
    await gameConfig.updateConfig(
      debugMode: _debugMode,
      musicVolume: _musicVolume,
      soundEffectVolume: _soundEffectVolume,
      showFps: _showFps,
      enableLlm: _enableLlm,
      llmModelId: _llmModelId.isNotEmpty ? _llmModelId : null,
    );
  }

  Widget _buildRestartHint() {
    return Text(
      ' *${engine.locale('restartRequired')}',
      style: TextStyle(
        color: Colors.orange,
        fontSize: 12.0,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 600.0,
      height: 520.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('settings')),
          actions: [
            CloseButton2(
              onPressed: () {
                Navigator.of(context).maybePop();
              },
            )
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20.0, vertical: 10.0),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // 音乐音量
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 200.0,
                            child: Text('${engine.locale('musicVolume')}: '),
                          ),
                          Expanded(
                            child: fluent.Slider(
                              value: _musicVolume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (value) {
                                setState(() {
                                  _musicVolume = (value * 100).round() / 100.0;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 50.0,
                            child: Text(
                              '${(_musicVolume * 100).round()}%',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 音效音量
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 200.0,
                            child:
                                Text('${engine.locale('soundEffectVolume')}: '),
                          ),
                          Expanded(
                            child: fluent.Slider(
                              value: _soundEffectVolume,
                              min: 0.0,
                              max: 1.0,
                              onChanged: (value) {
                                setState(() {
                                  _soundEffectVolume =
                                      (value * 100).round() / 100.0;
                                });
                              },
                            ),
                          ),
                          SizedBox(
                            width: 50.0,
                            child: Text(
                              '${(_soundEffectVolume * 100).round()}%',
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // 显示FPS
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 200.0,
                            child: Text('${engine.locale('showFps')}: '),
                          ),
                          fluent.Checkbox(
                            content: Text(engine
                                .locale(_showFps ? 'enabled' : 'disabled')),
                            checked: _showFps,
                            onChanged: (bool? value) {
                              setState(() {
                                _showFps = value ?? false;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    // 开发者模式（需重启）
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Row(
                        children: [
                          Container(
                            width: 200.0,
                            padding: const EdgeInsets.only(right: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${engine.locale('debugMode')}: '),
                                _buildRestartHint(),
                              ],
                            ),
                          ),
                          fluent.Checkbox(
                            content: Text(engine
                                .locale(_debugMode ? 'enabled' : 'disabled')),
                            checked: _debugMode,
                            onChanged: (bool? value) {
                              setState(() {
                                _debugMode = value ?? false;
                                _checkRestartNeeded();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 30.0),
                    // 启用LLM（需重启）
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Row(
                        children: [
                          Container(
                            width: 200.0,
                            padding: const EdgeInsets.only(right: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${engine.locale('enableLlm')}: '),
                                _buildRestartHint(),
                              ],
                            ),
                          ),
                          fluent.Checkbox(
                            content: Text(engine
                                .locale(_enableLlm ? 'enabled' : 'disabled')),
                            checked: _enableLlm,
                            onChanged: (bool? value) {
                              setState(() {
                                _enableLlm = value ?? false;
                                _checkRestartNeeded();
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                    // LLM 模型ID（需重启）
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Row(
                        children: [
                          Container(
                            width: 200.0,
                            padding: const EdgeInsets.only(right: 10.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('${engine.locale('llmModelId')}: '),
                                _buildRestartHint(),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 250.0,
                            height: 40.0,
                            child: fluent.TextBox(
                              controller:
                                  TextEditingController(text: _llmModelId),
                              onChanged: (value) {
                                _llmModelId = value.trim();
                                _checkRestartNeeded();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_needRestart)
              Padding(
                padding: const EdgeInsets.only(bottom: 5.0),
                child: Text(
                  engine.locale('hint_restartRequired'),
                  style: TextStyle(color: Colors.orange),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: fluent.Button(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(engine.locale('cancel')),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: fluent.FilledButton(
                      onPressed: () async {
                        await _applySettings();
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(engine.locale('save')),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
