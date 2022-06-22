import 'dart:isolate';
import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:hetu_script/value/struct/struct.dart';
import 'package:hetu_script_flutter/hetu_script_flutter.dart';

import 'binding/scene/component/game_map_binding.dart';
import 'binding/game_binding.dart';
import 'scene/scene.dart';
import '../event/event.dart';
import '../event/events.dart';
import 'localization.dart';
import '../shared/color.dart';
import 'scene/scene_controller.dart';
import 'logger/printer.dart';
import 'logger/output.dart';

class SamsaraEngine with SceneController, EventAggregator {
  final bool debugMode;

  final CustomLoggerPrinter _loggerPrinter = CustomLoggerPrinter();
  final CustomLoggerOutput _loggerOutput = CustomLoggerOutput();

  late final Logger logger;

  final locale = GameLocalization();

  Map<int, Color> zoneColors = {};
  Map<String, Color> nationColors = {};

  final _receivePort = ReceivePort();

  // Convert the ReceivePort into a StreamQueue to receive messages from the
  // spawned isolate using a pull-based interface. Events are stored in this
  // queue until they are accessed by `events.next`.
  late final StreamQueue<dynamic> _isolateEvents;

  late final SendPort _sendPort;

  SamsaraEngine({required this.debugMode}) {
    _isolateEvents = StreamQueue<dynamic>(_receivePort);
    logger = Logger(
      filter: null,
      printer: _loggerPrinter,
      output: _loggerOutput,
    );
  }

  void updateLocales(HTStruct data) {
    locale.loadData(data);
  }

  void updateZoneColors(Map data) {
    zoneColors.clear();
    zoneColors.addAll(
        data.map((key, value) => MapEntry(key, HexColor.fromHex(value))));
  }

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

  /// Spawns an isolate and asynchronously invoke hetu funcitons in the script environment.
  ///
  /// Waits for the response before sending the next.
  ///
  /// Returns a stream that emits the JSON-decoded contents of each file.
  void init({Map<String, Function> externalFunctions = const {}}) async {
    await Isolate.spawn(_handleScriptInvocation, _receivePort.sendPort);

    // The first message from the spawned isolate is a SendPort. This port is
    // used to communicate with the spawned isolate.
    _sendPort = await _isolateEvents.next;
  }

  void close() async {
    // Send a signal to the spawned isolate indicating that it should exit.
    _sendPort.send(null);

    // Dispose the StreamQueue.
    await _isolateEvents.cancel();
  }

  dynamic invoke(String funcName,
      {String? moduleName,
      List<dynamic> positionalArgs = const [],
      Map<String, dynamic> namedArgs = const {},
      List<HTType> typeArgs = const []}) async {
    if (!isLoaded) throw 'Engine is not initialized yet!';
    // Send the next filename to be read and parsed
    _sendPort.send({
      "funcName": funcName,
      "moduleName": moduleName,
      "positionalArgs": positionalArgs,
      "namedArgs": namedArgs,
      "typeArgs": typeArgs
    });

    // Receive the parsed JSON
    Map<String, dynamic> message = await _isolateEvents.next;

    // Add the result to the stream returned by this async* function.
    message;
  }

  // The entrypoint that runs on the spawned isolate. Receives messages from
  // the main isolate, reads the contents of the file, decodes the JSON, and
  // sends the result back to the main isolate.
  Future<void> _handleScriptInvocation(SendPort port) async {
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
    hetu = Hetu(
      config: HetuConfig(
        showHetuStackTrace: true,
        allowImplicitNullToZeroConversion: true,
        allowImplicitEmptyValueToFalseConversion: true,
      ),
      sourceContext: sourceContext,
    );
    await hetu.initFlutter(
      locale: HTLocaleSimplifiedChinese(),
      // externalFunctions: externalFunctions,
      externalClasses: [
        SamsaraEngineClassBinding(),
        MapComponentClassBinding(),
      ],
    );

    // Send a SendPort to the main isolate so that it can send JSON strings to
    // this isolate.
    final commandPort = ReceivePort();
    port.send(commandPort.sendPort);

    // Wait for messages from the main isolate.
    await for (final message in commandPort) {
      if (message is Map) {
        final result = hetu.interpreter.invoke(message['funcName'],
            moduleName: message['moduleName'],
            positionalArgs: message['positionalArgs'],
            namedArgs: message['namedArgs'],
            typeArgs: message['typeArgs']);

        // Send the result to the main isolate.
        port.send(result);
      } else if (message == null) {
        // Exit if the main isolate sends a null message, indicating there are no
        // more files to read and parse.
        break;
      }
    }

    Isolate.exit();
  }

  // Future<void> init(
  //     {Map<String, Function> externalFunctions = const {}}) async {
  //   if (debugMode) {
  //     const root = 'scripts/';
  //     final filterConfig = HTFilterConfig(root, extension: [
  //       HTResource.hetuModule,
  //       HTResource.hetuScript,
  //       HTResource.json,
  //     ]);
  //     final sourceContext = HTAssetResourceContext(
  //         root: root,
  //         includedFilter: [filterConfig],
  //         expressionModuleExtensions: [HTResource.json]);
  //     hetu = Hetu(
  //       config: HetuConfig(
  //         showHetuStackTrace: true,
  //         allowImplicitNullToZeroConversion: true,
  //         allowImplicitEmptyValueToFalseConversion: true,
  //       ),
  //       sourceContext: sourceContext,
  //     );
  //     await hetu.initFlutter(
  //       locale: HTLocaleSimplifiedChinese(),
  //       externalFunctions: externalFunctions,
  //       externalClasses: [
  //         SamsaraEngineClassBinding(),
  //         MapComponentClassBinding(),
  //       ],
  //     );
  //   } else {
  //     hetu = Hetu(
  //       config: HetuConfig(
  //         showHetuStackTrace: true,
  //         allowImplicitNullToZeroConversion: true,
  //         allowImplicitEmptyValueToFalseConversion: true,
  //       ),
  //     );
  //     hetu.init(
  //       locale: HTLocaleSimplifiedChinese(),
  //       externalFunctions: externalFunctions,
  //       externalClasses: [
  //         SamsaraEngineClassBinding(),
  //         MapComponentClassBinding(),
  //       ],
  //     );
  //   }
  // }

  @override
  Future<Scene> createScene(String key, [Map<String, dynamic>? args]) async {
    final scene = await super.createScene(key, args);
    broadcast(SceneEvent.created(sceneKey: key));
    return scene;
  }

  @override
  void leaveScene(String key) {
    super.leaveScene(key);
    broadcast(SceneEvent.ended(sceneKey: key));
  }

  List<String> getLog() => _loggerOutput.log;

  // String _stringify(dynamic args) {
  //   if (args is List) {
  //     if (isLoaded) {
  //       return args.map((e) => hetu.lexicon.stringify(e)).join(' ');
  //     } else {
  //       return args.map((e) => e.toString()).join(' ');
  //     }
  //   } else {
  //     if (isLoaded) {
  //       return hetu.lexicon.stringify(args);
  //     } else {
  //       return args.toString();
  //     }
  //   }
  // }

  void debug(dynamic content) {
    logger.d(content);
  }

  void info(dynamic content) {
    logger.i(content);
  }

  void warning(dynamic content) {
    logger.w(content);
  }

  void error(dynamic content) {
    logger.e(content);
  }
}
