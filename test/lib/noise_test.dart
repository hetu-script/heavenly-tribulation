import 'dart:ui' as ui;
import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:fast_noise/fast_noise.dart';

int _floatToInt8(double x) {
  return (x * 255.0).round() & 0xff;
}

/// A 32 bit value representing this color.
///
/// The bits are assigned as follows:
///
/// * Bits 24-31 are the alpha value.
/// * Bits 16-23 are the red value.
/// * Bits 8-15 are the green value.
/// * Bits 0-7 are the blue value.
int getARGB(double a, double r, double g, double b) {
  return _floatToInt8((a / 255)) << 24 |
      _floatToInt8(r) << 16 |
      _floatToInt8(g) << 8 |
      _floatToInt8(b) << 0;
}

int getABGR(double a, double b, double g, double r) {
  return _floatToInt8((a / 255)) << 24 |
      _floatToInt8(b) << 16 |
      _floatToInt8(g) << 8 |
      _floatToInt8(r) << 0;
}

// int ARGBToABGR(int argbColor) {
//   int r = (argbColor >> 16) & 0xFF;
//   int b = argbColor & 0xFF;
//   return (argbColor & 0xFF00FF00) | (b << 16) | r;
// }

Future<ui.Image> makeImage(List<List<double>> noiseData) {
  final dimension = noiseData.length;
  final c = Completer<ui.Image>();
  final pixels = Int32List(dimension * dimension);
  for (var x = 0; x < dimension; ++x) {
    for (var y = 0; y < dimension; ++y) {
      final noise = noiseData[x][y];
      final normalize = (noise + 1) / 2;
      // 群岛 islands：normalize > 0.55，frequency： 6 /, type: PerlinFractal
      // 滨海 coast：normalize > 0.48，frequency： 3.5 /, type: CubicFractal
      // 内陆 inland：normalize > 0.35，frequency： 6 /, type: CubicFractal
      final alpha = normalize > 0.48 ? 255 : 0;
      final abgr = getABGR(alpha.toDouble(), 0, 0, 0);
      pixels[y * dimension + x] = abgr;
    }
  }
  ui.decodeImageFromPixels(
    pixels.buffer.asUint8List(),
    dimension,
    dimension,
    ui.PixelFormat.rgba8888,
    c.complete,
  );
  return c.future;
}

class NoiseTest extends StatelessWidget {
  const NoiseTest({super.key});

  @override
  Widget build(BuildContext context) {
    const size = Size(512, 512);
    const dimension = 50;
    final noiseData = noise2(
      dimension,
      dimension,
      seed: math.Random().nextInt(1 << 32),
      frequency: 3.5 / dimension,
      noiseType: NoiseType.cubicFractal,
    );

    return Center(
      child: SizedBox(
        width: size.width,
        height: size.height,
        child: Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: const Text('Noise Test'),
          ),
          body: FutureBuilder<ui.Image>(
            future: makeImage(noiseData),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Center(
                  child: RawImage(
                    width: 400,
                    height: 400,
                    fit: BoxFit.fill,
                    image: snapshot.data,
                  ),
                );
              } else {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }
            },
          ),

          //  CustomPaint(
          //   size: size,
          //   painter: NoisePainter(data: noiseData),
          // ),
        ),
      ),
    );
  }
}
