import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:samsara/extensions.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../game/ui.dart';
import '../../widgets/ui/menu_builder.dart';

const kWorldStyles = {'coast', 'islands', 'inland'};

const kWorldScaleLabel = {
  1: 'tiny', // 24×12
  2: 'medium', // 40×20
  3: 'huge', // 64×32
  4: 'massive', // 96×48
};

/// 保存了据点数量，门派数量和人物数量
const kEnittyNumberPerWorldScale = {
  1: (10, 6, 24),
  2: (16, 10, 36),
  3: (24, 16, 48),
  4: (36, 24, 64),
};

/// 返回一个用于创建世界场景的 Map 对象参数
/// Map 格式如下
/// {
///   'id': 'main',
///   'method': 'generate',
///   'isMain': true,
///   'saveName': 'save_file_name',
///   'seedString': 'hello world!',
///   'style': _worldStyle, // 'islands', 'coast', 'inland'
///   'worldScale': _worldScale, // 1-4 integer
///   'nationNumber': _organizationNumber, // integer
///   'locationNumber': _locationNumber, // integer
///   'characterNumber': _characterNumber,
/// }
class CreateSandboxGameDialog extends StatefulWidget {
  const CreateSandboxGameDialog({super.key});

  @override
  State<CreateSandboxGameDialog> createState() =>
      _CreateSandboxGameDialogState();
}

class _CreateSandboxGameDialogState extends State<CreateSandboxGameDialog> {
  final _saveNameEditingController = TextEditingController();
  final _seedEditingController = TextEditingController();

  String _worldStyle = 'coast';
  int _worldScale = 2;
  int _locationNumber = 16;
  int _organizationNumber = 10;
  int _characterNumber = 36;

  late String _worldScaleLabel;

  @override
  void initState() {
    super.initState();
    _worldScaleLabel = engine.locale(kWorldScaleLabel[_worldScale]!);

    _saveNameEditingController.text = engine.locale('unnamed');
    _seedEditingController.text = 'Hello, world!';
  }

  @override
  void dispose() {
    super.dispose();

    _saveNameEditingController.dispose();
    _seedEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final layout =

    return Scaffold(
      backgroundColor: GameUI.backgroundColor2,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(engine.locale('sandboxMode')),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: ListView(
                shrinkWrap: true,
                children: [
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40.0),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 120.0,
                              child: Text('${engine.locale('fileName')}: '),
                            ),
                            SizedBox(
                              width: 150.0,
                              height: 40.0,
                              child: TextField(
                                controller: _saveNameEditingController,
                              ),
                            ),
                          ],
                        ),
                        // 随机数种子
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            SizedBox(
                              width: 120.0,
                              child: Text('${engine.locale('randomSeed')}: '),
                            ),
                            SizedBox(
                              width: 150.0,
                              child: TextField(
                                controller: _seedEditingController,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: fluent.FilledButton(
                                onPressed: () {
                                  _seedEditingController.text =
                                      math.Random().nextInt(1 << 32).toString();
                                },
                                child: Text(engine.locale('random')),
                              ),
                            ),
                          ],
                        ),
                        // 地图风格
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              SizedBox(
                                width: 120.0,
                                child: Text('${engine.locale('worldStyle')}: '),
                              ),
                              fluent.DropDownButton(
                                title: Text(engine.locale(_worldStyle)),
                                items: buildFluentMenuItems(
                                  items: {
                                    for (final style in kWorldStyles)
                                      engine.locale(style): style
                                  },
                                  onSelectedItem: (String item) {
                                    setState(() {
                                      _worldStyle = item;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                        // world size
                        Padding(
                          padding: const EdgeInsets.only(top: 10.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100.0,
                                child: Text('${engine.locale('worldSize')}: '),
                              ),
                              Slider(
                                value: _worldScale.toDouble(),
                                min: 1,
                                max: 4,
                                label: _worldScaleLabel,
                                onChanged: (double value) {
                                  setState(() {
                                    _worldScale = value.toInt();
                                    _worldScaleLabel = engine
                                        .locale(kWorldScaleLabel[_worldScale]!);
                                    final entityNumber =
                                        kEnittyNumberPerWorldScale[
                                            _worldScale]!;
                                    _locationNumber = entityNumber.$1;
                                    _organizationNumber = entityNumber.$2;
                                    _characterNumber = entityNumber.$3;
                                  });
                                },
                              ),
                              SizedBox(
                                width: 40.0,
                                child: Text(_worldScaleLabel),
                              ),
                            ],
                          ),
                        ),
                        // nation number
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100.0,
                                child: Text(
                                    '${engine.locale('organizationNumber')}: '),
                              ),
                              // Slider(
                              //   value: _organizationNumber.toDouble(),
                              //   min: 1,
                              //   max: organizationNumberMax.toDouble(),
                              //   label: _organizationNumber.toString(),
                              //   onChanged: (double value) {
                              //     setState(() {
                              //       _organizationNumber = value.toInt();
                              //     });
                              //   },
                              // ),
                              SizedBox(
                                width: 40.0,
                                child: Text(_organizationNumber.toString()),
                              ),
                            ],
                          ),
                        ),
                        // location number
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100.0,
                                child: Text(
                                    '${engine.locale('locationNumber')}: '),
                              ),
                              // Slider(
                              //   value: _locationNumber.toDouble(),
                              //   min: 1,
                              //   max: newLocationNumberMax.toDouble(),
                              //   label: _locationNumber.toString(),
                              //   onChanged: (double value) {
                              //     setState(() {
                              //       _locationNumber = value.toInt();
                              //       final organizationNumberMax = math.min(
                              //           _locationNumber, _characterNumber);
                              //       if (_organizationNumber >
                              //           organizationNumberMax) {
                              //         _organizationNumber = organizationNumberMax;
                              //       }
                              //     });
                              //   },
                              // ),
                              SizedBox(
                                width: 40.0,
                                child: Text(_locationNumber.toString()),
                              ),
                            ],
                          ),
                        ),
                        // character number
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100.0,
                                child: Text(
                                    '${engine.locale('characterNumber')}: '),
                              ),
                              // Slider(
                              //   value: _characterNumber.toDouble(),
                              //   min: 1,
                              //   max: 800,
                              //   label: _characterNumber.toString(),
                              //   onChanged: (double value) {
                              //     setState(() {
                              //       _characterNumber = value.toInt();
                              //       final organizationNumberMax = math.min(
                              //           _locationNumber, _characterNumber);
                              //       if (_organizationNumber >
                              //           organizationNumberMax) {
                              //         _organizationNumber = organizationNumberMax;
                              //       }
                              //     });
                              //   },
                              // ),
                              SizedBox(
                                width: 40.0,
                                child: Text(_characterNumber.toString()),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: fluent.FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(engine.locale('cancel')),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: fluent.FilledButton(
                  onPressed: () {
                    if (_seedEditingController.text.isNotEmpty) {
                      Navigator.of(context).pop({
                        'id': 'sandboxWorld',
                        'method': 'generate',
                        'saveName': _saveNameEditingController.text.isNotBlank
                            ? _saveNameEditingController.text
                            : null,
                        'seedString': _seedEditingController.text.isNotBlank
                            ? _seedEditingController.text
                            : null,
                        'style': _worldStyle,
                        'worldScale': _worldScale,
                        'nationNumber': _organizationNumber,
                        'locationNumber': _locationNumber,
                        'characterNumber': _characterNumber,
                      });
                    } else {
                      // TODO: 创建游戏错误提示对话
                    }
                  },
                  child: Text(engine.locale('continue')),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // return ResponsiveView(
    //   alignment: AlignmentDirectional.center,
    //   child: layout,
    // );
  }
}
