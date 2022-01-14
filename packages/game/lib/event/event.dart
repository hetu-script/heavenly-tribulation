import 'package:flutter/material.dart';

abstract class GameEvent {
  final String name;

  const GameEvent(this.name);
}

class EventHandler {
  final Key ownerKey;

  final void Function(GameEvent event) handle;

  EventHandler(this.ownerKey, this.handle);
}

abstract class EventAggregator {
  final _eventHandlers = <String, List<EventHandler>>{};

  void registerListener(String name, EventHandler handler) {
    if (_eventHandlers[name] == null) {
      _eventHandlers[name] = [];
    }
    _eventHandlers[name]!.add(handler);
  }

  void disposeListenders(Key key) {
    for (final list in _eventHandlers.values) {
      list.removeWhere((handler) => handler.ownerKey == key);
    }
  }

  void broadcast(GameEvent event) {
    final listeners = _eventHandlers[event.name]!;
    for (final listener in listeners) {
      listener.handle(event);
    }
  }
}
