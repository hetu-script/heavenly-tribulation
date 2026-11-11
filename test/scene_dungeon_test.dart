import 'dart:io';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:heavenly_tribulation/data/game.dart';
import 'package:heavenly_tribulation/scene/dungeon/dungeon_controller.dart';

import 'support/hetu_test_utils.dart';

(Hetu, dynamic, dynamic) createSettlementContext() {
  final hetu = createTestHetu(relaxedConversions: true);
  hetu.eval(File('scripts/main/event/scene_dungeon.ht').readAsStringSync());
  hetu.eval('var game; var hero;');
  hetu.assign('game', {
    'flags': {
      'dungeon': {
        'rank': 2,
        'level': 2,
        'levelMax': 5,
        'currentSceneIndex': 4,
        'rooms': {
          '4': <String, dynamic>{},
        },
        'active': true,
        'battleResult': true,
        'battleRoomIndex': 4,
      },
    },
  });
  hetu.assign('hero', {
    'rank': 2,
    'dungeonId': 'scene_chain',
    'cardLibrary': {
      'permanent': {'id': 'permanent'},
      'boss_permanent': {'id': 'boss_permanent'},
      'dungeon': {'id': 'dungeon', 'isDungeonCard': true},
    },
    'battleDecks': [
      {
        'cards': ['permanent', 'dungeon'],
      },
      {
        'cards': ['dungeon'],
      },
    ],
    'battleDeckIndex': 0,
    'equipments': {'0': 'equipped'},
    'inventory': {
      'equipped': {'id': 'equipped', 'isInvalid': true},
      'loose': {'id': 'loose'},
    },
    'materials': {'money': 100, 'shard': 5},
    'warehouse': {
      'inventory': {
        'safe': {'id': 'safe'},
      },
      'materials': {'money': 1000},
    },
  });
  return (hetu, hetu.fetch('hero'), hetu.fetch('game'));
}

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

  test('突破只匹配随身背包中目标境界的破镜丹', () {
    final previousHero = GameData.hero;
    try {
      final targetPill = {
        'id': 'craftmaterial_upgradeRank_2',
        'kind': 'craftmaterial_upgradeRank',
        'rank': 2,
      };
      GameData.hero = {
        'inventory': {
          'wrong_rank': {
            'kind': 'craftmaterial_upgradeRank',
            'rank': 1,
          },
          'other_item': {
            'kind': 'craftmaterial_addAffix',
            'rank': 2,
          },
          'target': targetPill,
        },
        'warehouse': {
          'inventory': {
            'warehouse_pill': {
              'kind': 'craftmaterial_upgradeRank',
              'rank': 3,
            },
          },
        },
      };

      expect(DungeonController.findBreakthroughPill(2), same(targetPill));
      expect(DungeonController.findBreakthroughPill(3), isNull);
      expect(DungeonController.findBreakthroughPill(4), isNull);
    } finally {
      GameData.hero = previousHero;
    }
  });

  test('突破成功后同步秘境境界、层级和层级上限', () {
    final previousHero = GameData.hero;
    final previousGame = GameData.game;
    try {
      GameData.hero = {'rank': 3};
      GameData.game = {
        'flags': {
          'dungeon': {
            'rank': 2,
            'level': 5,
            'levelMax': 5,
          },
        },
      };

      DungeonController.syncDungeonAfterBreakthrough();

      expect(GameData.game['flags']['dungeon']['rank'], 3);
      expect(GameData.game['flags']['dungeon']['level'], 0);
      expect(GameData.game['flags']['dungeon']['levelMax'], 7);
    } finally {
      GameData.hero = previousHero;
      GameData.game = previousGame;
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

      final permanentCopy = DungeonController.createDungeonCardCopy(
        first.first,
        isDungeonCard: false,
      );
      expect(permanentCopy['isDungeonCard'], isNull);
      expect(permanentCopy['id'], isNot(first.first['id']));
      expect(permanentCopy['id'], isNot(copy['id']));
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

  test('胜利结算保留随身资产，只清理当前卡组与卡库中的地牢卡', () {
    final (hetu, hero, game) = createSettlementContext();

    final summary = hetu.invoke(
      'settleSceneDungeonRun',
      namedArgs: {'outcome': 'victory'},
    );

    expect(summary['outcome'], 'victory');
    expect(summary['previousLevel'], 2);
    expect(summary['level'], 3);
    expect(summary['removedDungeonCardCount'], 1);
    expect(summary['removedInventoryItemCount'], 0);
    expect(summary['clearedMaterialKinds'], 0);
    expect(game['flags']['dungeon']['level'], 3);
    expect(game['flags']['dungeon']['active'], false);
    expect(game['flags']['dungeon']['rooms'], isEmpty);
    expect(game['flags']['dungeon']['currentSceneIndex'], 0);
    expect(game['flags']['dungeon']['battleResult'], isNull);
    expect(game['flags']['dungeon']['battleRoomIndex'], isNull);
    expect(hero['dungeonId'], isNull);
    expect(
        hero['cardLibrary'].keys, containsAll(['permanent', 'boss_permanent']));
    expect(hero['cardLibrary'].containsKey('dungeon'), false);
    expect(hero['battleDecks'][0]['cards'], ['permanent']);
    expect(hero['battleDecks'][1]['cards'], ['dungeon']);
    expect(hero['inventory'].keys, containsAll(['equipped', 'loose']));
    expect(hero['materials'], {'money': 100, 'shard': 5});
    expect(hero['warehouse']['materials'], {'money': 1000});

    final repeated = hetu.invoke(
      'settleSceneDungeonRun',
      namedArgs: {'outcome': 'victory'},
    );
    expect(repeated, isNull);
    expect(game['flags']['dungeon']['level'], 3);
  });

  for (final outcome in ['failure', 'abandon']) {
    test('$outcome 结算清理未装备物品与全部随身货币且保持幂等', () {
      final (hetu, hero, game) = createSettlementContext();

      final summary = hetu.invoke(
        'settleSceneDungeonRun',
        namedArgs: {'outcome': outcome},
      );

      expect(summary['outcome'], outcome);
      expect(summary['level'], 0);
      expect(summary['removedDungeonCardCount'], 1);
      expect(summary['removedInventoryItemCount'], 1);
      expect(summary['clearedMaterialKinds'], 2);
      expect(game['flags']['dungeon']['level'], 0);
      expect(game['flags']['dungeon']['active'], false);
      expect(hero['inventory'].keys, ['equipped']);
      expect(hero['inventory']['equipped']['isInvalid'], true);
      expect(hero['materials'], isEmpty);
      expect(hero['warehouse']['inventory'].keys, ['safe']);
      expect(hero['warehouse']['materials'], {'money': 1000});
      expect(hero['cardLibrary'].containsKey('dungeon'), false);
      expect(hero['cardLibrary'].containsKey('boss_permanent'), true);
      expect(hero['battleDecks'][0]['cards'], ['permanent']);
      expect(hero['battleDecks'][1]['cards'], ['dungeon']);

      final repeated = hetu.invoke(
        'settleSceneDungeonRun',
        namedArgs: {'outcome': outcome},
      );
      expect(repeated, isNull);
      expect(hero['inventory'].keys, ['equipped']);
      expect(game['flags']['dungeon']['level'], 0);
    });
  }
}
