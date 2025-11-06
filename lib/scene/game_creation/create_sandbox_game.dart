import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:samsara/extensions.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:fast_noise/fast_noise.dart';
import 'package:hetu_script/utils/crc32b.dart';

import '../../global.dart';
import '../../data/common.dart';
import '../../widgets/ui/close_button2.dart';
import '../../widgets/ui/responsive_view.dart';
import '../../extensions.dart';

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
///   'nationNumber': _sectNumber, // integer
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
  static final random = math.Random();

  final _saveNameEditingController = TextEditingController();
  final _seedEditingController = TextEditingController();

  String _worldStyle = 'coast';
  String _worldScaleLabel = 'tiny';
  int _worldScale = 1;
  int _worldWidth = 0, _worldHeight = 0;
  late int _locationNumber;
  late int _sectNumber;
  late int _characterNumber;
  late int _seed;

  bool _enableTutorial = true;

  ui.Image? _image;

  final Map<int, ui.Image> _imageCache = {};

  bool get needConfirmed => _seedToBeConfirmed != null;
  String? _seedToBeConfirmed;

  @override
  void dispose() {
    super.dispose();

    _saveNameEditingController.dispose();
    _seedEditingController.dispose();

    _imageCache.clear();
  }

  void applyAllConfig() {
    _worldScale = kWorldLabelToScale[_worldScaleLabel]!;
    final entityNumber = kEntityNumberPerWorldScale[_worldScale]!;
    _locationNumber = entityNumber.$1;
    _sectNumber = entityNumber.$2;
    _characterNumber = entityNumber.$3;

    _worldScale = kWorldLabelToScale[_worldScaleLabel]!;
    _worldWidth = kWorldWidthByScale[_worldScale]!;
    _worldHeight = _worldWidth ~/ 2;
    _seed = crcInt(
        '${_seedEditingController.text}$_worldStyle$_worldWidth$_worldHeight');
  }

  Future<void> makeImage() async {
    if (_imageCache[_seed] != null) {
      _image = _imageCache[_seed]!;
      setState(() {});
      return;
    }

    final dimension = (_worldWidth + _worldHeight) ~/ 2;

    final (threshold, threshold2, frequency, noiseType, octaves) =
        kNoiseConfigByWorldStyle[_worldStyle]!;
    final noiseData = noise2(
      _worldWidth,
      _worldHeight,
      seed: _seed,
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
    _image = _imageCache[_seed] = image;
    setState(() {});
  }

  @override
  void initState() {
    super.initState();

    _saveNameEditingController.text = engine.locale('unnamed');
    _seedEditingController.text = 'Hello, World!';

    applyAllConfig();
    makeImage();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 1000.0,
      height: 600.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('sandboxMode')),
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 600.0,
                  height: 420.0,
                  padding: const EdgeInsets.only(left: 20.0),
                  child: SingleChildScrollView(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        Row(
                          children: [
                            SizedBox(
                              width: 120.0,
                              child: Text('${engine.locale('saveName')}: '),
                            ),
                            SizedBox(
                              width: 150.0,
                              height: 40.0,
                              child: fluent.TextBox(
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
                                child: Text('${engine.locale('tutorial')}: '),
                              ),
                              fluent.Checkbox(
                                content: Text(engine.locale(
                                    _enableTutorial ? 'enabled' : 'disabled')),
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
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 120.0,
                                child: Text('${engine.locale('randomSeed')}: '),
                              ),
                              SizedBox(
                                width: 150.0,
                                height: 40.0,
                                child: fluent.TextBox(
                                  controller: _seedEditingController,
                                  onChanged: (value) {
                                    final trimed = value.trim();
                                    if (trimed.isNotBlank) {
                                      _seedToBeConfirmed = trimed;
                                      setState(() {});
                                    }
                                  },
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 5.0),
                                child: fluent.Button(
                                  onPressed: () async {
                                    if (needConfirmed) {
                                      _seedEditingController.text =
                                          _seedToBeConfirmed!;
                                      _seed = crcInt(
                                          '$_seedToBeConfirmed$_worldStyle$_worldWidth$_worldHeight');
                                      _seedToBeConfirmed = null;
                                      await makeImage();
                                    } else {
                                      _seedEditingController.text =
                                          random.nextInt(1 << 32).toString();
                                      _seed = crcInt(
                                          '${_seedEditingController.text}$_worldStyle$_worldWidth$_worldHeight');
                                      await makeImage();
                                    }
                                    setState(() {});
                                  },
                                  child: Text(
                                    engine.locale(
                                        needConfirmed ? 'confirm' : 'random'),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // 地图风格
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 120.0,
                                child: Text('${engine.locale('worldStyle')}: '),
                              ),
                              fluent.ComboBox<String>(
                                value: _worldStyle,
                                items: kWorldStyles.map((e) {
                                  return fluent.ComboBoxItem(
                                    value: e,
                                    child: Text(engine.locale(e)),
                                  );
                                }).toList(),
                                onChanged: (value) async {
                                  if (value == null) return;
                                  _worldStyle = value;
                                  _seed = crcInt(
                                      '${_seedEditingController.text}$_worldStyle$_worldWidth$_worldHeight');
                                  await makeImage();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                        // world size
                        Padding(
                          padding: const EdgeInsets.only(top: 20.0),
                          child: Row(
                            children: [
                              SizedBox(
                                width: 120.0,
                                child: Text('${engine.locale('worldSize')}: '),
                              ),
                              fluent.ComboBox<String>(
                                value: _worldScaleLabel,
                                items: kWorldLabelToScale.keys.map((e) {
                                  return fluent.ComboBoxItem(
                                    value: e,
                                    child: Text(engine.locale(e)),
                                  );
                                }).toList(),
                                onChanged: (value) async {
                                  if (value == null) return;
                                  _worldScaleLabel = value;
                                  applyAllConfig();
                                  await makeImage();
                                  setState(() {});
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 320.0,
                  height: 320.0,
                  padding: const EdgeInsets.only(top: 20.0, right: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: RawImage(
                          fit: BoxFit.fill,
                          image: _image,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20.0, left: 5.0, right: 5.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120.0,
                              child: Text('${engine.locale('sectNumber')}: '),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 40.0,
                              child: Text(
                                '$_sectNumber',
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20.0, left: 5.0, right: 5.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120.0,
                              child: Text('${engine.locale('cityNumber')}: '),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 40.0,
                              child: Text(
                                '$_locationNumber',
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(
                            top: 20.0, left: 5.0, right: 5.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 120.0,
                              child:
                                  Text('${engine.locale('characterNumber')}: '),
                            ),
                            const Spacer(),
                            SizedBox(
                              width: 40.0,
                              child: Text(
                                '~$_characterNumber',
                                textAlign: TextAlign.right,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: fluent.Button(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text(engine.locale('cancel')),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: fluent.Button(
                    onPressed: () async {
                      if (_seedEditingController.text.isBlank) {
                        dialog.pushDialog('hint_emptySeed');
                        dialog.execute();
                        return;
                      }
                      applyAllConfig();
                      Navigator.of(context).pop({
                        'id': 'sandboxWorld',
                        'method': 'generate',
                        'saveName': _saveNameEditingController.text.isNotBlank
                            ? _saveNameEditingController.text
                            : null,
                        'seed': _seed,
                        'style': _worldStyle,
                        'width': _worldWidth,
                        'height': _worldHeight,
                        'nationNumber': _sectNumber,
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
      ),
    );
  }
}
