import 'package:flame/components.dart' show Vector2;

final kTileMapObjectSpriteSrcSize = Vector2(32.0, 48.0);

const kSpriteWater = 0;
const kSpriteLand = 1;
const kSpriteForest = 2;
const kSpriteMountain = 3;
const kSpriteFarmField = 4;
const kSpritePond = 5;
const kSpriteShelf = 6;
const kSpriteCity = 7;

const kTerrainKindEmpty = 'empty';
const kTerrainKindMountain = 'mountain';
const kTerrainKindShore = 'shore';
const kTerrainKindForest = 'forest';
const kTerrainKindPlain = 'plain';
const kTerrainKindLake = 'lake';
const kTerrainKindSea = 'sea';
const kTerrainKindRiver = 'river';
const kTerrainKindRoad = 'road';

const kColorModeZone = 0;
const kColorModeOrganization = 1;

const kMinHeroAge = 10;
const kMaxHeroAge = 20;
