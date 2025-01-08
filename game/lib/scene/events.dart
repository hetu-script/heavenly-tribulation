abstract class GameEvents {
  static const leaveCultivation = 'leave_scene_cultivation';
  static const leaveCardLibrary = 'leave_scene_card_library';
  static const leaveCardBattle = 'leave_scene_card_battle';

  static const mapLoaded = 'map_loaded';
  static const popLocationSiteScene = 'pop_scene';
  static const pushLocationSiteScene = 'push_scene';
  static const residenceSiteScene = 'residence_scene';
  static const worldmapCharactersUpdated = 'worldmap_characters_updated';
}

abstract class UIEvents {
  static const cardPacksButtonClicked = 'card_packs_button_clicked';
}

abstract class CardEvents {
  static const cardPreview = 'card_preview';
  static const cardUnpreview = 'card_unpreview';
}
