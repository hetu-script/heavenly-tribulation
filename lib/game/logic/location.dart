part of 'logic.dart';

void _onAfterEnterLocation(dynamic location) async {
  await engine.hetu.invoke('onGameEvent',
      positionalArgs: ['onAfterEnterLocation', location]);

  if (location['kind'] == 'home') {
    final ownerId = location['ownerId'];
    if (ownerId != GameData.hero['id']) {
      final owner = GameData.game['characters'][ownerId];
      if (owner['locationId'] != location['id']) {
        GameDialogContent.show(
            engine.context,
            engine.locale('hint_visitEmptyHome',
                interpolations: [owner['name']]));
      }
    }
  } else {
    final locationId = location['id'];
  }
}
