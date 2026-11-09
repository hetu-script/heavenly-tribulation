import 'package:flutter_test/flutter_test.dart';
import 'package:heavenly_tribulation/data/game.dart';
import 'package:heavenly_tribulation/logic/logic.dart';

void main() {
  const rootA = 'track_0_0';
  const rootB = 'track_0_1';
  const arcA = 'track_1_0';
  const bridge = 'track_2_0';
  const arcB = 'track_1_1';
  const unreachable = 'track_8_8';

  Map<String, dynamic> characterWith(Set<String> unlocked) => {
        'unlockedPassiveTreeNodes': {for (final id in unlocked) id: true},
      };

  setUp(() {
    GameData.passiveSkills
      ..clear()
      ..addAll({
        rootA: {'isOpen': true},
        rootB: {'isOpen': true},
        arcA: {},
        bridge: {},
        arcB: {},
        unreachable: {},
      });
    GameData.passiveSkillsAdjacency
      ..clear()
      ..addAll({
        rootA: [arcA],
        arcA: [rootA, bridge],
        bridge: [arcA, arcB],
        arcB: [bridge, rootB],
        rootB: [arcB],
        unreachable: [],
      });
  });

  tearDown(() {
    GameData.passiveSkills.clear();
    GameData.passiveSkillsAdjacency.clear();
  });

  test('尚未加点时只开放流派入口', () {
    final character = characterWith({});

    expect(GameLogic.checkPassiveTreeNodeOpen(character, rootA), isTrue);
    expect(GameLogic.checkPassiveTreeNodeOpen(character, rootB), isTrue);
    expect(GameLogic.checkPassiveTreeNodeOpen(character, arcA), isFalse);
    expect(GameLogic.checkPassiveTreeNodeOpen(character, unreachable), isFalse);
  });

  test('选定入口后不能直接选择未连接的其他入口或不可达节点', () {
    final character = characterWith({rootA});

    expect(GameLogic.checkPassiveTreeNodeOpen(character, rootB), isFalse);
    expect(GameLogic.checkPassiveTreeNodeOpen(character, unreachable), isFalse);
    expect(GameLogic.checkPassiveTreeNodeOpen(character, arcA), isTrue);
  });

  test('沿圆弧到达相邻节点后允许解锁其他流派入口', () {
    final character = characterWith({rootA, arcA, bridge, arcB});

    expect(GameLogic.checkPassiveTreeNodeOpen(character, rootB), isTrue);
  });

  test('退回全部节点后恢复所有流派入口', () {
    final character = characterWith({rootA});
    (character['unlockedPassiveTreeNodes'] as Map).clear();

    expect(GameLogic.checkPassiveTreeNodeOpen(character, rootA), isTrue);
    expect(GameLogic.checkPassiveTreeNodeOpen(character, rootB), isTrue);
  });
}
