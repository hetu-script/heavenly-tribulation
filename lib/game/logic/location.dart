part of 'logic.dart';

void _onAfterEnterLocation(dynamic location) async {
  await engine.hetu.invoke('onGameEvent',
      positionalArgs: ['onAfterEnterLocation', location]);

  if (location['kind'] == 'home') {
    final ownerId = location['ownerId'];
    if (ownerId != GameData.hero['id']) {
      final owner = GameData.getCharacter(ownerId);
      if (owner['locationId'] != location['id']) {
        GameDialogContent.show(
            engine.context,
            engine.locale('hint_visitEmptyHome',
                interpolations: [owner['name']]));
      }
    }
  }

  final heroOrganizationId = GameData.hero['organizationId'];
  if (heroOrganizationId != null) {
    final organization = GameData.getOrganization(heroOrganizationId);
    final memberData = organization['members'][GameData.hero['id']];
    assert(memberData != null,
        'Member data not found in organization [${organization['id']}], member id: ${GameData.hero['id']}');

    final reportSiteId = memberData['reportSiteId'];
    if (reportSiteId == location['id']) {
      final organizationInitiationQuest =
          GameData.hero['quests']['organizationInitiation'];
      if (organizationInitiationQuest != null &&
          organizationInitiationQuest['isFinished'] != true) {
        final superiorId = memberData['superiorId'];
        assert(superiorId != null);

        final superior = GameData.getCharacter(superiorId);
        dialog.pushDialog(
          'hint_organization_initiation2',
          character: superior,
        );
        await dialog.execute();

        final randomEquipment = kEquipmentCategoryKinds['weapon']!.random;
        final itemsInfo = [
          {
            'type': 'equipment',
            'kind': randomEquipment,
            'rank': GameData.hero['rank'],
          },
          {
            'type': 'cardpack',
            'category': 'attack',
            'kind': randomEquipment,
            'rank': GameData.hero['rank'],
            'isBasic': true,
          },
          {
            'type': 'cardpack',
            'kind': randomEquipment,
            'rank': GameData.hero['rank'],
          },
        ];
        final items = engine.hetu
            .invoke('loot', namespace: 'Player', positionalArgs: [itemsInfo]);
        GameLogic.promptItems(items);

        engine.hetu.invoke('progressQuestById',
            namespace: 'Player', positionalArgs: ['organizationInitiation']);
      } else {
        final playerMonthly = GameData.game['monthlyActivities'];
        if (playerMonthly['attendedMeeting'] != true && GameLogic.day <= 5) {}
      }
    }
  }
}
