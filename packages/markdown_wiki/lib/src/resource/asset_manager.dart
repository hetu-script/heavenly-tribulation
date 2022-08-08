import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as path;

import 'resource.dart';
import 'resource_manager.dart';

class AssetManager extends ResourceManager {
  final Set<String> _extentions;

  @override
  final Set<String> includedPaths = {};

  final Map<String, Resource> _cached = {};

  AssetManager({
    Set<String> resourceExtensions = ResourceManager.resourceFileExtensions,
  }) : _extentions = resourceExtensions;

  @override
  void init() async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);
    final assetKeys = manifestMap.keys;
    for (final key in assetKeys) {
      final ext = path.extension(key);
      if (_extentions.contains(ext)) {
        includedPaths.add(key);
      }
    }
    for (final key in includedPaths) {
      final content = await rootBundle.loadString(key);
      final resource = Resource(content: content);
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
