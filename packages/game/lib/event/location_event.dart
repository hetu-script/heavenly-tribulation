import 'event.dart';

abstract class LocationEvents {
  static const entered = 'entered_location';
  static const left = 'left_location';
}

class LocationEvent extends GameEvent {
  final String locationId;

  const LocationEvent({
    required String eventName,
    required this.locationId,
  }) : super(eventName);

  const LocationEvent.entered({required String locationId})
      : this(eventName: LocationEvents.entered, locationId: locationId);

  const LocationEvent.left({required String locationId})
      : this(eventName: LocationEvents.left, locationId: locationId);
}
