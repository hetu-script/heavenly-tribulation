extension MeaningfulString on DateTime {
  String toMeaningfulString({bool useUnderscore = false}) {
    final sep = useUnderscore ? '' : '_';
    final ymdSep = useUnderscore ? '' : '/';
    final hmsSep = useUnderscore ? '' : ':';
    return '$year$ymdSep${(month).toString().padLeft(2, '0')}$ymdSep${(day).toString().padLeft(2, '0')}$sep'
        '${(hour).toString().padLeft(2, '0')}$hmsSep${(minute).toString().padLeft(2, '0')}';
  }
}
