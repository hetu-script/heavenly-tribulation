import 'package:flutter/material.dart';

abstract class GameEvents {
  static const onBack2Menu = 'back2Menu';
}

class GameEvent {
  final String name;

  const GameEvent.back2Menu() : this(GameEvents.onBack2Menu);

  const GameEvent(this.name);
}

class EventHandler {
  final Key ownerKey;

  final void Function(GameEvent event) handle;

  EventHandler(this.ownerKey, this.handle);
}

abstract class EventAggregator {
  final _eventHandlers = <String, List<EventHandler>>{};

  void registerListener(String eventId, EventHandler eventHandler) {
    if (_eventHandlers[eventId] == null) {
      _eventHandlers[eventId] = [];
    }
    _eventHandlers[eventId]!.add(eventHandler);
  }

  void disposeListenders(Key key) {
    for (final list in _eventHandlers.values) {
      list.removeWhere((handler) => handler.ownerKey == key);
    }
  }

  void broadcast(GameEvent event) {
    final listeners = _eventHandlers[event.name];
    if (listeners != null) {
      for (final listener in listeners) {
        listener.handle(event);
      }
    }
  }
}
