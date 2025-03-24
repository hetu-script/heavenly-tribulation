import 'engine.dart';

String getNameFromId(String? id, [String? orElse = 'null']) {
  if (id != null) {
    final l = id.split('.');
    return l.last;
  } else {
    return engine.locale(orElse);
  }
}

Iterable<String> getNamesFromIds(Iterable ids, [String? orElse = 'null']) {
  if (ids.isNotEmpty) {
    return ids.map((id) => getNameFromId(id));
  } else {
    return [engine.locale(orElse)];
  }
}
