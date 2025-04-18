import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';

import '../state/hover_content.dart';

final kGridSize = Vector2(32.0, 28.0);
final kTileSpriteSrcSize = Vector2(32.0, 64.0);
final kTileOffset = Vector2(0.0, 16.0);
final kTileFogOffset = Vector2(-6.0, 0.0);
final kWorldMapCharacterSpriteSrcSize = Vector2(32.0, 48.0);

const kSpriteWater = 0;
const kSpriteLand = 1;
const kSpriteRiver = 2;
const kSpriteDungeonStonePavedTile = 8;

const kSpriteCity = 'object/city.png';
const kSpriteDungeon = 'object/dungeon.png';
const kSpriteArray = 'object/portalArray.png';
const kSpriteDungeonLever = 'object/lever.png';
const kSpriteDungeonLeverOn = 'object/leverOn.png';
const kSpriteTreasureBox = 'object/treasureBox.png';
const kSpriteTreasureBoxOpened = 'object/treasureBoxOpened.png';
const kSpriteDungeonGlowingTile = 'object/glowingTile.png';

const kSpriteCharacterYoungMan = 'object/characterYoungMan.png';
const kSpriteCharacterMan = 'object/characterMan.png';
const kSpriteCharacterOldMan = 'object/characterOldMan.png';
const kSpriteCharacterYoungWoman = 'object/characterYoungWoman.png';

const kTerrainKindVoid = 'void';
const kTerrainKindPlain = 'plain';
const kTerrainKindMountain = 'mountain';
const kTerrainKindForest = 'forest';
const kTerrainKindSnowPlain = 'snow_plain';
const kTerrainKindShore = 'shore';
const kTerrainKindLake = 'lake';
const kTerrainKindSea = 'sea';
const kTerrainKindRiver = 'river';
const kTerrainKindRoad = 'road';

const kColorModeZone = 0;
const kColorModeOrganization = 1;

const kMinHeroAge = 10;
const kMaxHeroAge = 20;

const kWorldMapAnimationPriority = 15000;

const kSiteCardPriority = 500;

const kMouseCursorEffectPriority = 99999999;

abstract class Scenes {
  static const mainmenu = 'mainmenu';
  static const library = 'library';
  static const cultivation = 'cultivation';
  static const worldmap = 'worldmap';
  static const location = 'location';
  static const battle = 'battle';

  /// 下面的 id 仅用于事件注册
  static const editor = 'editor';
  static const prebattle = 'prebattle';
}

const kLocationKindHome = 'home';
const kLocationKindResidence = 'residence';

void previewCard(
  BuildContext context,
  String id,
  dynamic cardData,
  Rect rect, {
  bool isLibrary = true,
  HoverContentDirection? direction,
  dynamic characterData,
}) {
  context.read<HoverContentState>().show(
        cardData,
        rect,
        type: isLibrary ? ItemType.player : ItemType.none,
        direction: direction ?? HoverContentDirection.rightTop,
        data2: characterData,
      );
}

void unpreviewCard(BuildContext context) {
  context.read<HoverContentState>().hide();
}
