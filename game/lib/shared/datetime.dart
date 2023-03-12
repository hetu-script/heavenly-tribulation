extension MeaningfulString on DateTime {
  String toMeaningfulString({bool hasMillisecond = false}) {
    var result =
        '$year/${(month).toString().padLeft(2, '0')}/${(day).toString().padLeft(2, '0')}'
        ' ${(hour).toString().padLeft(2, '0')}:'
        '${(minute).toString().padLeft(2, '0')}:'
        '${(second).toString().padLeft(2, '0')}';
    if (hasMillisecond) {
      result += ' ${(millisecond).toString().padLeft(3, '0')}.'
          '${(microsecond).toString().padLeft(3, '0')}';
    }
    return result;
  }
}
