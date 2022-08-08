import 'resource.dart';

abstract class ResourceManager {
  Iterable<String> get includedPaths;

  void init();

  bool contains(String path);

  void addResource(String path, Resource resource);

  Resource? getResource(String path);
}
