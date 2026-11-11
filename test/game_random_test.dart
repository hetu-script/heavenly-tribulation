import 'package:flutter_test/flutter_test.dart';
import 'package:hetu_script/hetu_script.dart';
import 'package:heavenly_tribulation/data/game_random.dart';

void main() {
  test('相同 seed 产生相同序列，状态恢复后后续结果一致', () {
    final original = GameRandom(12345);
    final duplicate = GameRandom(12345);
    for (var i = 0; i < 20; ++i) {
      expect(duplicate.nextInt(1000), original.nextInt(1000));
    }

    final savedState = original.state;
    original.nextDouble();
    final expectedInt = original.nextInt(1000);
    final expectedDouble = original.nextDouble();
    final expectedBool = original.nextBool();
    final expectedChoice = original.nextIterable(['a', 'b', 'c']);

    final restored = GameRandom(12345)..state = savedState;
    restored.nextDouble();
    expect(restored.nextInt(1000), expectedInt);
    expect(restored.nextDouble(), expectedDouble);
    expect(restored.nextBool(), expectedBool);
    expect(restored.nextIterable(['a', 'b', 'c']), expectedChoice);
  });

  test('Hetu Random 绑定可以保存并恢复状态', () {
    final hetu = Hetu()..init();
    hetu.interpreter
        .bindExternalClass(GameRandomClassBinding(), override: true);
    hetu.interpreter.bindExternalReflection(
      (object) => object is GameRandom ? 'Random' : null,
    );
    hetu.eval('''
      external class Random {
        constructor([seed: integer])
        var state
        function nextInt(max: integer) -> integer
        function nextDouble() -> float
      }
      function verifyRandomRestore() {
        final random = Random(6789)
        random.nextInt(100)
        final savedState = random.state
        random.nextDouble()
        final expected = random.nextInt(100)
        random.state = savedState
        random.nextDouble()
        return random.nextInt(100) == expected
      }
    ''');

    expect(hetu.invoke('verifyRandomRestore'), true);
  });
}
