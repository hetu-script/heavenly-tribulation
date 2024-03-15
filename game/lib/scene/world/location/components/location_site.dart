// import 'package:samsara/event/event.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:samsara/cardgame/card.dart';

import '../../../../config.dart';
import '../../../../data.dart';
import 'site_cards.dart';
import '../../../../ui.dart';
import '../../../../events.dart';

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

    final List<Card> siteCards = [];

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

    final exit = Card(
      id: 'exit',
      deckId: 'exit',
      borderRadius: 15.0,
      illustrationSpriteId: 'location/site/exit_card.png',
      spriteId: 'location/site/site_frame.png',
      title: engine.locale('exit'),
      titleStyle: ScreenTextStyle(textStyle: const TextStyle(fontSize: 20.0)),
      showTitle: true,
      position: GameUI.siteExitCardPositon,
      size: GameUI.siteCardSize,
      enablePreview: true,
      focusOnPreviewing: true,
      focusedPriority: 500,
      focusedSize: GameUI.siteCardFocusedSize,
      focusedOffset: Vector2(
          -(GameUI.siteCardFocusedSize.x - GameUI.siteCardSize.x) / 2,
          GameUI.siteCardSize.y - GameUI.siteCardFocusedSize.y),
    );
    exit.onTap =
        (_, __) => engine.emit(GameEvents.popLocationSiteScene, args: id);
    world.add(exit);
  }
}
