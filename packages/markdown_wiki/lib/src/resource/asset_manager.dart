import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;

import 'resource.dart';
import 'resource_manager.dart';

class AssetManager extends ResourceManager {
  @override
  final Set<String> includedPaths = {};
  final Set<String> extentions;
  final Map<String, Resource> _cached = {};
  final Map<String, Set<String>> _tags = {};

  AssetManager({
    this.extentions = const {'.md'},
  });

  @override
  void init() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final assetKeys = manifestMap.keys;
    for (final key in assetKeys) {
      final ext = path.extension(key);
      if (extentions.contains(ext)) {
        includedPaths.add(key);
      }
    }
    for (final key in includedPaths) {
      final content = await rootBundle.loadString(key);
      final Set<String> tags = {};
      final resource = Resource(
        title: key,
        content: content,
        tags: tags,
      );
      for (final tag in tags) {
        if (_tags.containsKey(tag)) {
          _tags[tag]!.add(key);
        } else {
          _tags[tag] = {key};
        }
      }
      addResource(key, resource);
    }
  }

  @override
  bool contains(String path) {
    return _cached.containsKey(path);
  }

  @override
  void addResource(String path, Resource resource) {
    _cached[path] = resource;
  }

  @override
  Resource? getResource(String path) {
    return _cached[path];
  }
}
