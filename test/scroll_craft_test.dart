import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'support/hetu_test_utils.dart';

void main() {
  test('制符保留原卡，副本没有跨战斗次数且打出后消耗', () {
    final source = File('scripts/main/binding/player.ht').readAsStringSync();
    final start = source.indexOf('  function craftScroll');
    final end = source.indexOf('  /// 分解卡牌', start);
    final craftScroll = source.substring(start, end);
    final hetu = createTestHetu();
    hetu.eval('''
      final hero = {
        id: 'hero',
        name: 'hero',
        cardLibrary: {},
      }
      final engine = {
        locale: function(id, {interpolations}) { return id },
        info: function(message) {},
      }
      final crypto = {
        randomUID: function({withTime}) { return 'scroll-id' },
      }
      final Constants = {colorlessCostColorId: 'life'}
      namespace Player {
        function lose(item, {amount = 1}) {}
        $craftScroll
      }
    ''');
    hetu.eval('''
      final original = {
        id: 'original',
        name: 'test-card',
        rank: 4,
        equipment: 'sword',
        coloredCost: {spell: 3},
        isEphemeral: false,
      }
      final copy = Object.create(original)
      Player.craftScroll(copy, {id: 'paper'}, incurIncident: false)
    ''');

    final original = hetu.fetch('original');
    final hero = hetu.fetch('hero');
    final scroll = hero['cardLibrary']['scroll-id'];
    expect(original['id'], 'original');
    expect(original['rank'], 4);
    expect(original['equipment'], 'sword');
    expect(scroll['isEphemeral'], true);
    expect(scroll['chargeData'], isNull);
    expect(scroll['rank'], 0);
    expect(scroll['equipment'], isNull);
    expect(scroll['coloredCost']['life'], 1);
  });
}
