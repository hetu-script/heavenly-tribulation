import 'package:flame/components.dart' show Vector2;

final kTileMapObjectSpriteSrcSize = Vector2(32.0, 48.0);

const kSpriteWater = 0;
const kSpriteLand = 1;
const kSpriteForest = 2;
const kSpriteMountain = 3;
const kSpriteFarmField = 4;
const kSpriteDungeonStonePavedTile = 5;

const kSpriteCity = 8;
const kSpriteCave = 9;
const kSpriteArray = 10;
const kSpriteDungeonStoneGate = 11;
const kSpriteDungeonUnpressedTile = 12;
const kSpriteDungeonPressedTile = 13;
const kSpriteTreasureBox = 14;
const kSpriteTreasureBoxOpened = 15;

const kSpriteDungeonGlowingTile = 44;

const kTerrainKindEmpty = 'empty';
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
