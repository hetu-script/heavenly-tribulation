import 'package:flutter/material.dart';

import '../../global.dart';

class DynamicColorProgressBar extends StatelessWidget {
  DynamicColorProgressBar({
    Key? key,
    this.title,
    this.margin = const EdgeInsets.all(2.0),
    required this.size,
    required this.value,
    this.begin = Alignment.centerLeft,
    this.end = Alignment.centerRight,
    required this.colors,
    List<double>? stops,
    this.borderRadius = 2.5,
  })  : assert(colors.length > 1),
        super(key: key) {
    if (stops == null) {
      final s = <double>[];
      final d = 1.0 / (colors.length - 1);
      for (var i = 0; i < colors.length; ++i) {
        s.add(i * d);
      }
      s.last = 1.0;
      this.stops = s;
    }
  }

  final String? title;

  final EdgeInsets margin;

  final Size size;

  final double value;

  final AlignmentGeometry begin;

  final AlignmentGeometry end;

  final List<Color> colors;

  late final List<double> stops;

  final double borderRadius;

  Color _lerpGradient(double t) {
    for (var s = 0; s < stops.length - 1; s++) {
      final leftStop = stops[s], rightStop = stops[s + 1];
      final leftColor = colors[s], rightColor = colors[s + 1];
      if (t <= leftStop) {
        return leftColor;
      } else if (t < rightStop) {
        final sectionT = (t - leftStop) / (rightStop - leftStop);
        return Color.lerp(leftColor, rightColor, sectionT)!;
      }
    }
    return colors.last;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: Row(
        children: [
          if (title != null) Text(title!),
          Expanded(
            child: Container(
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(borderRadius),
                border: Border.all(color: kForegroundColor),
              ),
              child: Stack(
                children: [
                  Container(
                    width: value * size.width,
                    height: size.height,
                    decoration: BoxDecoration(
                      color: _lerpGradient(value),
                    ),
                  ),
                  Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.only(right: 5.0),
                    child: Text(value.toPercentageString()),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
