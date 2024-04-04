import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:samsara/extensions.dart';

import '../config.dart';
// import '../hash.dart';
import 'create_config.dart';

class CreateSandboxGameDialog extends StatefulWidget {
  static Future<dynamic> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => const CreateSandboxGameDialog(),
    );
  }

  const CreateSandboxGameDialog({super.key});

  @override
  State<CreateSandboxGameDialog> createState() =>
      _CreateSandboxGameDialogState();
}

class _CreateSandboxGameDialogState extends State<CreateSandboxGameDialog> {
  final _saveNameEditingController = TextEditingController();
  final _idEditingController = TextEditingController();
  final _seedEditingController = TextEditingController();
  String _worldStyle = 'coast';
  int _worldScale = 2;
  int _organizationNumber = 6;
  int _locationNumber = 14;
  int _characterNumber = 36;

  late String _worldScaleLabel;

  @override
  void initState() {
    super.initState();
    _worldScaleLabel = engine.locale(kWorldScaleLabel[_worldScale]!);

    _saveNameEditingController.text = engine.locale('unnamed');
    _idEditingController.text = 'main';
    _seedEditingController.text = 'Hello, world!';
  }

  @override
  Widget build(BuildContext context) {
    final organizationNumberMax = math.min(_locationNumber, _characterNumber);
    if (_organizationNumber > organizationNumberMax) {
      _organizationNumber = organizationNumberMax;
    }
    final newLocationNumberMax = kMaxLocationNumberPerWorldScale[_worldScale]!;
    if (_locationNumber > newLocationNumberMax) {
      _locationNumber = newLocationNumberMax;
    }

    // final layout =

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(engine.locale('sandboxMode')),
        // actions: const [CloseButton()],
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
                    child: Wrap(
                      alignment: WrapAlignment.start,
                      children: [
                        SizedBox(
                          width: 350,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100.0,
                                child: Text('${engine.locale('fileName')}: '),
                              ),
                              SizedBox(
                                width: 150.0,
                                child: TextField(
                                  controller: _saveNameEditingController,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 350,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100.0,
                                child: Text('${engine.locale('worldId')}: '),
                              ),
                              SizedBox(
                                width: 150.0,
                                child: TextField(
                                  controller: _idEditingController,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 随机数种子
                        SizedBox(
                          width: 350,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100.0,
                                child: Text('${engine.locale('randomSeed')}: '),
                              ),
                              SizedBox(
                                width: 150.0,
                                child: TextField(
                                  controller: _seedEditingController,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _seedEditingController.text = math.Random()
                                        .nextInt(1 << 32)
                                        .toString();
                                  },
                                  child: Text(engine.locale('random')),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 地图风格
                        SizedBox(
                          width: 350,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 100.0,
                                child: Text('${engine.locale('worldStyle')}: '),
                              ),
                              DropdownButton<String>(
                                items: <String>['islands', 'coast', 'inland']
                                    .map((String value) =>
                                        DropdownMenuItem<String>(
                                          value: value,
                                          child: Text(engine.locale(value)),
                                        ))
                                    .toList(),
                                value: _worldStyle,
                                onChanged: (value) {
                                  setState(() {
                                    _worldStyle = value!;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                        // world size
                        SizedBox(
                          width: 350,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70.0,
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
                                    final newLocationNumberMax =
                                        kMaxLocationNumberPerWorldScale[
                                            _worldScale]!;
                                    if (_locationNumber >
                                        newLocationNumberMax) {
                                      _locationNumber = newLocationNumberMax;
                                    }
                                    final organizationNumberMax = math.min(
                                        _locationNumber, _characterNumber);
                                    if (_organizationNumber >
                                        organizationNumberMax) {
                                      _organizationNumber =
                                          organizationNumberMax;
                                    }
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
                        SizedBox(
                          width: 350,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70.0,
                                child: Text(
                                    '${engine.locale('organizationNumber')}: '),
                              ),
                              Slider(
                                value: _organizationNumber.toDouble(),
                                min: 1,
                                max: organizationNumberMax.toDouble(),
                                label: _organizationNumber.toString(),
                                onChanged: (double value) {
                                  setState(() {
                                    _organizationNumber = value.toInt();
                                  });
                                },
                              ),
                              SizedBox(
                                width: 40.0,
                                child: Text(_organizationNumber.toString()),
                              ),
                            ],
                          ),
                        ),
                        // location number
                        SizedBox(
                          width: 350,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70.0,
                                child: Text(
                                    '${engine.locale('locationNumber')}: '),
                              ),
                              Slider(
                                value: _locationNumber.toDouble(),
                                min: 1,
                                max: newLocationNumberMax.toDouble(),
                                label: _locationNumber.toString(),
                                onChanged: (double value) {
                                  setState(() {
                                    _locationNumber = value.toInt();
                                    final organizationNumberMax = math.min(
                                        _locationNumber, _characterNumber);
                                    if (_organizationNumber >
                                        organizationNumberMax) {
                                      _organizationNumber =
                                          organizationNumberMax;
                                    }
                                  });
                                },
                              ),
                              SizedBox(
                                width: 40.0,
                                child: Text(_locationNumber.toString()),
                              ),
                            ],
                          ),
                        ),
                        // character number
                        SizedBox(
                          width: 350,
                          child: Row(
                            children: [
                              SizedBox(
                                width: 70.0,
                                child: Text(
                                    '${engine.locale('characterNumber')}: '),
                              ),
                              Slider(
                                value: _characterNumber.toDouble(),
                                min: 1,
                                max: 800,
                                label: _characterNumber.toString(),
                                onChanged: (double value) {
                                  setState(() {
                                    _characterNumber = value.toInt();
                                    final organizationNumberMax = math.min(
                                        _locationNumber, _characterNumber);
                                    if (_organizationNumber >
                                        organizationNumberMax) {
                                      _organizationNumber =
                                          organizationNumberMax;
                                    }
                                  });
                                },
                              ),
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
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(engine.locale('cancel')),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: ElevatedButton(
                  onPressed: () {
                    if (_seedEditingController.text.isNotEmpty) {
                      Navigator.of(context).pop({
                        'id': 'main',
                        'method': 'generate',
                        'isMainWorld': true,
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

    // return ResponsiveWindow(
    //   alignment: AlignmentDirectional.center,
    //   child: layout,
    // );
  }
}
