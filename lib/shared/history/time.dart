import '../../engine/game.dart';

enum GameDateTimeFormat {
  dateYearMonthDay,
  dateMonthDay,
  dateDay,
  timeYear,
  timeMonth,
  timeDay,
  ageYearMonthDay,
  ageYear,
}

class GameDateTime {
  static int _getYear(int timestamp) => timestamp ~/ _ticksPerYear;
  static int _getMonth(int timestamp) =>
      (timestamp % _ticksPerYear) ~/ _ticksPerMonth;
  static int _getDay(int timestamp) =>
      (timestamp % _ticksPerMonth) ~/ _ticksPerDay;

  // [format] = 'age' | 'date' | 'time' + 'YMD' | 'YM' | 'MD' | 'D'
  static String _formatString({required int timestamp, String? format}) {
    int yearN = _getYear(timestamp);
    int monthN = _getMonth(timestamp);
    int dayN = _getDay(timestamp);

    final type = format?.split('.').first ?? 'date';
    if (type == 'age') {
      return ' $yearN ${SamsaraGame.texts['date.year']}';
    }

    if (type == 'date') {
      ++yearN;
      ++monthN;
      ++dayN;
    }

    final year = ' $yearN ${SamsaraGame.texts['$type.year']}';
    final month = ' $monthN ${SamsaraGame.texts['$type.month']}';
    final day = ' $dayN ${SamsaraGame.texts['$type.day']}';

    final fmt = format?.split('.').last;
    switch (fmt) {
      case 'y':
        return year;
      case 'm':
        return month;
      case 'd':
        return day;
      case 'ym':
        return '$year$month';
      case 'md':
        return '$month$day';
      case 'ymd':
      default:
        return '$year$month$day';
    }
  }

  static const _ticksPerDay = 4; //每天的回合数 morning, afternoon, evening, night
  static const _daysPerMonth = 30; //每月的天数
  static const _ticksPerMonth = _ticksPerDay * _daysPerMonth; //每月的回合数
  static const _monthsPerYear = 12; //每年的月数
  static const _ticksPerYear =
      _ticksPerDay * _daysPerMonth * _monthsPerYear; //每年的回合数

  static int _now = 0;

  static String get now => _formatString(timestamp: _now);

  static String get currentDate => _formatString(timestamp: _now);
  static int get currentYear => _getYear(_now);
  static int get currentMonth => _getMonth(_now);
  static int get currentDay => _getDay(_now);

  static GameDateTime get oneYear => GameDateTime(_ticksPerYear);
  static GameDateTime get oneMonth => GameDateTime(_ticksPerMonth);
  static GameDateTime get oneDay => GameDateTime(_ticksPerDay);

  static String next() {
    return _formatString(timestamp: _now++);
  }

  int timestamp;

  GameDateTime(this.timestamp);

  operator +(dynamic other) {
    if (other is int) {
      timestamp += other;
    } else if (other is GameDateTime) {
      timestamp += other.timestamp;
    } else {
      throw ('GameDateTime cannot add with \'${other.runtimeType}\'.');
    }
  }

  operator -(dynamic other) {
    if (other is int) {
      timestamp -= other;
    } else if (other is GameDateTime) {
      timestamp -= other.timestamp;
    } else {
      throw ('GameDateTime cannot subtract with \'${other.runtimeType}\'.');
    }
  }

  toDateString() => _formatString(timestamp: timestamp);
  toTimeString() => _formatString(timestamp: timestamp, format: 'time.ymd');
  toAgeString() => _formatString(timestamp: timestamp, format: 'age');
}
