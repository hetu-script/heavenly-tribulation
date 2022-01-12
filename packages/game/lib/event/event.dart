class GameEvent {
  final String name;

  const GameEvent(this.name);
}

typedef EventHandler = void Function(GameEvent event);

class EventAggregator {
  final _eventHandlers = <String, List<EventHandler>>{};

  void registerListener(String name, EventHandler handle) {
    if (_eventHandlers[name] == null) {
      _eventHandlers[name] = [];
    }
    _eventHandlers[name]!.add(handle);
  }

  void broadcast(GameEvent event) {
    final listeners = _eventHandlers[event.name]!;
    for (final listener in listeners) {
      listener(event);
    }
  }
}
