import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/samsara.dart';

import '../state/hoverinfo.dart';

final kGridSize = Vector2(32.0, 28.0);
final kTileSpriteSrcSize = Vector2(32.0, 64.0);
final kTileOffset = Vector2(0.0, 16.0);
final kTileFogOffset = Vector2(-6.0, 0.0);
final kWorldMapCharacterSpriteSrcSize = Vector2(32.0, 48.0);

const kSpriteWater = 0;
const kSpriteLand = 1;
const kSpriteForest = 2;
const kSpriteMountain = 3;
const kSpriteFarmField = 4;
const kSpriteDungeonStonePavedTile = 5;

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

  /// 这个 id 仅用于事件注册，在创建场景时，editor 使用 worldmap 作为 id
  static const editor = 'editor';
}

const kLocationKindHome = 'home';
const kLocationKindResidence = 'residence';

void previewCard(
  BuildContext context,
  String id,
  dynamic cardData,
  Rect rect, {
  HoverInfoDirection? direction,
  dynamic characterData,
}) {
  context.read<HoverInfoContentState>().set(
        cardData,
        rect,
        direction: direction ?? HoverInfoDirection.rightTop,
        data2: characterData,
      );
}

void unpreviewCard(BuildContext context) {
  context.read<HoverInfoContentState>().hide();
}
