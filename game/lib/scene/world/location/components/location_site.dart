// import 'package:samsara/event/event.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:samsara/cardgame/custom_card.dart';

import '../../../../engine.dart';
import '../../../../data.dart';
import 'site_zone.dart';
// import '../../../../ui.dart';
import '../../../events.dart';

class LocationSiteScene extends Scene {
  late final SpriteComponent _backgroundComponent;
  final String background;
  final Iterable<dynamic> sitesIds;
  final dynamic sitesData;

  LocationSiteScene({
    required super.id,
    required this.background,
    required super.controller,
    required super.context,
    required this.sitesIds,
    required this.sitesData,
  }) : super(
        // bgmFile: 'vietnam-bamboo-flute-143601.mp3',
        // bgmVolume: GameConfig.musicVolume,
        );

  @override
  void onLoad() async {
    super.onLoad();

    _backgroundComponent = SpriteComponent(
      sprite: Sprite(await Flame.images.load(background)),
      size: size,
    );
    world.add(_backgroundComponent);

    final List<CustomGameCard> siteCards = [];

    // final heroHomeId = engine.hetu.invoke('getHeroHomeLocationId');
    // if (id == heroHomeId) {
    //   final heroHomeSite = engine.hetu.invoke('getHeroHomeSite');
    //   siteCards.add(GameData.getSiteCard(heroHomeSite));
    // }

    for (final id in sitesIds) {
      assert(sitesData.containsKey(id));
      final siteData = sitesData[id];
      siteCards.add(GameData.getSiteCard(siteData));
    }

    for (final card in siteCards) {
      world.add(card);
      card.onTap = (buttons, position) {
        if (card.data['category'] != 'residence') {
          engine.emit(GameEvents.pushLocationSiteScene, args: card.id);
        } else {
          engine.emit(GameEvents.residenceSiteScene);
        }
      };
    }

    final siteList = SitesCards(cards: siteCards);
    world.add(siteList);

    final exit = GameData.getExitSiteCard();
    exit.onTap =
        (_, __) => engine.emit(GameEvents.popLocationSiteScene, args: id);
    world.add(exit);
  }
}
