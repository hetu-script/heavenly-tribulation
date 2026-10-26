import 'package:flutter_test/flutter_test.dart';
import 'package:heavenly_tribulation/data/common.dart';
import 'package:heavenly_tribulation/scene/battle/hand_size.dart';

void main() {
  test('默认手牌上限为 10', () {
    expect(kBattleHandSizeMax, 10);
  });

  test('抽牌数量按剩余手牌空间截断', () {
    expect(
      getDrawableCardCount(
        requestedCount: 5,
        currentHandSize: 0,
        handSizeMax: 10,
      ),
      5,
    );
    expect(
      getDrawableCardCount(
        requestedCount: 5,
        currentHandSize: 8,
        handSizeMax: 10,
      ),
      2,
    );
    expect(
      getDrawableCardCount(
        requestedCount: 3,
        currentHandSize: 10,
        handSizeMax: 11,
      ),
      1,
    );
  });

  test('满手或超过上限时不再抽牌', () {
    for (final handSize in [10, 12]) {
      expect(
        getDrawableCardCount(
          requestedCount: 5,
          currentHandSize: handSize,
          handSizeMax: 10,
        ),
        0,
      );
    }
  });

  test('非正抽牌请求不产生抽牌', () {
    for (final count in [0, -1]) {
      expect(
        getDrawableCardCount(
          requestedCount: count,
          currentHandSize: 0,
          handSizeMax: 10,
        ),
        0,
      );
    }
  });
}
