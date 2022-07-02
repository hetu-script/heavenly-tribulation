import 'package:flutter/material.dart';

import '../../global.dart';

class DynamicColorProgressBar extends StatelessWidget {
  DynamicColorProgressBar({
    Key? key,
    this.title,
    required this.width,
    this.height,
    required this.value,
    required this.max,
    this.showNumber = true,
    this.showNumberAsPercentage = true,
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

  final double width;

  final double? height;

  final int value, max;

  final bool showNumber, showNumberAsPercentage;

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
    return Row(
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(right: 5.0),
            child: Text(title!),
          ),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white24,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: kForegroundColor),
          ),
          child: Stack(
            alignment: AlignmentDirectional.centerStart,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                width: value / max * width,
                height: height,
                decoration: BoxDecoration(
                  color: _lerpGradient(value / max),
                ),
              ),
              if (showNumber)
                Align(
                  alignment: Alignment.center,
                  child: Text(
                    showNumberAsPercentage
                        ? (value / max).toPercentageString()
                        : '$value/$max',
                    style: const TextStyle(fontSize: 12.0),
                  ),
                )
            ],
          ),
        ),
      ],
    );
  }
}
