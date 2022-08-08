import 'resource.dart';

abstract class ResourceManager {
  static const Set<String> resourceFileExtensions = {'.md'};

  Iterable<String> get includedPaths;

  void init();

  bool contains(String path);

  void addResource(String path, Resource resource);

  Resource? getResource(String path);
}
