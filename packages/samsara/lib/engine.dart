import 'package:flutter/material.dart';

import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/value/struct/struct.dart';
// import 'package:hetu_script_flutter/hetu_script_flutter.dart';

import 'binding/scene/component/game_map_binding.dart';
import 'binding/game_binding.dart';
import 'scene/scene.dart';
import '../event/event.dart';
import '../event/events.dart';
import '../shared/localization.dart';
import '../shared/color.dart';
import 'scene/scene_controller.dart';

class SamsaraEngine with SceneController, EventAggregator {
  final locale = GameLocalization();

  void updateLocales(HTStruct data) {
    locale.loadData(data);
  }

  Map<int, Color> zoneColors = {};

  void updateZoneColors(Map data) {
    zoneColors.clear();
    zoneColors.addAll(
        data.map((key, value) => MapEntry(key, HexColor.fromHex(value))));
  }

  Map<String, Color> nationColors = {};

  void updateNationColors(Map data) {
    nationColors.clear();
    nationColors.addAll(
        data.map((key, value) => MapEntry(key, HexColor.fromHex(value))));
  }

  void onIncident(HTStruct data) {
    broadcast(HistoryEvent.occurred(data: data));
  }

  late final Hetu hetu;
  bool isLoaded = false;

  invoke(String funcName,
          {String? moduleName,
          List<dynamic> positionalArgs = const [],
          Map<String, dynamic> namedArgs = const {},
          List<HTType> typeArgs = const []}) =>
      hetu.interpreter.invoke(funcName,
          moduleName: moduleName,
          positionalArgs: positionalArgs,
          namedArgs: namedArgs,
          typeArgs: typeArgs);

  /// Initialize the engine, must be called within
  /// the initState() of Flutter widget,
  /// for accessing the assets bundle resources.
  Future<void> init(
      {Map<String, Function> externalFunctions = const {}}) async {
    // const root = 'scripts/';
    // final filterConfig = HTFilterConfig(root, extension: [
    //   HTResource.hetuModule,
    //   HTResource.hetuScript,
    //   HTResource.json,
    // ]);
    // final sourceContext = HTAssetResourceContext(
    //     root: root,
    //     includedFilter: [filterConfig],
    //     expressionModuleExtensions: [HTResource.json]);
    hetu = Hetu(
      config: HetuConfig(
        allowImplicitNullToZeroConversion: true,
        allowImplicitEmptyValueToFalseConversion: true,
      ),
    );
    // sourceContext: sourceContext);
    hetu.init(
      externalFunctions: externalFunctions,
      externalClasses: [
        SamsaraEngineClassBinding(),
        MapComponentClassBinding(),
      ],
    );
    // await hetu.initFlutter(
    //   externalFunctions: externalFunctions,
    //   externalClasses: [
    //     SamsaraEngineClassBinding(),
    //     MapComponentClassBinding(),
    //   ],
    // );
  }

  @override
  Future<Scene> createScene(String key, [String? args]) async {
    final scene = await super.createScene(key, args);
    broadcast(SceneEvent.created(sceneKey: key));
    return scene;
  }

  @override
  void leaveScene(String key) {
    super.leaveScene(key);
    broadcast(SceneEvent.ended(sceneKey: key));
  }

  static int getYear(int timestamp) => timestamp ~/ _ticksPerYear;
  static int getMonth(int timestamp) =>
      (timestamp % _ticksPerYear) ~/ _ticksPerMonth;
  static int getDay(int timestamp) =>
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
}
