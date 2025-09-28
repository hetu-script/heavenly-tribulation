// ignore_for_file: prefer_collection_literals

import 'dart:collection';
import 'dart:async';

import 'package:heavenly_tribulation/game/data.dart';
import 'package:hetu_script/values.dart';
import 'package:flutter/material.dart';
import 'package:samsara/task.dart';
import 'package:hetu_script/utils/uid.dart';

import '../engine.dart';

class IllustrationInfo {
  final String path;
  final double offsetX, offsetY;
  bool isFadeOut;

  IllustrationInfo(
    this.path, {
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.isFadeOut = false,
  });
}

class SceneInfo {
  final String path;
  final bool isFadeIn;
  bool isFadeOut;
  String? taskId;

  SceneInfo(
    this.path, {
    this.isFadeIn = false,
    this.isFadeOut = false,
    this.taskId,
  });
}

class GameDialog with ChangeNotifier, TaskController {
  static final singleton = GameDialog._();

  GameDialog._();

  bool isOpened = false;

  /// key是图片的asset路径
  final scenes = LinkedHashSet<SceneInfo>();
  SceneInfo? get currentSceneInfo => scenes.lastOrNull;
  SceneInfo? prevScene;

  /// key是图片的asset路径，value是图片x坐标的偏移值
  final illustrations = LinkedHashSet<IllustrationInfo>();

  final contents = LinkedHashMap<String, dynamic>();
  dynamic get currentContent => contents.values.lastOrNull;

  dynamic selectionsData;

  final storedValues = <String, dynamic>{};

  void loadValues(Map<String, dynamic> values) {
    storedValues.clear();
    storedValues.addAll(values);
  }

  dynamic getValue(String key) {
    return storedValues[key];
  }

  Future<void>? execute() {
    return schedule(() {
      isOpened = false;
      prevScene = null;
      illustrations.clear();
      scenes.clear();
      contents.clear();
      selectionsData = null;
      notifyListeners();
    }, id: 'execution_to_end');
  }

  void pushBackground(String imageId, {bool isFadeIn = false}) {
    isOpened = true;
    final taskId = 'push_background_${randomUID(withTime: true)}';
    schedule(
      () {
        if (scenes.isNotEmpty) {
          prevScene = scenes.last;
        }
        scenes.add(SceneInfo(
          'assets/images/$imageId',
          isFadeIn: isFadeIn,
          taskId: taskId,
        ));
        notifyListeners();
      },
      id: taskId,
      isAuto: !isFadeIn,
    );
  }

  void popBackground({String? imageId, isFadeOut = false}) {
    assert(isOpened == true);
    final taskId = 'pop_background_${randomUID(withTime: true)}';
    schedule(
      () {
        assert(scenes.isNotEmpty,
            'game dialog: pop background failed, no background to pop. imageId: $imageId');
        if (imageId != null) {
          prevScene = scenes.singleWhere(
            (scene) => scene.path == 'assets/images/$imageId',
            orElse: () => scenes.last,
          );
        } else {
          prevScene = scenes.last;
        }
        if (isFadeOut) {
          prevScene!.isFadeOut = isFadeOut;
          prevScene!.taskId = taskId;
        }
        scenes.remove(prevScene);
        notifyListeners();
      },
      id: taskId,
      isAuto: !isFadeOut,
    );
  }

  void popAllBackgrounds() {
    assert(isOpened == true);
    final taskId = 'pop_all_backgrounds_${randomUID(withTime: true)}';
    schedule(
      () {
        assert(scenes.isNotEmpty,
            'game dialog: pop background failed, no background to pop.');
        if (scenes.isNotEmpty) {
          prevScene = scenes.last;
        }
        scenes.clear();
        notifyListeners();
      },
      id: taskId,
    );
  }

  void pushImage(
    String imageId, {
    double offsetX = 0.0,
    double offsetY = 0.0,
  }) {
    isOpened = true;
    final taskId = 'push_image_${randomUID(withTime: true)}';
    schedule(
      () {
        illustrations.add(IllustrationInfo(
          'assets/images/$imageId',
          offsetX: offsetX,
          offsetY: offsetY,
        ));
        notifyListeners();
      },
      id: taskId,
    );
  }

  void popImage({String? imageId}) {
    assert(isOpened == true);
    final taskId = 'pop_image_${randomUID(withTime: true)}';
    schedule(
      () {
        assert(illustrations.isNotEmpty,
            'game dialog: pop image failed, no image to pop.');
        if (imageId != null) {
          illustrations
              .removeWhere((img) => img.path == 'assets/images/$imageId');
        } else if (illustrations.isNotEmpty) {
          illustrations.remove(illustrations.last);
        }
        notifyListeners();
      },
      id: taskId,
    );
  }

  void popAllImages() {
    assert(isOpened == true);
    final taskId = 'pop_all_images_${randomUID(withTime: true)}';
    schedule(
      () {
        assert(illustrations.isNotEmpty,
            'game dialog: pop image failed, no image to pop.');
        illustrations.clear();
        notifyListeners();
      },
      id: taskId,
    );
  }

  /// 简化模式的对话框接口，会根据情况自动包装需要的信息
  void pushDialog(
    dynamic localeKeys, {
    dynamic character,
    String? characterId,
    bool isHero = false,
    String? nameId,
    String? name,
    bool hideName = false,
    String? icon,
    bool hideIcon = false,
    String? image,
    bool hideImage = false,
    dynamic interpolations,
  }) {
    character ??=
        isHero ? GameData.hero : GameData.game['characters'][characterId];
    icon ??= hideIcon ? null : character?['icon'];
    image ??= hideImage ? null : character?['illustration'];

    if (hideName) {
      name = '';
    } else {
      if (isHero) {
        name = engine.locale('me');
      } else {
        if (name == null) {
          if (nameId != null) {
            name = engine.locale(nameId);
          } else {
            if (character != null) {
              final heroHaveMetChar = engine.hetu.invoke('haveMet',
                  positionalArgs: [GameData.hero, character]);
              if (heroHaveMetChar == null || heroHaveMetChar == false) {
                if (character['titleId'] != null) {
                  name = engine.locale(character['titleId']);
                } else {
                  name = '???';
                }
              } else {
                name = character['name'];
              }
            }
          }
        }
      }
    }

    List<String> strings = [];
    if (localeKeys is List) {
      assert(localeKeys.isNotEmpty);
      strings = localeKeys
          .map((key) => engine.locale(key, interpolations: interpolations))
          .toList();
    } else if (localeKeys is String) {
      strings = [engine.locale(localeKeys, interpolations: interpolations)];
    } else {
      throw 'Dialog.pushDialog: localeKeys must be a String or a List<String>.';
    }
    List lines = [];
    for (final line in strings) {
      final splits = line.split('\n');
      for (final split in splits) {
        final trim = split.trim();
        if (trim.isNotEmpty) {
          lines.add(trim);
        }
      }
    }

    return pushDialogRaw(
      {
        'name': name,
        'icon': icon,
        'lines': lines,
      },
      imageId: image,
    );
  }

  /// 按原始数据推送游戏对话，格式如下
  /// ```javascript
  /// {
  ///   name: string,
  ///   icon: icon,
  ///   image: string,
  ///   lines: []string,
  /// }
  /// ```
  void pushDialogRaw(dynamic content, {String? imageId}) {
    isOpened = true;
    if (imageId != null) {
      pushImage(imageId);
    }
    assert(content != null);
    final resolved = <String, dynamic>{};

    if (content is String) {
      resolved['lines'] = [content];
    } else if (content is List) {
      resolved['lines'] = content;
    } else if (content is Map || content is HTStruct) {
      resolved.addAll(content);
    } else {
      throw 'Dialog.pushDialogRaw: content must be a String, List<String>, Map or HTStruct. $content';
    }
    isOpened = true;
    final taskId = 'push_dialog_${randomUID(withTime: true)}';
    resolved['id'] = taskId;
    schedule(
      () {
        contents[taskId] = resolved;
        notifyListeners();
      },
      id: taskId,
      isAuto: false,
    );
    if (imageId != null) {
      popImage(imageId: imageId);
    }
  }

  void finishDialog(String id) {
    assert(isOpened == true);
    assert(contents.containsKey(id));
    contents.remove(id);
    finishTask(id);
    notifyListeners();
  }

  void finishTask(String id) {
    if (hasTask(id)) {
      completeTask(id);
    }
  }

  void pushTask(FutureOr<dynamic> Function() task, {String? flagId}) {
    isOpened = true;
    final taskId = 'push_task_${randomUID(withTime: true)}';
    schedule(task, id: taskId)?.then((result) {
      if (flagId != null) {
        storedValues[flagId] = result;
      }
    });
  }

  /// 简易版本的选择对话框，localeId是一个字符串列表或[Map<String, String>]，
  void pushSelection(String id, dynamic locales) {
    final selections = {};
    if (locales is List) {
      for (final value in locales) {
        if (value is String) {
          selections[value] = engine.locale(value);
        } else if (value is Map || value is HTStruct) {
          assert(value['text'] != null,
              'Dialog.pushSelection: invalid selection value data, text is null. $value');
          final keyData = {};
          keyData['text'] = engine.locale(value['text']);
          keyData['description'] = engine.locale(value['description']);
          selections[value['text']] = keyData;
        } else {
          throw 'Dialog.pushSelection: locales must be a List<String> or a Map<String, String>.';
        }
      }
    } else if (locales is Map || locales is HTStruct) {
      for (final key in locales.keys) {
        final value = locales[key];
        assert(value is Map || value is HTStruct,
            'Dialog.pushSelection: invalid selection data. $value');
        final keyData = {};
        if (value['text'] != null) {
          keyData['text'] = engine.locale(value['text']);
        } else {
          keyData['text'] = engine.locale(key);
        }
        keyData['description'] = engine.locale(value['description']);
        selections[key] = keyData;
      }
    } else {
      throw 'Dialog.pushSelection: locales must be a List<String> or a Map<String, String>.';
    }
    return pushSelectionRaw({'id': id, 'selections': selections});
  }

  /// 按原始数据推送选择对话框，格式如下：
  /// ```
  /// {
  ///   // 用于稍后取出玩家选择的 key
  ///   id: 'selection_id',
  ///   selections: {
  ///     // 可以只有一个单独的文本
  ///     selectKey1: 'localedText1',
  ///     // 也可以是文本加一个描述文本
  ///     selectKey2: { text: 'localedText3', description: 'localedText4' },
  ///   }
  /// }
  void pushSelectionRaw(dynamic selectionsData) {
    assert(selectionsData is HTStruct || selectionsData is Map,
        'invalid selection data. $selectionsData');
    final taskId = 'push_selection_${randomUID(withTime: true)}';
    isOpened = true;
    schedule(
      () {
        selectionsData['taskId'] = taskId;
        this.selectionsData = selectionsData;
        notifyListeners();
      },
      id: taskId,
      isAuto: false,
    );
  }

  void finishSelection(String taskId, String dataId, {dynamic value}) {
    assert(isOpened == true);
    storedValues[dataId] = value ?? true;
    selectionsData = null;
    assert(hasTask(taskId));
    completeTask(taskId);
    notifyListeners();
  }

  /// 根据当前选择分支执行任务
  dynamic checkSelected(dynamic data) {
    bool satisfied = true;
    if (data is List) {
      for (final key in data) {
        if (storedValues[key.toString()] != true) {
          satisfied = false;
          break;
        }
      }
      return satisfied;
    } else if (data is HTStruct || data is Map) {
      for (final key in data.keys) {
        final value = data[key];
        if (storedValues[key.toString()] != value) {
          satisfied = false;
          break;
        }
      }
      return satisfied;
    } else if (data is String) {
      if (storedValues[data] == null) {
        engine.warn('game dialog: checked selected data non exists: $data');
      } else {
        return storedValues[data];
      }
    } else {
      engine.warn('game dialog: invalid selected value data: $data');
      return null;
    }
  }
}
