import '../global.dart';

String getNameFromId(String? id) {
  if (id != null) {
    final l = id.split('_');
    return l.last;
  } else {
    return engine.locale['none'];
  }
}

Iterable<String> getNamesFromEntityIds(Iterable ids) {
  if (ids.isNotEmpty) {
    return ids.map((id) => getNameFromId(id));
  } else {
    return [engine.locale['none']];
  }
}
