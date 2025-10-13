import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:samsara/components/progress_indicator.dart';
import 'package:samsara/components/sprite_button.dart';
import 'package:samsara/utils/math.dart';
import 'package:samsara/components/rich_text_component.dart';
import 'package:samsara/components/hovertip.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:hetu_script/values.dart';
import 'package:provider/provider.dart';

import '../particles/light_point.dart';
import '../../engine.dart';
import '../../game/logic/logic.dart';
import '../../game/ui.dart';
import '../../game/game.dart';
import '../../widgets/ui_overlay.dart';
import '../common.dart';
import '../../game/event_ids.dart';
import '../particles/light_trail.dart';
import '../game_dialog/game_dialog_content.dart';
import '../../state/states.dart';
import '../../game/common.dart';

const _kLightPointMoveSpeed = 450.0;
// const _kButtonAnimationDuration = 1.2;
// const _kExpPerLightPoint = 10;
const _kLightDisplayMax = 100;

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
  collect,
  exhaust,
  none,
}

class CultivationScene extends Scene {
  CultivationScene({
    required super.context,
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

  int collectableExp = 0;

  final _focusNode = FocusNode();

  late final Timer timer;

  bool isMeditating = false;

  void setMeditateState(bool state) {
    if (state) {
      assert(mode != CultivationMode.none);

      if (mode == CultivationMode.collect) {
        final int light = location['collectableLight'] ?? 0;
        if (light <= 0) {
          GameDialogContent.show(
              context, engine.locale('hint_insufficientLight'));
          return;
        }
      } else if (mode == CultivationMode.exhaust) {
        final int shard = GameData.hero['materials']['shard'] ?? 0;
        if (shard <= 0) {
          GameDialogContent.show(
              context, engine.locale('hint_insufficientShard'));
          return;
        }
      }
    }

    isMeditating = state;

    levelUpButton.isEnabled = !state;

    cultivateButton.text =
        isMeditating ? engine.locale('stop') : engine.locale('meditate');

    cultivator.tryLoadSprite(
        spriteId: 'cultivation/cultivator${state ? '' : '2'}.png');

    for (final trail in _lightTrails) {
      trail.isVisible = isMeditating;
    }
  }

  late final SpriteComponent2 timeOfDaySprite;
  late final SpriteComponent backgroundSprite;

  // late final SpriteComponent2 passiveTreeTrack;

  String _cultivatorDescription = '';

  late final SpriteButton cultivator;

  final List<LightPoint> _lightPoints = [];

  final List<LightTrail> _lightTrails = [];

  // late final RichTextComponent expDescription;

  late final RichTextComponent levelDescription;

  late final DynamicColorProgressIndicator expBar;

  late final SpriteButton cultivateButton, levelUpButton;

  final Map<String, SpriteButton> _skillButtons = {};

  final Map<String, SpriteComponent2> _nodeConnections = {};

  FutureOr<void> Function()? onEnterScene;

  bool _showPassiveTree = false;

  void setPassiveTreeState(bool state) {
    _showPassiveTree = state;

    for (final light in _lightPoints) {
      light.isVisible = !_showPassiveTree;
    }
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

  @override
  void onStart([dynamic arguments = const {}]) {
    super.onStart(arguments);

    if (arguments['character'] != null) {
      character = arguments['character'];
    } else if (arguments['characterId'] != null) {
      character = GameData.getCharacter(arguments['characterId']);
    } else {
      character = GameData.hero;
    }

    if (arguments['location'] != null) {
      mode = CultivationMode.collect;
      location = arguments['location'];
    } else {
      if (arguments['enableCultivate'] == true) {
        mode = CultivationMode.exhaust;
      } else {
        mode = CultivationMode.none;
      }
    }

    onEnterScene = arguments['onEnterScene'];
  }

  void updateInformation() {
    String collectableExpString = '';
    final int expCollectEfficiency =
        GameData.hero['stats']['expCollectEfficiency'];
    if (mode == CultivationMode.collect) {
      assert(location != null);
      final int collectableLight = location['collectableLight'] ?? 0;
      collectableExp = collectableLight * expCollectEfficiency;
      collectableExpString =
          '${engine.locale('collectableLight')}: <bold ${collectableLight > 0 ? 'yellow' : 'grey'}>$collectableLight</>';
    } else if (mode == CultivationMode.exhaust) {
      int shard = GameData.hero['materials']['shard'] ?? 0;
      assert(expCollectEfficiency > 0);
      collectableExp = shard * expCollectEfficiency;
      collectableExpString =
          '${engine.locale('availableShard')}: <bold ${shard > 0 ? 'yellow' : 'grey'}>$shard</>';
    }

    String expCollectEfficiencyString =
        '${engine.locale('expCollectEfficiency')}: $expCollectEfficiency';

    // final int expMax = GameData.heroData['expMax'];

    final int skillPoints = character['skillPoints'];
    final pointsString = skillPoints > 0
        ? '<bold yellow>$skillPoints</>'
        : '<bold red>$skillPoints</>';

    final int rank = character['rank'];
    final rankString =
        '<bold rank$rank>${engine.locale('cultivationRank_$rank')}</>';

    levelDescription.text =
        '$collectableExpString $expCollectEfficiencyString\n'
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
    double positionOffsetY = 0.0,
    double duration = 2,
    Color? color,
  }) {
    addHintText(
      text,
      target: cultivator,
      duration: duration,
      textStyle: TextStyle(
        fontSize: 20,
        fontFamily: GameUI.fontFamily,
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

  void _addExpLightPoint(int exp) {
    Vector2 randomPosition;
    do {
      randomPosition =
          generateRandomPointOnCircle(cultivator.center, 640, exponent: 0.2);
    } while (cultivator.containsPoint(randomPosition));
    final lightPoint = LightPoint(
      position: randomPosition,
      flickerRate: 8,
      condensedPosition: GameUI.condensedPosition,
      value: exp,
      priority: _kLightPriority,
    );
    _lightPoints.add(lightPoint);
    world.add(lightPoint);
  }

  /// 出于性能考虑，光点数量上限 200 个
  void updateExpLightPoints({bool clearCache = false}) {
    if (clearCache) {
      for (final light in _lightPoints) {
        light.removeFromParent();
      }
      _lightPoints.clear();
    }

    if (mode == CultivationMode.none) return;

    if (collectableExp <= 0) return;

    final int expPerLightPoint = GameData.hero['stats']['expCollectEfficiency'];
    assert(expPerLightPoint > 0);

    // final int expForLevel = characterData['expForLevel'];

    int expOnExistedLights = 0;
    for (final light in _lightPoints) {
      expOnExistedLights += light.value as int;
    }

    int expToDisplay = collectableExp - expOnExistedLights;

    if (expToDisplay <= 0) return;

    int lightPointCount = collectableExp ~/ expPerLightPoint;
    // int expPerLightPoint = math.max(expForLevel ~/ 20, _kExpPerLightPoint);
    if (lightPointCount > _kLightDisplayMax) {
      // 最多只显示 100 个光点
      lightPointCount = _kLightDisplayMax;
      // kExpPerLightPoint = collectableExp ~/ lightPointCount;
    }
    while (_lightPoints.length < lightPointCount &&
        expToDisplay >= expPerLightPoint) {
      expToDisplay -= expPerLightPoint;

      _addExpLightPoint(expPerLightPoint);
    }
  }

  void _addSkillButton({required String nodeId, required Vector2 position}) {
    final passiveTreeNodeData = GameData.passiveTree[nodeId];

    late SpriteButton skillButton;

    final (isLearned, isOpen) = checkPassiveStatus(nodeId);

    if (passiveTreeNodeData == null) {
      // 还未开放的技能，在debug模式下显示为占位符
      if (engine.config.debugMode) {
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
      // 是否是属性点天赋
      bool isAttribute = passiveTreeNodeData['isAttribute'] ?? false;

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
        // 身法：绿 灵力：蓝 体魄：红 意志：白 神识：黄
        final attributeId = character['unlockedPassiveTreeNodes'][nodeId];
        assert(attributeId is String);
        final attributeSkillData = GameData.passives[attributeId];
        assert(attributeSkillData != null);
        skillButton.tryLoadSprite(spriteId: attributeSkillData['icon']);
      }

      skillButton.onTapUp = (button, position) async {
        final (isLearned, isOpen) = checkPassiveStatus(nodeId);

        if (button == kPrimaryButton) {
          if (isLearned || !isOpen) return;
          Hovertip.hide(skillButton);

          final String? warning =
              GameLogic.checkRequirements(passiveTreeNodeData);
          if (warning != null) {
            GameDialogContent.show(
                context, engine.locale('hint_requirementNotMetForSkill'));
            return;
          }

          if (!isEditorMode) {
            if (character['skillPoints'] <= 0) {
              GameDialogContent.show(
                  context, engine.locale('hint_notEnoughPassiveSkillPoints'));
              return;
            }
          }

          if (isAttribute) {
            // 如果是属性节点，需要特殊处理
            final selectedAttributeId =
                await engine.hetu.invoke('selectHeroAttribute');

            if (selectedAttributeId == null ||
                selectedAttributeId == 'cancel') {
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

          engine.play('click-21156.mp3');
        } else if (button == kSecondaryButton) {
          if (!isLearned) return;
          Hovertip.hide(skillButton);
          skillButton.isSelected = false;
          if (!isEditorMode) {
            ++character['skillPoints'];
          }

          // TODO:检查节点链接，如果有其他节点依赖于该节点，则不能退点

          GameLogic.characterRefundPassiveTreeNode(character, nodeId);

          updatePassivesDescription();
          updateInformation();
          engine.play('click-21156.mp3');
        }
      };

      skillButton.onMouseEnter = () {
        final (isLearned, isOpen) = checkPassiveStatus(nodeId);

        final String? warning =
            GameLogic.checkRequirements(passiveTreeNodeData);

        final skillDescription = StringBuffer();

        if (engine.config.debugMode) {
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
          String attributeDescription = engine.locale(
              attributeSkillData['description'],
              interpolations: ['+${(kAttributeAnyLevel * 0.5).toInt()}']);
          skillDescription.writeln('<lightBlue>$attributeDescription</>');
        } else {
          skillDescription.writeln(passiveTreeNodeData['description']);
        }

        skillDescription.writeln(' ');
        if (isLearned) {
          skillDescription.writeln(engine.locale('passivetree_refund_hint'));
        } else {
          if (isOpen) {
            if (character['skillPoints'] > 0 || isEditorMode) {
              final rankRequirement = passiveTreeNodeData['rank'] ?? 0;
              if (character['rank'] >= rankRequirement) {
                skillDescription
                    .writeln(engine.locale('passivetree_unlock_hint'));
              } else {
                skillDescription
                    .writeln(engine.locale('passivetree_rank_hint'));
              }
            } else {
              skillDescription
                  .writeln(engine.locale('passivetree_points_hint'));
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
    _cultivatorDescription = GameData.getPassivesDescription(character);

    engine.hetu.invoke('calculateStats', namespace: 'Player');
  }

  void _updateTimeOfDay() {
    timeOfDaySprite.tryLoadSprite(spriteId: 'time/${GameLogic.timeOfDay}.png');
  }

  void _tick() async {
    void gainExp() async {
      assert(_lightPoints.isNotEmpty);
      final light = _lightPoints.first;
      await condenseOne(light);
      light.removeFromParent();
      character['exp'] += light.value;
      updateInformation();
      updateExpBar();
      updateExpLightPoints();
    }

    bool breakOut = false;

    if (mode == CultivationMode.collect) {
      if (location['collectableLight'] > 0) {
        location['collectableLight'] -= 1;
        gainExp();
      } else {
        hint(engine.locale('hint_outOfLight'), color: Colors.red);
        breakOut = true;
      }
    } else if (mode == CultivationMode.exhaust) {
      final bool success = engine.hetu.invoke(
        'exhaust',
        namespace: 'Player',
        positionalArgs: ['shard'],
        namedArgs: {'amount': 1},
      );
      if (success) {
        gainExp();
      } else {
        hint(engine.locale('hint_outOfShard'), color: Colors.red);
        breakOut = true;
      }
    }

    if (breakOut) {
      setMeditateState(false);
    } else {
      GameLogic.updateGame();
      _updateTimeOfDay();
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    fps = FpsComponent();

    engine.addEventListener(Scenes.cultivation, GameEvents.heroPassivesUpdated,
        (args) {
      updatePassivesDescription();
    });

    timer = Timer(
      kAutoTimeFlowInterval / 1000,
      repeat: true,
      onTick: _tick,
    );

    timeOfDaySprite = SpriteComponent2(
      position: Vector2(center.x, center.y - 180),
      anchor: Anchor.center,
      priority: _kTimeOfDayPriority,
    );
    world.add(timeOfDaySprite);
    _updateTimeOfDay();

    backgroundSprite = SpriteComponent(
      position: Vector2(center.x, center.y - 130),
      sprite: Sprite(await Flame.images.load('cultivation/cave2.png')),
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
      setPassiveTreeState(!_showPassiveTree);
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

    levelDescription = RichTextComponent(
      position: GameUI.levelDescriptionPosition,
      anchor: Anchor.center,
      size: GameUI.levelDescriptionSize,
      config: ScreenTextConfig(
        outlined: true,
        anchor: Anchor.topCenter,
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: GameUI.fontFamily,
        ),
      ),
    );
    camera.viewport.add(levelDescription);

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
      labelFontFamily: GameUI.fontFamily,
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
      setPassiveTreeState(false);
      setMeditateState(!isMeditating);
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
      spriteId: 'ui/button.png',
    );
    levelUpButton.onTapUp = (button, position) async {
      if (!levelUpButton.isEnabled) return;
      if (button != kPrimaryButton) return;
      tryLevelUp();
      // levelUpButton.enableGesture = false;
      // await condenseAll();
      // levelUpButton.enableGesture = true;
    };
    camera.viewport.add(levelUpButton);

    final exit = GameData.createSiteCard(
      id: 'exit',
      spriteId: 'location/card/exit2.png',
      title: engine.locale('exit'),
      position: GameUI.siteExitCardPositon,
    );
    exit.onTap = (_, __) {
      setMeditateState(false);
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
  void onMount() async {
    context.read<EnemyState>().setPrebattleVisible(false);
    context.read<HoverContentState>().hide();
    context.read<ViewPanelState>().clearAll();

    updateUnlockedNode();
    updatePassivesDescription();
    updateInformation();
    updateExpBar();
    updateExpLightPoints(clearCache: true);
    setMeditateState(false);

    if (mode != CultivationMode.none) {
      setPassiveTreeState(false);
      cultivateButton.isEnabled = true;
    } else {
      setPassiveTreeState(true);
      cultivateButton.isEnabled = false;
    }

    camera.snapTo(center);

    if (GameData.data['enableTutorial'] == true && !isEditorMode) {
      if (GameData.flags['tutorial']['cultivation'] != true) {
        // 修炼界面教程
        GameData.flags['tutorial']['cultivation'] = true;

        dialog.pushDialog('hint_cultivation',
            npc: GameData.data['npcs']['xitong']);
        await dialog.execute();
      }
    }

    await onEnterScene?.call();

    engine.hetu.invoke('onGameEvent', positionalArgs: ['onEnterCultivation']);
  }

  /// 处理角色升级相关逻辑
  void tryLevelUp() {
    int expForLevel = character['expForLevel'];
    int exp = character['exp'];

    if (exp >= expForLevel) {
      // 无论渡劫是否成功，经验值都会被扣除
      exp -= expForLevel;

      bool tribulationCheckResult = GameLogic.checkTribulation();

      if (!tribulationCheckResult) {
        engine.hetu.invoke('levelUp', namespace: 'Player');

        hint(
          '${engine.locale('cultivationLevel')} + 1',
          positionOffsetY: 60,
          color: Colors.yellow,
        );
      } else {
        character['exp'] = exp;
      }

      updateInformation();
      updateExpBar();
    }
  }

  Future<void> condenseOne(LightPoint light) async {
    _lightPoints.remove(light);

    return light.moveTo(
      toPosition: GameUI.condensedPosition,
      duration: light.distance2CondensePoint / _kLightPointMoveSpeed,
      curve: Curves.linear,
    );
  }

  // FutureOr<void> condenseAll() async {
  //   if (_lightPoints.isEmpty) {
  //     return;
  //   }

  //   int exp = characterData['exp'];
  //   final int expForLevel = characterData['expForLevel'];

  //   if (exp >= expForLevel) {
  //     checkEXP();
  //     return;
  //   }

  //   List<Future> futures = [];
  //   for (final light in _lightPoints) {
  //     futures.add(condenseOne(light));
  //     exp += light.value as int;
  //     if (exp > expForLevel) {
  //       break;
  //     }
  //   }

  //   await Future.wait(futures);

  //   checkEXP();
  // }

  @override
  void onTapDown(int pointer, int button, TapDownDetails details) {
    super.onTapDown(pointer, button, details);

    if (button == kSecondaryButton) {
      engine.setCursor(Cursors.drag);
    }
  }

  @override
  void onTapUp(int pointer, int button, TapUpDetails details) {
    super.onTapUp(pointer, button, details);

    if (button == kSecondaryButton) {
      engine.setCursor(Cursors.normal);
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

    _focusNode.requestFocus();

    engine.setCursor(Cursors.normal);
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

    _focusNode.requestFocus();
  }

  @override
  void update(double dt) {
    super.update(dt);

    fps.update(dt);

    if (isMeditating) {
      timer.update(dt);
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    if (engine.config.debugMode || engine.config.showFps) {
      drawScreenText(
        canvas,
        'FPS: ${fps.fps.toStringAsFixed(0)}',
        config: ScreenTextConfig(
          textStyle: const TextStyle(fontSize: 20),
          size: GameUI.size,
          anchor: Anchor.topCenter,
          padding: const EdgeInsets.only(top: 40),
        ),
      );
    }
  }

  @override
  Widget build(
    BuildContext context, {
    Widget Function(BuildContext)? loadingBuilder,
    Map<String, Widget Function(BuildContext, Scene)>? overlayBuilderMap,
    List<String>? initialActiveOverlays,
  }) {
    return KeyboardListener(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          engine.debug('keydown: ${event.logicalKey.debugName}');
          if (event.logicalKey == LogicalKeyboardKey.space) {
            camera.zoom = 1.0;
            camera.snapTo(center);
          }
        }
      },
      child: Stack(
        children: [
          SceneWidget(
            scene: this,
            loadingBuilder: loadingBuilder,
            overlayBuilderMap: overlayBuilderMap,
            initialActiveOverlays: initialActiveOverlays,
          ),
          GameUIOverlay(
            enableHeroInfo: !isEditorMode,
            enableNpcs: false,
            enableCultivation: false,
            enableAutoExhaust: false,
            action: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(color: GameUI.foregroundColor),
              ),
              child: IconButton(
                padding: const EdgeInsets.all(0),
                onPressed: () {
                  GameDialogContent.show(
                    context,
                    engine.locale('hint_cultivation'),
                    style: TextStyle(color: Colors.yellow),
                  );
                },
                icon: Icon(Icons.question_mark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
