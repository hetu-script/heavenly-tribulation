import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script_flutter/hetu_script_flutter.dart';

import '../binding/external_game_functions.dart';
import '../binding/engine/scene/component/game_map_binding.dart';
import '../binding/engine/game_binding.dart';
import 'scene/scene.dart';
import 'event/event.dart';
import '../shared/localization.dart';

class SamsaraGame with SceneController, EventAggregator {
  final locale = GameLocalization();

  void updateLanguagesData(Map<String, dynamic> data) {
    locale.data.clear();
    locale.data.addAll(data);
  }

  late final Hetu hetu;
  bool _isLoaded = false;
  bool get isLoaded => _isLoaded;

  Future<void> init() async {
    const root = 'scripts/';
    final filterConfig = HTFilterConfig(root, extension: [
      HTResource.hetuModule,
      HTResource.hetuScript,
      HTResource.json,
    ]);
    final sourceContext = HTAssetResourceContext(
        root: root,
        includedFilter: [filterConfig],
        expressionModuleExtensions: [HTResource.json]);
    hetu = Hetu(sourceContext: sourceContext);
    await hetu.initFlutter(
      externalFunctions: externalGameFunctions,
      externalClasses: [
        SamsaraGameClassBinding(),
        MapComponentClassBinding(),
      ],
    );
    hetu.evalFile('game/main.ht',
        moduleName: 'game:main',
        globallyImport: true,
        invokeFunc: 'init',
        namedArgs: {'lang': 'zh', 'dartGame': this});
    _isLoaded = true;
  }

  @override
  Future<Scene> createScene(String name) async {
    final Scene scene = await super.createScene(name);
    broadcast(SceneEvent.started(sceneKey: scene.key));
    return scene;
  }

  static int _getYear(int timestamp) => timestamp ~/ _ticksPerYear;
  static int _getMonth(int timestamp) =>
      (timestamp % _ticksPerYear) ~/ _ticksPerMonth;
  static int _getDay(int timestamp) =>
      (timestamp % _ticksPerMonth) ~/ _ticksPerDay;

  static const _ticksPerDay = 4; //每天的回合数 morning, afternoon, evening, night
  static const _daysPerMonth = 30; //每月的天数
  static const _ticksPerMonth = _ticksPerDay * _daysPerMonth; //每月的回合数 120
  static const _monthsPerYear = 12; //每年的月数
  static const _ticksPerYear =
      _ticksPerDay * _daysPerMonth * _monthsPerYear; //每年的回合数 1440

  static int get oneYear => _ticksPerYear;
  static int get oneMonth => _ticksPerMonth;
  static int get oneDay => _ticksPerDay;

  // [format] = 'age' | 'date' | 'time' + 'YMD' | 'YM' | 'MD' | 'D'
  String _formatString({required int timestamp, String? format}) {
    int yearN = _getYear(timestamp);
    int monthN = _getMonth(timestamp);
    int dayN = _getDay(timestamp);

    final type = format?.split('.').first ?? 'date';
    if (type == 'age') {
      return ' $yearN ${locale['date.year']}';
    }

    if (type == 'date') {
      ++yearN;
      ++monthN;
      ++dayN;
    }

    final year = ' $yearN ${locale['$type.year']}';
    final month = ' $monthN ${locale['$type.month']}';
    final day = ' $dayN ${locale['$type.day']}';

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

  int _now = 0;

  String next() {
    return _formatString(timestamp: _now++);
  }

  int get now => _now;
  String get currentDate => _formatString(timestamp: _now);
  int get currentYear => _getYear(_now);
  int get currentMonth => _getMonth(_now);
  int get currentDay => _getDay(_now);

  formatDateString(int timestamp) => _formatString(timestamp: timestamp);
  formatTimeString(int timestamp) =>
      _formatString(timestamp: timestamp, format: 'time.ymd');
  formatAgeString(int timestamp) =>
      _formatString(timestamp: timestamp, format: 'age');
}
