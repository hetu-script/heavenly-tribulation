import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:samsara/components/ui/progress_indicator.dart';
import 'package:samsara/components/ui/sprite_button.dart';
import 'package:samsara/utils/math.dart';
import 'package:samsara/components/ui/rich_text_component.dart';
import 'package:samsara/components/ui/hovertip.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:hetu_script/values.dart';
import 'package:provider/provider.dart';
import 'package:samsara/hover_info.dart';
import 'package:samsara/effect/confetti.dart';
import 'package:samsara/cardgame/cardgame.dart';

import '../../extensions.dart';
import '../../global.dart';
import '../../logic/logic.dart';
import '../../ui.dart';
import '../../data/game.dart';
import '../common.dart';
import '../particles/light_trail.dart';
import '../../state/states.dart';
import '../../data/common.dart';
import '../cursor_state.dart';
import '../mini_game/common.dart';
import '../../game_events.dart';
import '../../widgets/common.dart';

const _kOrbMoveSpeed = 450.0;

const _kTimeOfDayPriority = 5;
const _kBackgroundPriority = 10;
// const _kPassiveTreePriority = 15;
const _kCultivatorPriority = 20;
// const _kCultivationRankButtonPriority = 22;
const _kLightPriority = 25;
const _kSkillButtonPriority = 40;

/// 天赋树轨道半径，及轨道上的坐标点数量
const kTrackRadius = [
  (128, 5), // 0, 起始轨道
  (213, 5), // 1,
  (298, 10), // 2,
  (384, 10), // 3,
  (469, 20), // 4, 凝气轨道
  (554, 20), // 5, 筑基轨道
  (640, 40), // 6, 结丹轨道
  (725, 20), // 7,
  (810, 40), // 8,
  (896, 20), // 9,
  (981, 40), // 10,
  (1066, 20), // 11,
  (1152, 40), // 12,
  // (1408)
  // (1664)
];

enum CultivationMode {
  daostele,
  exparray,
  none,
}

const _kBarrierPriority = 100;

/// 问道碑冥想: 每个阶段需要收集的同色光点数量
const kDaoSteleLightTarget = 5;

/// 每种颜色生成的光点数量
const kDaoSteleOrbsPerColor = 5;

/// 冥想总共需要完成的轮数（对应类型、稀有度、流派三次选择）
const kDaoSteleRoundCount = 3;

/// 每轮文字选择中混入的胡言乱语数量
const kDaoSteleNonsenseCount = 4;

/// 每轮文字选择中展示的有效选项数量上限（从全部选项中随机抽取）
const kDaoSteleValidPhraseMax = 4;

/// 光点抖动间隔（秒）
const kDaoSteleVibrateInterval = 0.15;

/// 光点抖动幅度
const kDaoSteleVibrateAmount = 3.0;

/// 胡言乱语（干扰项），点击即失败
const kNonsensePhrases = [
  'meditate_nonsense_1',
  'meditate_nonsense_2',
  'meditate_nonsense_3',
  'meditate_nonsense_4',
  'meditate_nonsense_5',
  'meditate_nonsense_6',
  'meditate_nonsense_7',
  'meditate_nonsense_8',
];

/// 悟道碑冥想 - 第0轮: 卡牌类型（attack / buff）
/// key = locale key, value = 实际值
const kDaoSteleCategoryPhrases = {
  'daostele_phrase_attack_1': 'attack',
  'daostele_phrase_attack_2': 'attack',
  'daostele_phrase_attack_3': 'attack',
  'daostele_phrase_attack_4': 'attack',
  'daostele_phrase_buff_1': 'buff',
  'daostele_phrase_buff_2': 'buff',
  'daostele_phrase_buff_3': 'buff',
  'daostele_phrase_buff_4': 'buff',
};

/// 悟道碑冥想 - 第1轮: 稀有度
const kDaoSteleRarityPhrases = {
  'daostele_phrase_common': 'common',
  'daostele_phrase_rare': 'rare',
  'daostele_phrase_epic': 'epic',
  'daostele_phrase_legendary': 'legendary',
  'daostele_phrase_mythic': 'mythic',
  'daostele_phrase_arcane': 'arcane',
};

/// 悟道碑冥想 - 第2轮: 流派
const kDaoSteleGenrePhrases = {
  'daostele_phrase_neutral': 'neutral',
  'daostele_phrase_swordcraft': 'swordcraft',
  'daostele_phrase_spellcraft': 'spellcraft',
  'daostele_phrase_bodyforge': 'bodyforge',
  'daostele_phrase_avatar': 'avatar',
  'daostele_phrase_vitality': 'vitality',
};

/// 聚灵阵冥想 - 属性类型（attack / buff）
const kExpArrayCategoryPhrases = {
  'exparray_phrase_attack_1': 'attack',
  'exparray_phrase_attack_2': 'attack',
  'exparray_phrase_buff_1': 'defense',
  'exparray_phrase_buff_2': 'defense',
  'exparray_phrase_attribute_1': 'attribute',
  'exparray_phrase_attribute_2': 'attribute',
  'exparray_phrase_energy_1': 'energy',
  'exparray_phrase_energy_2': 'energy',
};

class CultivationScene extends Scene with HasCursorState {
  CultivationScene({
    this.isEditorMode = false,
  }) : super(
          id: Scenes.cultivation,
          enableLighting: true,
        );

  late FpsComponent fps;

  dynamic character;

  final bool isEditorMode;

  dynamic location;

  late CultivationMode mode;

  bool get isDaoStele => mode == CultivationMode.daostele;
  bool get isExpArray => mode == CultivationMode.exparray;

  String? _daoSteleCategory;
  String? _daoSteleRarity;
  String? _daoSteleGenre;
  CustomGameCard? _revealedCard;
  late final SpriteButton collectButton;

  // 冥想共享状态（问道碑和聚灵阵共用，同一时间只会有一种模式在运行）
  /// 0=聚光阶段, 1=选文阶段, -1=空闲
  int _meditatePhase = -1;
  int _meditateRound = 0;
  int _meditateLightCollected = 0;
  String? _meditateTargetColor;
  final List<SpriteButton> _meditateOrbs = [];
  final List<SpriteButton> _meditatePhrases = [];
  double _meditateVibrateTimer = 0;

  // 聚灵阵专用状态
  int _expArrayMaxRounds = 1;
  final List<String> _expArrayGrantedBuffs = [];

  late final SpriteComponent2 barrier;

  late final SpriteComponent newRankPrompt;

  late final SpriteButton rankInfo;

  late final SpriteButton confirm;

  late final Timer timer;

  bool isMeditating = false;

  void setMeditateState(CultivationMode state) {
    if (state == CultivationMode.none) {
      isMeditating = false;
      _resetMeditation();
    } else {
      isMeditating = true;
    }

    levelUpButton.isEnabled = !isMeditating;

    cultivateButton.text =
        isMeditating ? engine.locale('stop') : engine.locale('meditate');

    cultivator.tryLoadSprite(
        spriteId: 'cultivation/cultivator${isMeditating ? '' : '2'}.png');

    for (final trail in _lightTrails) {
      trail.isVisible = isMeditating;
    }
  }

  late final SpriteComponent2 timeOfDaySprite;
  late final SpriteComponent backgroundSprite;

  // late final SpriteComponent2 passiveTreeTrack;

  String _cultivatorDescription = '';

  late final SpriteButton cultivator;

  final List<LightTrail> _lightTrails = [];

  // late final RichTextComponent expDescription;

  late final RichTextComponent statusDescription;

  late final DynamicColorProgressIndicator expBar;

  late final SpriteButton cultivateButton, levelUpButton;

  final Map<String, SpriteButton> _skillButtons = {};

  final Map<String, SpriteComponent2> _nodeConnections = {};

  FutureOr<void> Function()? onEnterScene;

  bool _showPassiveTree = false;

  void setPassiveTreeState(bool state) {
    _showPassiveTree = state;

    for (final trail in _lightTrails) {
      trail.isVisible = isMeditating && !_showPassiveTree;
    }

    // passiveTreeTrack.isVisible = state;
    for (final button in _skillButtons.values) {
      button.isVisible = _showPassiveTree;
    }
    for (final line in _nodeConnections.values) {
      line.isVisible = _showPassiveTree;
    }
  }

  void updateInformation() {
    final int rank = character['rank'];
    final rankString =
        '<bold rank$rank>${engine.locale('cultivationRank_$rank')}</>';

    final int skillPoints = character['skillPoints'];
    final pointsString = skillPoints > 0
        ? '<bold yellow>$skillPoints</>'
        : '<bold red>$skillPoints</>';

    statusDescription.text =
        '${engine.locale('cultivationLevel')}: ${character['level']} '
        '${engine.locale('cultivationRank')}: $rankString '
        '${engine.locale('skillPoints')}: $pointsString';
  }

  void updateExpBar() {
    expBar.setValue(character['exp']);
    expBar.max = GameLogic.expForLevel(character['level']);
  }

  void hint(
    String text, {
    double duration = 2,
    Color? color,
  }) {
    addHintText(
      text,
      target: cultivator,
      duration: duration,
      offsetY: 60.0,
      textStyle: TextStyle(
        fontSize: 20,
        fontFamily: GameUI.fontFamilyKaiti,
        color: color,
      ),
      onViewport: false,
    );
  }

  /// 返回的两个bool值分别表示技能是否已经学习，以及技能是否可以学习
  (bool, bool) checkPassiveStatus(String nodeId) {
    final passiveTreeNodeData = GameData.passiveTree[nodeId];
    final unlockedNodes = character['unlockedPassiveTreeNodes'] as HTStruct;
    final isLearned = unlockedNodes.contains(nodeId);
    // 可以学的技能，如果邻近的父节点无一解锁，则无法学习
    // 如果父节点数据是空的，则是入口节点，直接可以学习
    final List? connectedNodes = passiveTreeNodeData?['connectedNodes'];
    bool isOpen =
        passiveTreeNodeData?['isOpen'] ?? connectedNodes?.isEmpty ?? true;
    if (!isOpen) {
      for (final node in connectedNodes!) {
        if (unlockedNodes.contains(node)) {
          isOpen = true;
          break;
        }
      }
    }
    return (isLearned, isOpen);
  }

  Future<String?> selectHeroAttribute() async {
    final selections = {};
    for (final key in kBattleAttributes) {
      final attrName = engine.locale(key);
      final attrDescription = engine.locale('${key}_description');
      selections[key] = {
        'text': attrName,
        'description':
            '$attrDescription\n${engine.locale('current')}$attrName: ${GameData.hero['stats'][key]}',
      };
    }
    selections['cancel'] = engine.locale('cancel');

    dialog.pushSelectionRaw({
      'id': 'selectedAttribute',
      'selections': selections,
    });
    await dialog.execute();
    final selected = dialog.checkSelected('selectedAttribute');
    return selected;
  }

  Future<void> onSkillButtonTapUp(
      SpriteButton skillButton, String nodeId, int button) async {
    final (isLearned, isOpen) = checkPassiveStatus(nodeId);
    final passiveTreeNodeData = GameData.passiveTree[nodeId];
    bool isAttribute = passiveTreeNodeData['isAttribute'] ?? false;

    if (button == kPrimaryButton) {
      if (isLearned || !isOpen) return;
      Hovertip.hide(skillButton);

      // final String? warning = GameLogic.checkRequirements(passiveTreeNodeData);
      // if (warning != null) {
      //   dialog.pushDialog('hint_requirementNotMetForSkill$warning');
      //   dialog.execute();
      //   return;
      // }

      if (!isEditorMode) {
        if (character['skillPoints'] <= 0) {
          dialog.pushDialog('hint_notEnoughPassiveSkillPoints');
          dialog.execute();
          return;
        }

        // 境界节点: 触发突破试炼
        final rankRequirement = passiveTreeNodeData['rank'] ?? 0;
        if (rankRequirement == character['rank'] + 1) {
          tryTribulation(skillButton, nodeId);
          return;
        }
      }

      if (isAttribute) {
        // 如果是属性节点，需要特殊处理
        final selectedAttributeId = await selectHeroAttribute();

        if (selectedAttributeId == null || selectedAttributeId == 'cancel') {
          return;
        }

        GameLogic.characterUnlockPassiveTreeNode(
          character,
          nodeId,
          selectedAttributeId: selectedAttributeId,
        );

        skillButton.tryLoadSprite(
            spriteId: GameData.passives[selectedAttributeId]['icon']);
      } else {
        GameLogic.characterUnlockPassiveTreeNode(character, nodeId);
      }
      skillButton.isSelected = true;
      if (!isEditorMode) {
        --character['skillPoints'];
      }

      updatePassivesDescription();
      updateInformation();

      engine.play(GameSound.click);
    } else if (button == kSecondaryButton) {
      if (!isLearned) return;

      // 境界节点不可退点
      final rankRequirement = passiveTreeNodeData['rank'] ?? 0;
      if (rankRequirement > 0) {
        dialog.pushDialog('passivetree_rank_node_no_refund_hint');
        dialog.execute();
        return;
      }

      Hovertip.hide(skillButton);
      skillButton.isSelected = false;
      if (!isEditorMode) {
        ++character['skillPoints'];
      }

      // TODO:检查节点链接，如果有其他节点依赖于该节点，则不能退点

      GameLogic.characterRefundPassiveTreeNode(character, nodeId);

      updatePassivesDescription();
      updateInformation();
      engine.play(GameSound.click);
    }
  }

  void onSkillButtonMouseEnter(SpriteButton skillButton, String nodeId) {
    final (isLearned, isOpen) = checkPassiveStatus(nodeId);
    final passiveTreeNodeData = GameData.passiveTree[nodeId];
    bool isAttribute = passiveTreeNodeData['isAttribute'] ?? false;
    final String? warning = GameLogic.checkRequirements(passiveTreeNodeData);

    final skillDescription = StringBuffer();

    if (engine.config.developMode) {
      skillDescription.write('<grey>$nodeId</>\n \n');
    }

    if (isAttribute && isLearned) {
      // 只有已经学习过的属性节点需要特殊处理
      // 其他情况下的节点描述文字已经在游戏载入时预先生成过了
      skillDescription.writeln(
          '<bold yellow>${engine.locale('passivetree_attribute_any')}</>');
      skillDescription.writeln(' ');

      final attributeId = character['unlockedPassiveTreeNodes'][nodeId];
      assert(attributeId is String);
      final attributeSkillData = GameData.passives[attributeId];
      assert(attributeSkillData != null);
      String attributeDescription = engine
          .locale(attributeSkillData['description'], interpolations: [
        '+${(kPassiveTreeAttributeAnyLevel * 0.5).toInt()}'
      ]);
      skillDescription.writeln('<lightBlue>$attributeDescription</>');
    } else {
      skillDescription.writeln(passiveTreeNodeData['description']);
    }

    skillDescription.writeln(' ');
    if (isLearned) {
      final rankRequirement = passiveTreeNodeData['rank'] ?? 0;
      if (rankRequirement > 0) {
        skillDescription
            .writeln(engine.locale('passivetree_rank_node_no_refund_hint'));
      } else {
        skillDescription.writeln(engine.locale('passivetree_refund_hint'));
      }
    } else {
      if (isOpen) {
        final rankRequirement = passiveTreeNodeData['rank'] ?? 0;
        if (rankRequirement > 0 && character['rank'] < rankRequirement) {
          // 境界节点: 需要突破试炼
          if (character['skillPoints'] > 0 || isEditorMode) {
            skillDescription.writeln(engine.locale('passivetree_rank_hint'));
          } else {
            skillDescription
                .writeln(engine.locale('passivetree_rank_no_points_hint'));
          }
        } else if (character['skillPoints'] > 0 || isEditorMode) {
          skillDescription.writeln(engine.locale('passivetree_unlock_hint'));
        } else {
          skillDescription.writeln(engine.locale('passivetree_points_hint'));
        }
      } else {
        skillDescription.writeln(engine.locale('passivetree_locked_hint'));
      }
    }

    if (warning != null) {
      skillDescription.writeln(warning);
    }

    Hovertip.show(
      scene: this,
      target: skillButton,
      direction: HovertipDirection.rightTop,
      content: skillDescription.toString(),
    );
  }

  void _addSkillButton({required String nodeId, required Vector2 position}) {
    final passiveTreeNodeData = GameData.passiveTree[nodeId];

    late SpriteButton skillButton;

    if (passiveTreeNodeData == null) {
      // 还未开放的技能，在debug模式下显示为占位符
      if (engine.config.developMode) {
        skillButton = SpriteButton(
          anchor: Anchor.center,
          position: position,
          size: GameUI.skillButtonSizeSmall,
          spriteId: 'cultivation/skill/wip.png',
          isVisible: false,
          priority: _kSkillButtonPriority,
        );
        skillButton.onMouseEnter = () {
          Hovertip.show(
            scene: this,
            target: skillButton,
            direction: HovertipDirection.rightTop,
            content: '<grey>$nodeId</>',
          );
        };
        skillButton.onMouseExit = () {
          Hovertip.hide(skillButton);
        };
      } else {
        return;
      }
    } else {
      // 已经开发完毕，写好数据的技能
      bool isAttribute = passiveTreeNodeData['isAttribute'] ?? false;
      final (isLearned, isOpen) = checkPassiveStatus(nodeId);

      final buttonSize = switch (passiveTreeNodeData['size']) {
        'large' => GameUI.skillButtonSizeLarge,
        'medium' => GameUI.skillButtonSizeMedium,
        _ => GameUI.skillButtonSizeSmall,
      };

      skillButton = SpriteButton(
        anchor: Anchor.center,
        position: position,
        size: buttonSize,
        spriteId: passiveTreeNodeData['icon'],
        unselectedSpriteId: isAttribute
            ? 'cultivation/skill/attribute_any_unselected.png'
            : passiveTreeNodeData['unselectedIcon'],
        isVisible: false,
        isSelectable: true,
        isSelected: isLearned,
        priority: _kSkillButtonPriority,
        // isEnabled: isOpen,
        lightConfig: LightConfig(radius: 25),
      );

      if (isAttribute && isLearned) {
        // 如果是属性节点，需要特殊处理
        // 分配新的属性天赋点时，从五种属性中选择一种，并获得3点该属性值
        // 分配后，按钮也会相应变成对应该属性的颜色
        // 身法: 绿 灵力: 蓝 体魄: 红 意志: 白 神识: 黄
        final attributeId = character['unlockedPassiveTreeNodes'][nodeId];
        assert(attributeId is String);
        final attributeSkillData = GameData.passives[attributeId];
        assert(attributeSkillData != null);
        skillButton.tryLoadSprite(spriteId: attributeSkillData['icon']);
      }

      skillButton.onTapUp = (button, position) async {
        onSkillButtonTapUp(skillButton, nodeId, button);
      };

      skillButton.onMouseEnter = () {
        onSkillButtonMouseEnter(skillButton, nodeId);
      };

      skillButton.onMouseExit = () {
        Hovertip.hide(skillButton);
      };
    }

    _skillButtons[nodeId] = skillButton;
    // _skillButtons.add(button);
    world.add(skillButton);
  }

  void updateUnlockedNode() {
    final unlockedNodes = character['unlockedPassiveTreeNodes'];
    for (final nodeId in unlockedNodes.keys) {
      final button = _skillButtons[nodeId];
      assert(button != null);
      button!.isSelected = true;
      final passiveTreeNodeData = GameData.passiveTree[nodeId];
      if (passiveTreeNodeData['isAttribute'] == true) {
        final String attributeId = unlockedNodes[nodeId];
        button.tryLoadSprite(spriteId: GameData.passives[attributeId]['icon']);
      }
    }
  }

  void updatePassivesDescription() {
    _cultivatorDescription =
        GameData.getPassivesDescription(character: character);

    engine.hetu.invoke('calculateStats', namespace: 'Player');
  }

  void updateTimeOfDay() {
    timeOfDaySprite.tryLoadSprite(spriteId: 'time/${GameLogic.timeString}.png');
  }

  // ── 冥想共享逻辑 ──

  /// 根据轮次获取该轮的有效文字选项
  Map<String, String> getPhrasesForRound(int round) {
    switch (round) {
      case 0:
        return kDaoSteleCategoryPhrases;
      case 1:
        return kDaoSteleGenrePhrases;
      case 2:
        assert(location != null);
        int maxRank =
            math.min(character['rank'] as int, location['development'] as int);
        return Map.fromEntries(
          kDaoSteleRarityPhrases.entries
              .where((e) => (kRaritiesToRank[e.value] ?? 0) <= maxRank),
        );
      default:
        return {};
    }
  }

  /// 从有效选项中随机抽取一部分，确保每个 value 至少出现一次
  List<MapEntry<String, String>> selectValidPhrases(
      Map<String, String> allPhrases, math.Random random) {
    // 先按 value 分组
    final byValue = <String, List<MapEntry<String, String>>>{};
    for (final entry in allPhrases.entries) {
      byValue.putIfAbsent(entry.value, () => []).add(entry);
    }

    // 每个 value 至少选一个
    final selected = <MapEntry<String, String>>[];
    for (final entries in byValue.values) {
      entries.shuffle(random);
      selected.add(entries.first);
    }

    // 如果超过上限，随机裁剪（保留每个value至少一个）
    if (selected.length > kDaoSteleValidPhraseMax) {
      selected.shuffle(random);
      // 保留每个value一个，多余的从尾部移除
      final seen = <String>{};
      final kept = <MapEntry<String, String>>[];
      for (final entry in selected) {
        if (!seen.contains(entry.value) ||
            kept.length < kDaoSteleValidPhraseMax) {
          kept.add(entry);
          seen.add(entry.value);
        }
      }
      return kept.take(kDaoSteleValidPhraseMax).toList();
    }

    return selected;
  }

  /// 随机抽取胡言乱语
  List<String> selectNonsensePhrases(math.Random random) {
    final shuffled = List<String>.from(kNonsensePhrases)..shuffle(random);
    return shuffled.take(kDaoSteleNonsenseCount).toList();
  }

  /// 清除冥想中的所有临时组件
  void _clearMeditateComponents() {
    for (final orb in _meditateOrbs) {
      orb.removeFromParent();
    }
    _meditateOrbs.clear();
    for (final phrase in _meditatePhrases) {
      phrase.removeFromParent();
    }
    _meditatePhrases.clear();
  }

  /// 进入聚光阶段（问道碑和聚灵阵共用）
  void _startLightPhase() {
    _clearMeditateComponents();
    _meditatePhase = 0;
    _meditateLightCollected = 0;
    _meditateTargetColor = null;

    hint(
      engine.locale('meditate_hint_light_phase'),
      duration: 3,
      color: Colors.amberAccent,
    );

    for (final colorId in RankedColors.values.keys) {
      for (var i = 0; i < kDaoSteleOrbsPerColor; i++) {
        Vector2 pos;
        do {
          pos = generateRandomPointOnCircle(center, 350, exponent: 0.3);
        } while (cultivator.containsPoint(pos));

        final orbColor = RankedColors.values[colorId]!;
        final orb = SpriteButton(
          spriteId: 'sprite/light_point.png',
          color: orbColor,
          position: pos,
          size: Vector2(60, 60),
          anchor: Anchor.center,
          priority: _kLightPriority,
          lightConfig: LightConfig(radius: 30, color: orbColor),
        );
        final capturedColor = colorId;
        final capturedOrb = orb;
        orb.onTap = (_, __) {
          _onOrbTap(capturedColor, capturedOrb);
        };
        _meditateOrbs.add(orb);
        world.add(orb);
      }
    }
  }

  /// 玩家点击了一个光点（问道碑和聚灵阵共用）
  void _onOrbTap(String colorId, SpriteButton orb) {
    if (_meditatePhase != 0) return;

    if (_meditateTargetColor == null) {
      // 第一次点击，确定目标颜色
      _meditateTargetColor = colorId;
      _meditateLightCollected = 1;
      orb.removeFromParent();
      _meditateOrbs.remove(orb);
      hint(
        '${engine.locale('meditate_hint_light_collected')} $_meditateLightCollected/$kDaoSteleLightTarget',
        color: Colors.lightBlueAccent,
      );
      engine.play(GameSound.click);
      _advanceTime();
    } else if (colorId == _meditateTargetColor) {
      // 正确颜色
      _meditateLightCollected++;
      orb
          .moveTo(
              toPosition: GameUI.condensedPosition,
              duration: orb.center.distanceTo(center) / _kOrbMoveSpeed,
              curve: Curves.linear)
          .then((_) {
        orb.removeFromParent();
      });
      _meditateOrbs.remove(orb);
      hint(
        '${engine.locale('meditate_hint_light_collected')} $_meditateLightCollected/$kDaoSteleLightTarget',
        color: Colors.lightBlueAccent,
      );
      engine.play(GameSound.click);
      _advanceTime();

      if (_meditateLightCollected >= kDaoSteleLightTarget) {
        // 聚光完成，进入选文阶段
        if (isDaoStele) {
          _startDaoSteleTextPhase();
        } else {
          _startExpArrayTextPhase();
        }
      }
    } else {
      // 错误颜色，冥想失败
      _advanceTime();
      _meditationFail('meditate_hint_wrong_color');
    }
  }

  /// 冥想失败（问道碑和聚灵阵共用）
  void _meditationFail(String hintKey) {
    hint(
      engine.locale(hintKey),
      duration: 3,
      color: GameColors.lightRed,
    );
    engine.play(GameSound.error);
    _clearMeditateComponents();
    _meditatePhase = -1;
    setMeditateState(CultivationMode.none);
  }

  /// 停止冥想时清理状态
  void _resetMeditation() {
    _clearMeditateComponents();
    _meditatePhase = -1;
    _meditateRound = 0;
    _meditateLightCollected = 0;
    _meditateTargetColor = null;
    _meditateVibrateTimer = 0;
  }

  /// 冥想中每次交互触发的时间流逝
  Future<void> _advanceTime() async {
    final int development = location?['development'] ?? 0;
    final double developmentBonus = 1.0 + development * 0.25;
    int medidateSpeed = GameData.hero['stats']['medidateSpeed'];
    int timeCost = math.max(
        1, (kTicksPerTime / (medidateSpeed * developmentBonus)).round());

    updateInformation();

    await GameLogic.updateGame(ticks: timeCost);
    updateTimeOfDay();
  }

  // ── 问道碑冥想 ──

  /// 开始一次完整的问道碑冥想（3轮）
  void _startDaoSteleMeditation() {
    _meditateRound = 0;
    _daoSteleCategory = null;
    _daoSteleRarity = null;
    _daoSteleGenre = null;
    setMeditateState(mode);
    _startLightPhase();
  }

  /// 进入问道碑选文阶段: 生成漂浮的文字选项
  void _startDaoSteleTextPhase() {
    _clearMeditateComponents();
    _meditatePhase = 1;

    hint(
      engine.locale('meditate_hint_text_phase'),
      duration: 3,
      color: Colors.amberAccent,
    );

    var allPhrases = getPhrasesForRound(_meditateRound);
    // 稀有度轮次: 根据角色境界和据点发展度限制可选稀有度
    final validPhrases = selectValidPhrases(allPhrases, random);
    final nonsensePhrases = selectNonsensePhrases(random);

    // 构建所有文字选项: (localeKey, value?) — value 为 null 表示胡言乱语
    final allOptions = <(String, String?)>[];
    for (final entry in validPhrases) {
      allOptions.add((entry.key, entry.value));
    }
    for (final key in nonsensePhrases) {
      allOptions.add((key, null));
    }
    allOptions.shuffle(random);

    // 在修炼者周围环形布局
    final positions = generateDividingPointsOnCircle(
        center: center, radius: 150, number: allOptions.length);

    for (var i = 0; i < allOptions.length; i++) {
      final (localeKey, value) = allOptions[i];
      final text = engine.locale(localeKey);
      final pos = positions[i].position;

      final phrase = SpriteButton(
        spriteId: 'ui/button.png',
        text: text,
        position: pos,
        size: GameUI.buttonSizeSmall,
        anchor: Anchor.center,
        priority: _kLightPriority + 5,
      );
      // phrase.opacity = 0.65;
      final capturedValue = value;
      phrase.onTap = (_, __) {
        _onDaoStelePhraseTap(capturedValue);
      };
      _meditatePhrases.add(phrase);
      world.add(phrase);
    }
  }

  /// 问道碑: 玩家点击了一个文字选项
  void _onDaoStelePhraseTap(String? value) {
    if (_meditatePhase != 1) return;

    if (value == null) {
      // 点击了胡言乱语，冥想失败
      _advanceTime();
      _meditationFail('meditate_hint_nonsense');
      return;
    }

    // 记录本轮选择结果
    switch (_meditateRound) {
      case 0:
        _daoSteleCategory = value;
      case 1:
        _daoSteleGenre = value;
      case 2:
        _daoSteleRarity = value;
    }

    hint(
      engine.locale('meditate_hint_round_complete'),
      color: Colors.lightGreenAccent,
    );
    engine.play(GameSound.click);
    _advanceTime();

    _meditateRound++;

    if (_meditateRound >= kDaoSteleRoundCount) {
      // 三轮完成，生成卡牌
      _daoSteleMeditationComplete();
    } else {
      // 进入下一轮的聚光阶段
      _startLightPhase();
    }
  }

  /// 问道碑冥想成功，生成并展示卡牌
  void _daoSteleMeditationComplete() {
    _clearMeditateComponents();
    _meditatePhase = -1;
    showDaoSteleCard();
  }

  // ── 聚灵阵冥想 ──

  /// 开始一次完整的聚灵阵冥想
  void _startExpArrayMeditation() async {
    final int development = location?['development'] ?? 0;
    final int cost = development + 1;

    int exhausted = engine.hetu.invoke(
      'exhaust',
      namespace: 'Player',
      positionalArgs: ['shard', cost],
    );
    if (exhausted != cost) {
      dialog.pushDialog('exparray_hint_insufficient_shard');
      dialog.execute();
      return;
    }

    _meditateRound = 0;
    _expArrayMaxRounds = development + 1;
    _expArrayGrantedBuffs.clear();
    setMeditateState(mode);

    hint(
      engine.locale('exparray_hint_start'),
      duration: 3,
      color: Colors.amberAccent,
    );

    _startLightPhase();
  }

  /// 进入聚灵阵选文阶段
  void _startExpArrayTextPhase() {
    _clearMeditateComponents();
    _meditatePhase = 1;

    hint(
      engine.locale('meditate_hint_text_phase'),
      duration: 3,
      color: Colors.amberAccent,
    );

    final validPhrases = selectValidPhrases(kExpArrayCategoryPhrases, random);
    final nonsensePhrases = selectNonsensePhrases(random);

    final allOptions = <(String, String?)>[];
    for (final entry in validPhrases) {
      allOptions.add((entry.key, entry.value));
    }
    for (final key in nonsensePhrases) {
      allOptions.add((key, null));
    }
    allOptions.shuffle(random);

    final positions = generateDividingPointsOnCircle(
        center: center, radius: 150, number: allOptions.length);

    for (var i = 0; i < allOptions.length; i++) {
      final (localeKey, value) = allOptions[i];
      final text = engine.locale(localeKey);
      final pos = positions[i].position;

      final phrase = SpriteButton(
        spriteId: 'ui/button.png',
        text: text,
        position: pos,
        size: GameUI.buttonSizeSmall,
        anchor: Anchor.center,
        priority: _kLightPriority + 5,
      );
      final capturedValue = value;
      phrase.onTap = (_, __) {
        _onExpArrayPhraseTap(capturedValue);
      };
      _meditatePhrases.add(phrase);
      world.add(phrase);
    }
  }

  /// 聚灵阵: 玩家点击了一个文字选项
  void _onExpArrayPhraseTap(String? value) {
    if (_meditatePhase != 1) return;

    if (value == null) {
      _advanceTime();
      _meditationFail('meditate_hint_nonsense');
      return;
    }

    // 调用 Hetu 生成并赋予该类别的随机 buff
    final int rank = character['rank'] as int;
    engine.hetu.invoke(
      'getExpArrayBuff',
      namespace: 'Player',
      positionalArgs: [value, rank],
    );

    hint(
      engine.locale('meditate_buff_acquired'),
      color: Colors.lightGreenAccent,
    );
    engine.play(GameSound.click);
    _advanceTime();

    _expArrayGrantedBuffs.add(value);
    _meditateRound++;

    if (_meditateRound >= _expArrayMaxRounds) {
      _expArrayMeditationComplete();
    } else {
      hint(
        engine.locale('exparray_hint_round',
            interpolations: ['${_meditateRound + 1}']),
        duration: 2,
        color: Colors.amberAccent,
      );
      _startLightPhase();
    }
    updatePassivesDescription();
  }

  /// 聚灵阵冥想成功完成
  void _expArrayMeditationComplete() {
    _clearMeditateComponents();
    _meditatePhase = -1;
    hint(
      engine.locale('exparray_hint_complete'),
      duration: 3,
      color: Colors.lightGreenAccent,
    );
    setMeditateState(CultivationMode.none);
  }

  void tick() async {
    // 问道碑和聚灵阵的时间流逝都由玩家交互触发，tick 中不再自动消耗时间
  }

  Future<void> showDaoSteleCard() async {
    // 暂停打坐
    setMeditateState(CultivationMode.none);

    // 根据玩家选择的类型、稀有度和流派生成卡牌
    final int rank = kRaritiesToRank[_daoSteleRarity] ?? 0;
    final String genre =
        _daoSteleGenre == 'neutral' ? 'none' : (_daoSteleGenre ?? 'none');

    final cardData = engine.hetu.invoke(
      'BattleCard',
      namedArgs: {
        'category': _daoSteleCategory,
        'genre': genre,
        'rank': rank,
      },
    );

    final card = GameData.createBattleCard(cardData);
    _revealedCard = card;

    card.preferredPriority = _kBarrierPriority + 1;
    card.resetPriority();
    card.size = GameUI.craftCardSize;
    card.anchor = Anchor.center;
    card.position = Vector2(center.x, center.y - 30);
    card.isFlipped = true;

    card.onTapUp = (int button, Vector2 position) {
      if (card.isFlipped) {
        engine.play(GameSound.craft);
        card.isFlipped = false;
        final (description, _) = GameData.getBattleCardDescription(card.data);
        card.description = description;
      }
    };

    card.onPreviewed = () {
      card.showGlow = true;
      if (card.isFlipped) return;
      previewCard(
        'cardpack_card_${card.id}',
        card.data,
        card.toAbsoluteRect(),
        character: GameData.hero,
      );
    };
    card.onUnpreviewed = () {
      card.showGlow = false;
      if (card.isFlipped) return;
      unpreviewCard();
    };

    barrier.isVisible = true;
    camera.viewport.add(card);
    collectButton.isVisible = true;

    engine.play(GameSound.dealCard);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    fps = FpsComponent();

    engine.addEventListener(Scenes.cultivation, GameEvents.heroPassivesUpdated,
        (args) {
      if (!isMounted) return;
      updatePassivesDescription();
    });

    timer = Timer(
      kTimeFlowInterval / 1000,
      repeat: true,
      onTick: tick,
    );

    timeOfDaySprite = SpriteComponent2(
      position: Vector2(center.x, center.y - 180),
      anchor: Anchor.center,
      priority: _kTimeOfDayPriority,
    );
    world.add(timeOfDaySprite);
    updateTimeOfDay();

    barrier = SpriteComponent2(
      size: size,
      color: GameUI.barrierColor,
      isVisible: false,
      priority: _kBarrierPriority,
      enableGesture: true,
    );
    camera.viewport.add(barrier);

    newRankPrompt = SpriteComponent(
      anchor: Anchor.center,
      position: Vector2(center.x, center.y - 125),
      sprite: await Sprite.load('rank_up.png'),
      size: Vector2(800.0, 220.0),
      priority: _kBarrierPriority,
    );

    rankInfo = SpriteButton(
      anchor: Anchor.center,
      position: center,
      size: Vector2(125.0, 125.0),
      isVisible: false,
      priority: _kBarrierPriority,
    );
    rankInfo.onMouseEnter = () {
      Hovertip.show(
        scene: this,
        target: rankInfo,
        direction: HovertipDirection.topCenter,
        config: ScreenTextConfig(textAlign: TextAlign.center),
        content: engine
            .locale('cultivationRank_${GameData.hero['rank']}_description'),
      );
    };
    rankInfo.onMouseExit = () {
      Hovertip.hide(rankInfo);
    };
    camera.viewport.add(rankInfo);

    confirm = SpriteButton(
      spriteId: 'ui/button2.png',
      size: GameUI.buttonSizeMedium,
      anchor: Anchor.center,
      position: Vector2(
          center.x,
          newRankPrompt.bottomRight.y +
              GameUI.buttonSizeMedium.y +
              GameUI.largeIndent),
      text: engine.locale('confirm'),
      isVisible: false,
      priority: _kBarrierPriority,
    );
    confirm.onTap = (_, __) async {
      newRankPrompt.removeFromParent();
      barrier.isVisible = false;
      rankInfo.isVisible = false;
      confirm.isVisible = false;
      // 通知教程系统境界突破成功
      await engine.hetu.invoke('onGameEvent', positionalArgs: ['onHeroRankUp']);
    };
    camera.viewport.add(confirm);

    collectButton = SpriteButton(
      spriteId: 'ui/button2.png',
      size: GameUI.buttonSizeMedium,
      anchor: Anchor.center,
      position: GameUI.craftZoneCloseButtonPosition,
      text: engine.locale('confirm'),
      isVisible: false,
      priority: _kBarrierPriority + 1,
    );
    collectButton.onTap = (_, __) {
      if (_revealedCard == null) return;

      engine.hetu.invoke(
        'acquireCard',
        namespace: 'Player',
        positionalArgs: [_revealedCard!.data],
      );

      hint(
        engine.locale('meditate_card_acquired'),
        color: Colors.lightGreen,
      );

      _revealedCard!.removeFromParent();
      _revealedCard = null;
      barrier.isVisible = false;
      collectButton.isVisible = false;

      engine.play(GameSound.dealCard);
    };
    camera.viewport.add(collectButton);

    backgroundSprite = SpriteComponent(
      position: Vector2(center.x, center.y - 130),
      sprite: await Sprite.load('cultivation/cave2.png'),
      anchor: Anchor.center,
      priority: _kBackgroundPriority,
    );
    world.add(backgroundSprite);

    cultivator = SpriteButton(
      anchor: Anchor.center,
      spriteId: 'cultivation/cultivator2.png',
      position: GameUI.cultivatorPosition,
      size: GameUI.cultivatorSize,
      priority: _kCultivatorPriority,
      lightConfig: LightConfig(
        radius: 250,
        blurBorder: 500,
        shape: LightShape.circle,
        lightCenter: GameUI.condensedPosition,
      ),
    );
    cultivator.onTapUp = (button, position) async {
      if (isEditorMode) return;
      if (isMeditating) return;
      if (button == kPrimaryButton) {
        setPassiveTreeState(!_showPassiveTree);
      }
    };
    cultivator.onMouseEnter = () {
      String description;
      if (_showPassiveTree) {
        description =
            '<yellow>${engine.locale('hint_cultivateMode')}</>\n \n$_cultivatorDescription';
      } else {
        description =
            '<yellow>${engine.locale('hint_passiveTreeMode')}</>\n \n$_cultivatorDescription';
      }
      Hovertip.show(
        scene: this,
        target: cultivator,
        direction: HovertipDirection.rightTop,
        content: description,
        config: ScreenTextConfig(textAlign: TextAlign.left),
      );
    };
    cultivator.onMouseExit = () {
      Hovertip.hide(cultivator);
    };
    // cultivator.enableGesture = false;
    world.add(cultivator);

    statusDescription = RichTextComponent(
      position: GameUI.levelDescriptionPosition,
      anchor: Anchor.center,
      size: GameUI.levelDescriptionSize,
      config: ScreenTextConfig(
        outlined: true,
        anchor: Anchor.topCenter,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: GameUI.fontFamilyKaiti,
        ),
      ),
    );
    camera.viewport.add(statusDescription);

    final int convertedExp = character['exp'];
    final int expForLevel = character['expForLevel'];
    expBar = DynamicColorProgressIndicator(
      anchor: Anchor.center,
      position: GameUI.expBarPosition,
      size: GameUI.expBarSize,
      borderRadius: 5,
      label: '${engine.locale('exp')}: ',
      value: convertedExp,
      max: expForLevel,
      showNumber: true,
      colors: [Colors.lightBlue, Colors.deepPurple],
      borderPaint: Paint()
        ..color = Colors.white
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
      labelFontFamily: GameUI.fontFamilyKaiti,
    );
    camera.viewport.add(expBar);

    cultivateButton = SpriteButton(
      text: engine.locale('meditate'),
      anchor: Anchor.center,
      position: GameUI.collectButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
    );
    cultivateButton.onTapUp = (button, position) async {
      if (!cultivateButton.isEnabled) return;
      if (button != kPrimaryButton) return;
      if (isMeditating) {
        setMeditateState(CultivationMode.none);
      } else {
        if (isDaoStele) {
          _startDaoSteleMeditation();
        } else if (isExpArray) {
          _startExpArrayMeditation();
        }
      }
      setPassiveTreeState(false);
    };
    cultivateButton.onMouseEnter = () {
      String hint = engine.locale('hint_cultivate');
      if (!cultivateButton.isEnabled) {
        hint += '\n \n${engine.locale('functionDisabled')}';
      }
      Hovertip.show(
        scene: this,
        target: cultivateButton,
        content: hint,
      );
    };
    cultivateButton.onMouseExit = () {
      Hovertip.hide(cultivateButton);
    };
    camera.viewport.add(cultivateButton);

    levelUpButton = SpriteButton(
      text: engine.locale('levelUp'),
      anchor: Anchor.center,
      position: GameUI.levelUpButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button1.png',
    );
    levelUpButton.onTapUp = (button, position) async {
      if (!levelUpButton.isEnabled) return;
      if (button == kPrimaryButton) {
        tryLevelUp();
      }
    };
    camera.viewport.add(levelUpButton);

    final exit = GameData.createSiteCard(
      id: 'exit',
      spriteId: 'location/card/exit2.png',
      title: engine.locale('exit'),
      position: GameUI.siteExitCardPositon,
    );
    exit.onTap = (_, __) {
      setMeditateState(CultivationMode.none);
      engine.context.read<EnemyState>().setPrebattleVisible();
      engine.popScene();
    };
    camera.viewport.add(exit);

    for (var i = 0; i < kTrackRadius.length; i++) {
      final radius = kTrackRadius[i].$1;
      final count = kTrackRadius[i].$2;
      final track = generateDividingPointsOnCircle(
          center: center, radius: radius.toDouble(), number: count);
      for (var j = 0; j < track.length; j++) {
        final id = 'track_${i}_$j';
        _addSkillButton(
          nodeId: id,
          position: track[j].position,
        );
      }
    }

    for (final nodeId in _skillButtons.keys) {
      final passiveTreeNodeData = GameData.passiveTree[nodeId];

      if (passiveTreeNodeData != null) {
        final button = _skillButtons[nodeId]!;
        final connectedNodes = passiveTreeNodeData['connectedNodes'];
        if (connectedNodes is List) {
          for (final positionId in connectedNodes) {
            assert(positionId != nodeId);
            final lineId1 = '$nodeId-$positionId';
            final lineId2 = '$positionId-$nodeId';
            if (_nodeConnections.containsKey(lineId1) ||
                _nodeConnections.containsKey(lineId2)) {
              continue;
            }
            final connectedButton = _skillButtons[positionId];
            if (connectedButton != null) {
              final distance = math.sqrt(
                  math.pow(connectedButton.center.x - button.center.x, 2) +
                      math.pow(connectedButton.center.y - button.center.y, 2));
              final angle = math.atan2(
                  connectedButton.center.y - button.center.y,
                  connectedButton.center.x - button.center.x);

              final line = SpriteComponent2(
                isVisible: false,
                position: button.center,
                size: Vector2(distance, 20.0),
                angle: angle,
                spriteId: 'cultivation/line_1.png',
                anchor: Anchor.centerLeft,
                priority: _kSkillButtonPriority - 1,
              );
              _nodeConnections[lineId1] = line;
              world.add(line);
            }
          }
        }
      }
    }

    final lightTrailCoordinates1 =
        generateDividingPointsOnCircle(center: center, radius: 200, number: 24);
    _lightTrails.addAll([
      LightTrail(
        radius: 200,
        index: 0,
        points: lightTrailCoordinates1,
      ),
      LightTrail(
        radius: 200,
        index: 8,
        points: lightTrailCoordinates1,
      ),
      LightTrail(
        radius: 200,
        index: 16,
        points: lightTrailCoordinates1,
      ),
    ]);

    final lightTrailCoordinates2 =
        generateDividingPointsOnCircle(center: center, radius: 350, number: 30);
    _lightTrails.addAll([
      LightTrail(
        radius: 350,
        index: 0,
        points: lightTrailCoordinates2,
      ),
      LightTrail(
        radius: 350,
        index: 6,
        points: lightTrailCoordinates2,
      ),
      LightTrail(
        radius: 350,
        index: 12,
        points: lightTrailCoordinates2,
      ),
      LightTrail(
        radius: 350,
        index: 18,
        points: lightTrailCoordinates2,
      ),
      LightTrail(
        radius: 350,
        index: 24,
        points: lightTrailCoordinates2,
      ),
    ]);

    final lightTrailCoordinates3 =
        generateDividingPointsOnCircle(center: center, radius: 500, number: 36);
    _lightTrails.addAll([
      LightTrail(
        radius: 500,
        index: 0,
        points: lightTrailCoordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 4,
        points: lightTrailCoordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 8,
        points: lightTrailCoordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 12,
        points: lightTrailCoordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 16,
        points: lightTrailCoordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 20,
        points: lightTrailCoordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 24,
        points: lightTrailCoordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 28,
        points: lightTrailCoordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 32,
        points: lightTrailCoordinates3,
      ),
    ]);

    for (final lightTrail in _lightTrails) {
      world.add(lightTrail);
    }
  }

  @override
  void onStart([dynamic arguments = const {}]) {
    super.onStart(arguments);

    engine.context.read<EnemyState>().setPrebattleVisible(false);
    engine.context.read<ViewPanelState>().clearAll();
    engine.context.read<HoverContentState>().hide();

    if (arguments['characterId'] != null) {
      character = GameData.getCharacter(arguments['characterId']);
    } else {
      character = GameData.hero;
    }

    if (arguments['location'] != null) {
      location = arguments['location'];

      final kind = location?['kind'] ?? location?['category'];
      if (kind == 'daostele') {
        mode = CultivationMode.daostele;
      } else if (kind == 'exparray') {
        mode = CultivationMode.exparray;
      } else {
        mode = CultivationMode.none;
      }
    } else {
      if (arguments['mode'] == 'daostele') {
        mode = CultivationMode.daostele;
      } else if (arguments['mode'] == 'exparray') {
        mode = CultivationMode.exparray;
      } else {
        mode = CultivationMode.none;
      }
    }

    engine.addEventListener(Scenes.cultivation, GameEvents.keyBoardEvent,
        (event) {
      if (!isMounted) return;
      if (event is KeyDownEvent) {
        switch (event.logicalKey) {
          case LogicalKeyboardKey.space:
            camera.zoom = 1.0;
            camera.snapTo(center);
        }
      }
    });

    onEnterScene = arguments['onEnterScene'];
  }

  @override
  void onMount() async {
    super.onMount();

    camera.snapTo(center);

    cursorState = MouseCursorState.normal;
    Hovertip.hideAll();

    cultivateButton.isEnabled = mode != CultivationMode.none;

    updateUnlockedNode();
    updatePassivesDescription();
    setMeditateState(CultivationMode.none);
    updateInformation();
    updateExpBar();

    setPassiveTreeState(mode == CultivationMode.none);

    if (GameData.game['enableTutorial'] == true && !isEditorMode) {
      if (GameData.flags['tutorial']['cultivation'] != true) {
        // 修炼界面教程
        GameData.flags['tutorial']['cultivation'] = true;

        dialog.pushDialog('hint_cultivation',
            npc: GameData.game['npcs']['xitong']);
        await dialog.execute();
      }
    }

    await onEnterScene?.call();

    engine.hetu.invoke('onGameEvent', positionalArgs: ['onEnterCultivation']);
  }

  /// 点击境界节点时触发突破试炼
  Future<void> tryTribulation(SpriteButton skillButton, String nodeId) async {
    final passiveTreeNodeData = GameData.passiveTree[nodeId];
    if (passiveTreeNodeData == null) return;

    final int difficulty = passiveTreeNodeData['rank'] ?? 0;
    assert(difficulty == character['rank'] + 1);

    if (!isEditorMode) {
      if (character['skillPoints'] <= 0) {
        dialog.pushDialog('hint_notEnoughPassiveSkillPoints');
        dialog.execute();
        return;
      }
    }

    // 教程提示
    if (GameData.game['enableTutorial'] == true) {
      if (GameData.flags['tutorial']['tribulation'] != true) {
        GameData.flags['tutorial']['tribulation'] = true;
        dialog.pushDialog('passivetree_tribulation_intro');
        await dialog.execute();
      }
    }

    // 选择试炼方式
    dialog.pushDialog('passivetree_tribulation_prompt2');
    await dialog.execute();

    dialog.pushSelection('tribulationMethod', ['yes', 'forgetIt']);
    await dialog.execute();
    final selected = dialog.checkSelected('tribulationMethod');
    if (selected == null || selected == 'forgetIt') return;

    void onTribulationSuccess() {
      GameLogic.characterUnlockPassiveTreeNode(character, nodeId);
      skillButton.isSelected = true;
      --character['skillPoints'];
      character['rank'] = difficulty;
      updatePassivesDescription();
      updateInformation();
      // engine.play(GameSound.click);
      barrier.isVisible = true;
      camera.viewport.add(newRankPrompt);
      rankInfo.tryLoadSprite(
          spriteId: 'cultivation/cultivation$difficulty.png');
      rankInfo.isVisible = true;
      confirm.isVisible = true;
      engine.play(GameSound.ascension);

      final celebration = ConfettiEffect(
        position: Vector2.zero(),
        size: size,
        priority: kConfettiPriority,
      );
      camera.viewport.add(celebration);

      Future.delayed(const Duration(milliseconds: 500), () {
        confirm.isVisible = true;
      });
    }

    // if (selected == 'tribulation_martial') {
    // 进入天道战斗
    final level = GameLogic.maxLevelForRank(difficulty - 1);

    bool isDifficultyDecreased = false;
    if (GameData.hero['passives']['decreaseTribulationDifficulty'] != null) {
      isDifficultyDecreased = true;
      GameData.hero['passives'].remove('decreaseTribulationDifficulty');
      dialog.pushDialog('tribulation_difficulty_decreased');
      await dialog.execute();
    }

    GameLogic.showTribulation(
        level, isDifficultyDecreased ? difficulty - 1 : difficulty,
        onResult: (bool result) {
      if (result) {
        onTribulationSuccess();
      } else {
        dialog.pushDialog('passivetree_tribulation_fail');
        dialog.execute();
      }
    });
    // } else if (selected == 'tribulation_literary') {
    //   // 随机进入一种小游戏。难度和节点本身的境界有关。
    //   final sceneId =
    //       kMiniGameScenes[math.Random().nextInt(kMiniGameScenes.length)];

    //   final miniGameDifficulty = MiniGameDifficulty.values[difficulty];
    //   engine.pushScene(sceneId, arguments: {
    //     'difficulty': miniGameDifficulty.name,
    //     'onGameEnd': (bool won) {
    //       if (won) {
    //         onTribulationSuccess();
    //       } else {
    //         dialog.pushDialog('passivetree_tribulation_fail');
    //         dialog.execute();
    //       }
    //     },
    //   });
    // }
  }

  /// 处理角色升级相关逻辑
  void tryLevelUp() {
    int level = character['level'];
    int rank = character['rank'];
    int maxLevel = GameLogic.maxLevelForRank(rank);
    int exp = character['exp'];
    int expForLevel = character['expForLevel'];

    if (exp < expForLevel) return;

    if (level < maxLevel) {
      exp -= expForLevel;
      engine.hetu.invoke('levelUp', namespace: 'Player');
      hint('修为等级 + 1', color: Colors.yellow);
    } else {
      dialog.pushDialog('hint_tribulation_5');
      dialog.execute();
    }

    updateInformation();
    updateExpBar();
  }

  @override
  void onTapDown(int pointer, int button, TapDownDetails details) {
    super.onTapDown(pointer, button, details);

    if (button == kSecondaryButton) {
      cursorState = MouseCursorState.drag;
      Hovertip.hideAll();
    }
  }

  @override
  void onTapUp(int pointer, int button, TapUpDetails details) {
    super.onTapUp(pointer, button, details);

    if (button == kSecondaryButton) {
      cursorState = MouseCursorState.normal;
    }
  }

  @override
  void onDragUpdate(int pointer, int button, DragUpdateDetails details) {
    super.onDragUpdate(pointer, button, details);

    if (button == kSecondaryButton) {
      camera.moveBy(-details.delta.toVector2() / camera.zoom);
    }
  }

  @override
  void onDragEnd(int pointer, int button, TapUpDetails details) {
    super.onDragEnd(pointer, button, details);

    cursorState = MouseCursorState.normal;
  }

  @override
  void onMouseScroll(MouseScrollDetails details) {
    super.onMouseScroll(details);

    final delta = details.scrollDelta.dy;
    if (delta > 0) {
      if (camera.zoom > 0.4) {
        camera.zoom -= 0.1;
      }
    } else if (delta < 0) {
      if (camera.zoom < 1) {
        camera.zoom += 0.1;
      }
    }
  }

  @override
  void update(double dt) {
    super.update(dt);

    fps.update(dt);

    if (isMeditating) {
      timer.update(dt);

      // 冥想中的组件抖动效果
      if (_meditatePhase >= 0) {
        _meditateVibrateTimer += dt;
        if (_meditateVibrateTimer >= kDaoSteleVibrateInterval) {
          _meditateVibrateTimer -= kDaoSteleVibrateInterval;
          for (final orb in _meditateOrbs) {
            orb.position.x +=
                (random.nextDouble() - 0.5) * 2 * kDaoSteleVibrateAmount;
            orb.position.y +=
                (random.nextDouble() - 0.5) * 2 * kDaoSteleVibrateAmount;
          }
          for (final phrase in _meditatePhrases) {
            phrase.position.x +=
                (random.nextDouble() - 0.5) * 2 * kDaoSteleVibrateAmount;
            phrase.position.y +=
                (random.nextDouble() - 0.5) * 2 * kDaoSteleVibrateAmount;
          }
        }
      }
    }
  }

  // @override
  // void render(Canvas canvas) {
  //   super.render(canvas);

  //   // if (engine.config.developMode || engine.config.showFps) {
  //   //   drawScreenText(
  //   //     canvas,
  //   //     'FPS: ${fps.fps.toStringAsFixed(0)}',
  //   //     config: ScreenTextConfig(
  //   //       textStyle: const TextStyle(fontSize: 20),
  //   //       size: GameUI.size,
  //   //       anchor: Anchor.topCenter,
  //   //       padding: const EdgeInsets.only(top: 40),
  //   //     ),
  //   //   );
  //   // }
  // }

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext)? loadingBuilder,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
    List<String>? initialActiveOverlays,
  }) {
    return Stack(
      children: [
        SceneWidget(
          scene: this,
          loadingBuilder: loadingBuilder,
          overlayBuilderMap: overlayBuilderMap,
          initialActiveOverlays: initialActiveOverlays,
        ),
        GameUIOverlay(
          showHero: !isEditorMode,
          showNpcs: false,
          enableCultivation: false,
          actions: [
            Container(
              decoration: GameUI.boxDecoration,
              width: GameUI.infoButtonSize.width,
              height: GameUI.infoButtonSize.height,
              child: IconButton(
                icon: Icon(Icons.question_mark),
                padding: const EdgeInsets.all(0),
                mouseCursor: GameUI.cursor.resolve({WidgetState.hovered}),
                onPressed: () {
                  dialog.pushDialog('hint_cultivation');
                  dialog.execute();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }
}
