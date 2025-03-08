abstract class GameEvents {
  static const leaveScene = 'leave_scene';

  static const leaveCultivation = 'leave_scene_cultivation';
  static const leaveCardLibrary = 'leave_scene_card_library';
  static const leaveCardBattle = 'leave_scene_card_battle';

  static const mapLoaded = 'map_loaded';
  static const residenceSiteScene = 'residence_scene';
  static const worldmapCharactersUpdated = 'worldmap_characters_updated';
  static const worldmapLocationsUpdated = 'worldmap_locations_updated';

  static const battleResult = 'battle_result';
}

abstract class CardEvents {
  static const cardPreview = 'card_preview';
  static const cardUnpreview = 'card_unpreview';
}
