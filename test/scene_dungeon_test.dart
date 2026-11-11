import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:heavenly_tribulation/data/game.dart';
import 'package:heavenly_tribulation/scene/dungeon/dungeon_controller.dart';

void main() {
  test('开始秘境只接受至少含一张满足硬需求卡牌的非空卡组', () {
    final previousHero = GameData.hero;
    try {
      GameData.hero = {
        'rank': 0,
        'equipments': <String, dynamic>{},
        'inventory': <String, dynamic>{},
        'cardLibrary': {
          'high-rank': {'rank': 5},
          'blocked': {'equipment': 'sword'},
        },
        'battleDecks': [
          {'cards': <dynamic>[]},
          {
            'cards': ['blocked']
          },
          {
            'cards': ['high-rank']
          },
        ],
        'battleDeckIndex': 0,
      };

      expect(DungeonController.prepareBattleDeck(), 2);
      expect(GameData.hero['battleDeckIndex'], 2);

      GameData.hero['battleDecks'] = [
        {'cards': <dynamic>[]},
        {
          'cards': ['blocked']
        },
      ];
      GameData.hero['battleDeckIndex'] = 0;
      expect(DungeonController.prepareBattleDeck(), -1);
    } finally {
      GameData.hero = previousHero;
    }
  });

  test('搜刮只过滤硬需求，候选持久保存且复制不修改敌人原卡', () {
    final previousHero = GameData.hero;
    final previousGame = GameData.game;
    final previousRandom = GameData.random;
    final previousScene = GameData.dungeonScenes['test_room'];
    final previousRoute = GameData.dungeonRoutes['test_route'];
    try {
      GameData.hero = {
        'rank': 0,
        'equipments': <String, dynamic>{},
        'inventory': <String, dynamic>{},
      };
      GameData.random = math.Random(7);
      GameData.dungeonScenes['test_room'] = {
        'id': 'test_room',
        'kind': 'battle',
      };
      GameData.dungeonRoutes['test_route'] = {
        'id': 'test_route',
        'sceneIds': ['test_room'],
      };
      final enemy = {
        'equipments': <String, dynamic>{},
        'inventory': <String, dynamic>{},
        'battleDeckIndex': 0,
        'battleDecks': [
          {
            'cards': ['high-rank', 'blocked', 'normal']
          }
        ],
        'cardLibrary': {
          'high-rank': {'id': 'high-rank', 'rank': 5},
          'blocked': {'id': 'blocked', 'equipment': 'sword'},
          'normal': {'id': 'normal', 'rank': 0},
        },
      };
      GameData.game = {
        'flags': {
          'dungeon': {
            'routeId': 'test_route',
            'currentSceneIndex': 0,
            'rooms': {
              '0': <String, dynamic>{
                'enemy': enemy,
                'scavengeCandidates': null,
              }
            },
          }
        }
      };

      final first = DungeonController.createScavengeCandidates();
      expect(first.map((card) => card['id']), hasLength(2));
      expect(first.map((card) => card['id']),
          containsAll(['high-rank', 'normal']));
      final second = DungeonController.createScavengeCandidates();
      expect(identical(first, second), isTrue);

      final copy = DungeonController.createDungeonCardCopy(first.first);
      expect(copy['isDungeonCard'], true);
      expect(copy['id'], isNot(first.first['id']));
      expect(first.first['isDungeonCard'], isNull);
    } finally {
      GameData.hero = previousHero;
      GameData.game = previousGame;
      GameData.random = previousRandom;
      if (previousScene == null) {
        GameData.dungeonScenes.remove('test_room');
      } else {
        GameData.dungeonScenes['test_room'] = previousScene;
      }
      if (previousRoute == null) {
        GameData.dungeonRoutes.remove('test_route');
      } else {
        GameData.dungeonRoutes['test_route'] = previousRoute;
      }
    }
  });
}
