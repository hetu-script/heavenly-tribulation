extension PercentageString on num {
  String toPercentageString([int fractionDigits = 0]) {
    return (this * 100).toStringAsFixed(fractionDigits).toString() + '%';
  }
}
