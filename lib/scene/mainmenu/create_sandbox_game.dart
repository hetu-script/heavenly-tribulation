import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:samsara/extensions.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:fast_noise/fast_noise.dart';
import 'package:hetu_script/utils/crc32b.dart';

import '../../engine.dart';
import '../../game/ui.dart';
import '../../widgets/ui/menu_builder.dart';
import '../../game/common.dart';

const _kWorldScaleLabel = {
  1: 'tiny', // 40 × 20
  2: 'huge', // 72 × 36
  3: 'massive', // 128 × 64
};

const _kNoiseConfigByWorldStyle = {
  'islands': (0.45, 0.3, 6, NoiseType.perlinFractal, 3),
  'coast': (0.55, 0.33, 3.5, NoiseType.valueFractal, 10),
  'inland': (0.65, 0.42, 10, NoiseType.cubicFractal, 3),
};

int _floatToInt8(double x) {
  // return (x * 255.0).round() & 0xff;
  return x.round().clamp(0, 255);
}

/// A 32 bit value representing this color.
///
/// The bits are assigned as follows:
///
/// * Bits 24-31 are the red value.
/// * Bits 16-23 are the blue value.
/// * Bits 8-15 are the green value.
/// * Bits 0-7 are the alpha value.
int getABGR(double a, double b, double g, double r) {
  return _floatToInt8(a) << 24 |
      _floatToInt8(b) << 16 |
      _floatToInt8(g) << 8 |
      _floatToInt8(r) << 0;
}

Future<ui.Image> _makeImage({
  required int width,
  required int height,
  required List<List<double>> noiseData,
  required threshold,
  required double threshold2,
}) async {
  assert(threshold2 < threshold);
  final c = Completer<ui.Image>();
  final pixels = Int32List(width * height);
  for (var x = 0; x < width; ++x) {
    for (var y = 0; y < height; ++y) {
      final noise = noiseData[x][y];
      final normalize = (noise + 1) / 2;
      int abgr = 0;
      if (normalize > threshold) {
        // 海洋
        abgr = getABGR(255, 128, 0, 0);
      } else if (normalize > threshold2) {
        // 陆地
        abgr = getABGR(255, 0, 128, 0);
      } else {
        // 山地
        abgr = getABGR(255, 128, 128, 128);
      }
      pixels[y * width + x] = abgr;
    }
  }
  ui.decodeImageFromPixels(
    pixels.buffer.asUint8List(),
    width,
    height,
    ui.PixelFormat.rgba8888,
    c.complete,
  );
  return c.future;
}

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
  int _worldScale = 1;
  int _worldWidth = 0, _worldHeight = 0;
  late int _locationNumber;
  late int _organizationNumber;
  late int _characterNumber;

  bool _enableTutorial = true;

  late String _worldScaleLabel;

  ui.Image? _image;

  Future<void> makeImage() async {
    final seed = crcInt('${_seedEditingController.text}_$_worldScale');

    _worldWidth = kWorldSizeByScale[_worldScale]!;
    _worldHeight = _worldWidth ~/ 2;
    final dimension = (_worldWidth + _worldHeight) ~/ 2;

    final (threshold, threshold2, frequency, noiseType, octaves) =
        _kNoiseConfigByWorldStyle[_worldStyle]!;
    final noiseData = noise2(
      _worldWidth,
      _worldHeight,
      seed: seed,
      frequency: frequency / dimension,
      noiseType: noiseType,
      octaves: octaves,
    );
    final image = await _makeImage(
      width: _worldWidth,
      height: _worldHeight,
      noiseData: noiseData,
      threshold: threshold,
      threshold2: threshold2,
    );
    setState(() {
      _image = image;
    });
  }

  @override
  void initState() {
    super.initState();

    final entityNumber = kEntityNumberPerWorldScale[_worldScale]!;
    _locationNumber = entityNumber.$1;
    _organizationNumber = entityNumber.$2;
    _characterNumber = entityNumber.$3;

    _worldScaleLabel = engine.locale(_kWorldScaleLabel[_worldScale]!);

    _saveNameEditingController.text = engine.locale('unnamed');
    _seedEditingController.text = 'Hello, world!';

    makeImage();
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                            // 是否开启引导
                            Padding(
                              padding: const EdgeInsets.only(top: 20.0),
                              child: Row(
                                children: [
                                  SizedBox(
                                    width: 120.0,
                                    child: Text(
                                        '${engine.locale('enableTutorial')}: '),
                                  ),
                                  fluent.Checkbox(
                                    content:
                                        Text(engine.locale('enableTutorial')),
                                    checked: _enableTutorial,
                                    onChanged: (bool? value) {
                                      setState(() {
                                        _enableTutorial = value ?? false;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                            // 随机数种子
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                SizedBox(
                                  width: 120.0,
                                  child:
                                      Text('${engine.locale('randomSeed')}: '),
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
                                          math.Random()
                                              .nextInt(1 << 32)
                                              .toString();
                                      makeImage();
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
                                    child: Text(
                                        '${engine.locale('worldStyle')}: '),
                                  ),
                                  fluent.DropDownButton(
                                    title: Text(engine.locale(_worldStyle)),
                                    items: buildFluentMenuItems(
                                      items: {
                                        for (final style in kWorldStyles)
                                          engine.locale(style): style
                                      },
                                      onSelectedItem: (String item) {
                                        _worldStyle = item;
                                        makeImage();
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
                                    child:
                                        Text('${engine.locale('worldSize')}: '),
                                  ),
                                  Slider(
                                    value: _worldScale.toDouble(),
                                    min: 1,
                                    max: 3,
                                    label: _worldScaleLabel,
                                    onChanged: (double value) {
                                      setState(() {
                                        _worldScale = value.toInt();
                                        _worldScaleLabel = engine.locale(
                                            _kWorldScaleLabel[_worldScale]!);
                                        final entityNumber =
                                            kEntityNumberPerWorldScale[
                                                _worldScale]!;
                                        _locationNumber = entityNumber.$1;
                                        _organizationNumber = entityNumber.$2;
                                        _characterNumber = entityNumber.$3;
                                        makeImage();
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
                        Container(
                          padding: const EdgeInsets.only(left: 20.0),
                          child: RawImage(
                            width: _worldWidth.toDouble() * 6,
                            height: _worldHeight.toDouble() * 6,
                            fit: BoxFit.fill,
                            image: _image,
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
                  onPressed: () async {
                    if (_seedEditingController.text.isBlank) {
                      dialog.pushDialog('hint_emptySeed');
                      await dialog.execute();
                      return;
                    }
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
                      'enableTutorial': _enableTutorial,
                    });
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
