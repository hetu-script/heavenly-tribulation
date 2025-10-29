const kMaxHeroAge = 17;

const kWorldMapAnimationPriority = 15000;

const kSiteCardPriority = 500;

const kMouseCursorEffectPriority = 99999999;

final class Scenes {
  static const mainmenu = 'mainmenu';
  static const library = 'library';
  static const cultivation = 'cultivation';
  static const worldmap = 'worldmap';
  static const location = 'location';
  static const battle = 'battle';

  static const matchingGame = 'matching_game';

  /// 下面的 id 仅用于事件注册
  static const editor = 'editor';
  static const prebattle = 'prebattle';
}

final class GameEvents {
  static const heroPassivesUpdated = 'hero_passives_updated';
}
