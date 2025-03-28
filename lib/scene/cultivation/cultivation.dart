import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/common.dart';
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
import 'package:hetu_script/utils/math.dart' as math;

import 'exp_light_point.dart';
import '../../engine.dart';
import '../../game/logic.dart';
import '../../game/ui.dart';
import '../../game/data.dart';
import '../game_dialog/selection_dialog.dart';
import '../../widgets/ui_overlay.dart';
import '../common.dart';
import '../../game/event_ids.dart';
import 'light_trail.dart';
import '../game_dialog/game_dialog_content.dart';

const _kLightPointMoveSpeed = 450.0;
// const _kButtonAnimationDuration = 1.2;
const _kExpPerLightPoint = 10;

const _kTimeOfDayPriority = 5;
const _kBackgroundPriority = 10;
// const _kPassiveTreePriority = 15;
const _kCultivatorPriority = 20;
// const _kCultivationRankButtonPriority = 22;
const _kLightPriority = 25;
const _kSkillButtonPriority = 40;

const _kLightDisplayMax = 100;

/// 天赋树轨道半径，及轨道上的坐标点数量
const kTrackRadius = [
  (128, 5), // 0, 起始轨道
  (213, 5), // 1,
  (298, 10), // 2,
  (384, 10), // 3,
  (469, 20), // 4, 凝气轨道
  (554, 20), // 5,
  (640, 20), // 6,
  (725, 20), // 7,
  (810, 40), // 8, 筑基轨道
  (896, 20), // 9,
  (981, 20), // 10,
  (1066, 20), // 11,
  (1152, 40), // 12, 结丹轨道
  // (1408)
  // (1664)
];

class CultivationScene extends Scene {
  CultivationScene({
    required super.context,
    bool talentTreeMode = false,
  }) : super(id: Scenes.cultivation, enableLighting: true);

  static final random = math.Random();

  final _focusNode = FocusNode();

  late final Timer timer;

  bool isMeditating = false;

  void setMeditatingState(bool state) {
    isMeditating = state;
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

  String _heroSkillsDescription = '';

  late final SpriteButton cultivator;

  final List<ExpLightPoint> _lightPoints = [];

  final List<LightTrail> _lightTrails = [];

  // late final RichTextComponent expDescription;

  late final RichTextComponent levelDescription;

  late final DynamicColorProgressIndicator expBar;

  late final SpriteButton cultivationRankButton,
      cardPacksButton,
      cardLibraryButton,
      cultivateButton,
      expCollectionButton;

  final Map<String, SpriteButton> _skillButtons = {};

  final List<SpriteComponent2> _nodeConnections = [];

  bool _showPassiveTree = false;

  void setPassiveTreeState(bool state) {
    _showPassiveTree = state;

    cultivateButton.isVisible = !_showPassiveTree;
    expCollectionButton.isVisible = !_showPassiveTree;
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
    for (final line in _nodeConnections) {
      line.isVisible = _showPassiveTree;
    }
  }

  Future<void> _onEnterScene() async {
    updateHeroPassivesDescription();
    udpateLevelDescription();
    updateExpDescription();
    addExpLightPoints();

    engine.hetu.invoke('onGameEvent', positionalArgs: ['onEnterCultivation']);
  }

  @override
  void onMount() {
    super.onMount();

    _onEnterScene();
  }

  @override
  void onStart([Map<String, dynamic> arguments = const {}]) {
    super.onStart(arguments);

    if (isLoaded) {
      _onEnterScene();
    }
  }

  void udpateLevelDescription() {
    final int unconvertedExp = GameData.heroData['unconvertedExp'];
    final unconvertedExpString = unconvertedExp > 0
        ? '<bold yellow>$unconvertedExp</>'
        : '<bold red>$unconvertedExp</>';

    final int skillPoints = GameData.heroData['skillPoints'];
    final pointsString = skillPoints > 0
        ? '<bold yellow>$skillPoints</>'
        : '<bold red>$skillPoints</>';

    final int rank = GameData.heroData['rank'];
    final rankString =
        '<bold rank$rank>${engine.locale('cultivationRank_$rank')}</>';

    levelDescription.text =
        '${engine.locale('unconvertedExp')}: $unconvertedExpString ${engine.locale('skillPoints')}: $pointsString\n'
        '${engine.locale('cultivationLevel2')}: ${GameData.heroData['level']} ${engine.locale('cultivationRank')}: $rankString';
  }

  void updateExpDescription() {
    expBar.setValue(GameData.heroData['exp']);
    expBar.max = GameLogic.expForLevel(GameData.heroData['level']);
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
    final unlockedNodes =
        GameData.heroData['unlockedPassiveTreeNodes'] as HTStruct;
    final isLearned = unlockedNodes.contains(nodeId);
    // 可以学的技能，如果邻近的父节点无一解锁，则无法学习
    // 如果父节点数据是空的，则是入口节点，直接可以学习
    final List? parentNodes = passiveTreeNodeData?['parentNodes'];
    bool isOpen =
        passiveTreeNodeData?['isOpen'] ?? parentNodes?.isEmpty ?? true;
    if (!isOpen) {
      for (final parent in parentNodes!) {
        if (unlockedNodes.contains(parent)) {
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
          generateRandomPointInCircle(cultivator.center, 640, exponent: 0.2);
    } while (cultivator.containsPoint(randomPosition));
    final lightPoint = ExpLightPoint(
      position: randomPosition,
      flickerRate: 8,
      condensedPosition: GameUI.condensedPosition,
      exp: exp,
      priority: _kLightPriority,
    );
    lightPoint.onTapDown = (int buttons, __) {
      if (buttons != kPrimaryButton) return;
      condenseOne(lightPoint, () {
        checkEXP();
      });
    };
    lightPoint.onDragOver = (int buttons, __) {
      if (buttons != kPrimaryButton) return;
      condenseOne(lightPoint, () {
        checkEXP();
      });
    };
    _lightPoints.add(lightPoint);
    world.add(lightPoint);
  }

  /// 出于性能考虑，永远只显示足以升到下一级的光点
  void addExpLightPoints() {
    final int unconvertedExp = GameData.heroData['unconvertedExp'];
    if (unconvertedExp <= 0) return;

    final int expForLevel = GameData.heroData['expForLevel'];

    int expOnExistedLights = 0;
    for (final light in _lightPoints) {
      expOnExistedLights += light.exp;
    }
    int expToDisplay = unconvertedExp - expOnExistedLights;
    if (expToDisplay <= 0) return;

    int lightPointCount = unconvertedExp ~/ _kExpPerLightPoint;
    int expPerLightPoint = math.max(expForLevel ~/ 20, _kExpPerLightPoint);
    if (lightPointCount > _kLightDisplayMax) {
      // 最多只显示 100 个光点
      lightPointCount = _kLightDisplayMax;
      expPerLightPoint = unconvertedExp ~/ lightPointCount;
    }
    while (_lightPoints.length < lightPointCount &&
        expToDisplay >= expPerLightPoint) {
      expToDisplay -= expPerLightPoint;

      _addExpLightPoint(expPerLightPoint);
    }
    if (expToDisplay > 0) {
      _addExpLightPoint(expToDisplay);
    }
  }

  void _addGenreSkillButton(
      {required String nodeId, required Vector2 position}) {
    final passiveTreeNodeData = GameData.passiveTree[nodeId];

    late SpriteButton button;

    final (isLearned, isOpen) = checkPassiveStatus(nodeId);

    if (passiveTreeNodeData == null) {
      // 还未开放的技能，在debug模式下显示为占位符
      if (kDebugMode) {
        button = SpriteButton(
          anchor: Anchor.center,
          position: position,
          size: GameUI.skillButtonSizeSmall,
          spriteId: 'cultivation/skill/wip.png',
          isVisible: false,
          priority: _kSkillButtonPriority,
        );
        button.onMouseEnter = () {
          Hovertip.show(
            scene: this,
            target: button,
            direction: HovertipDirection.rightTop,
            content: '<grey>$nodeId</>',
          );
        };
        button.onMouseExit = () {
          Hovertip.hide(button);
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

      button = SpriteButton(
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
        final attributeId =
            GameData.heroData['unlockedPassiveTreeNodes'][nodeId];
        assert(attributeId is String);
        final attributeSkillData = GameData.passives[attributeId];
        assert(attributeSkillData != null);
        button.tryLoadSprite(spriteId: attributeSkillData['icon']);
      }

      button.onTapUp = (buttons, position) async {
        final (isLearned, isOpen) = checkPassiveStatus(nodeId);

        if (buttons == kPrimaryButton) {
          if (isLearned || !isOpen) return;
          Hovertip.hide(button);

          final rank = passiveTreeNodeData['rank'] ?? 0;
          if (GameData.heroData['rank'] < rank) {
            GameDialogContent.show(
                context, engine.locale('hint_rankRequirementNotMet'));
            return;
          }

          if (GameData.heroData['skillPoints'] > 0) {
            button.isSelected = true;
            --GameData.heroData['skillPoints'];

            if (isAttribute) {
              // 如果是属性节点，需要特殊处理
              final selectedAttributeId =
                  await SelectionDialog.show(context, selectionsData: {
                'selections': {
                  'dexterity': engine.locale('dexterity'),
                  'spirituality': engine.locale('spirituality'),
                  'strength': engine.locale('strength'),
                  'willpower': engine.locale('willpower'),
                  'perception': engine.locale('perception'),
                  'cancel': engine.locale('cancel'),
                },
              });
              if (selectedAttributeId == null ||
                  selectedAttributeId == 'cancel') {
                return;
              }

              GameLogic.characterUnlockPassiveTreeNode(
                GameData.heroData,
                nodeId,
                selectedAttributeId: selectedAttributeId,
              );

              button.tryLoadSprite(
                  spriteId: GameData.passives[selectedAttributeId]['icon']);
            } else {
              GameLogic.characterUnlockPassiveTreeNode(
                  GameData.heroData, nodeId);
            }

            updateHeroPassivesDescription();
            udpateLevelDescription();

            engine.play('click-21156.mp3');
          } else {
            GameDialogContent.show(
                context, engine.locale('hint_notEnoughPassiveSkillPoints'));
          }
        } else if (buttons == kSecondaryButton) {
          if (!isLearned) return;
          Hovertip.hide(button);
          button.isSelected = false;
          // TODO:检查节点链接，如果有其他节点依赖于该节点，则不能退点

          ++GameData.heroData['skillPoints'];

          GameLogic.characterRefundPassiveTreeNode(GameData.heroData, nodeId);

          updateHeroPassivesDescription();
          udpateLevelDescription();
          engine.play('click-21156.mp3');
        }
      };

      button.onMouseEnter = () {
        final (isLearned, isOpen) = checkPassiveStatus(nodeId);

        StringBuffer skillDescription = StringBuffer();

        if (kDebugMode) {
          skillDescription.write('<grey>$nodeId</>\n \n');
        }

        if (isAttribute && isLearned) {
          // 只有已经学习过的属性节点需要特殊处理
          // 其他情况下的节点描述文字已经在游戏载入时预先生成过了
          skillDescription.writeln(
              '<bold yellow>${engine.locale('passivetree_attribute_any')}</>');
          skillDescription.writeln(' ');

          final attributeId =
              GameData.heroData['unlockedPassiveTreeNodes'][nodeId];
          assert(attributeId is String);
          final attributeSkillData = GameData.passives[attributeId];
          assert(attributeSkillData != null);
          String attributeDescription = engine.locale(
              attributeSkillData['description'],
              interpolations: [kAttributeAnyLevel]);
          skillDescription.writeln('<lightBlue>$attributeDescription</>');
        } else {
          skillDescription.writeln(passiveTreeNodeData['description']);
        }

        skillDescription.writeln(' ');
        if (isLearned) {
          skillDescription.writeln(engine.locale('passivetree_refund_hint'));
        } else {
          if (isOpen) {
            if (GameData.heroData['skillPoints'] > 0) {
              final rankRequirement = passiveTreeNodeData['rank'] ?? 0;
              if (GameData.heroData['rank'] >= rankRequirement) {
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

        Hovertip.show(
          scene: this,
          target: button,
          direction: HovertipDirection.rightTop,
          content: skillDescription.toString(),
        );
      };

      button.onMouseExit = () {
        Hovertip.hide(button);
      };
    }

    _skillButtons[nodeId] = button;
    // _skillButtons.add(button);
    world.add(button);
  }

  void updateHeroPassivesDescription() {
    _heroSkillsDescription = GameData.getHeroPassivesDescription();
    engine.hetu.invoke('calculateStats', namespace: 'Player');
  }

  void _updateTimeOfDay() {
    final timeOfDay = engine.hetu.fetch('timeOfDay');

    timeOfDaySprite.tryLoadSprite(spriteId: 'time/$timeOfDay.png');
  }

  void _tick() async {
    await engine.hetu.invoke('updateGame');
    _updateTimeOfDay();

    final bool success = engine.hetu.invoke(
      'exhaust',
      namespace: 'Player',
      positionalArgs: ['shard'],
      namedArgs: {
        'amount': 1,
        'incurIncident': false,
      },
    );
    if (success) {
      GameData.heroData['unconvertedExp'] +=
          GameData.heroData['stats']['expCollectEfficiency'];

      hint('${engine.locale('shard')} -1', color: Colors.yellow);
      updateExpDescription();
      addExpLightPoints();
    } else {
      hint(engine.locale('insufficientShard'), color: Colors.red);
    }
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    engine.addEventListener(Scenes.cultivation, GameEvents.heroPassivesUpdated,
        (args) {
      updateHeroPassivesDescription();
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

    // passiveTreeTrack = SpriteComponent2(
    //   isVisible: false,
    //   position: GameUI.cultivatorPosition,
    //   spriteId: 'cultivation/skill_tree_tracks.png',
    //   anchor: Anchor.center,
    //   priority: _kPassiveTreePriority,
    // );
    // world.add(passiveTreeTrack);

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
    cultivator.onTapUp = (buttons, position) async {
      if (isMeditating) return;
      setPassiveTreeState(!_showPassiveTree);
    };
    cultivator.onMouseEnter = () {
      Hovertip.show(
        scene: this,
        target: cultivator,
        direction: HovertipDirection.rightTop,
        content: _heroSkillsDescription,
      );
    };
    cultivator.onMouseExit = () {
      Hovertip.hide(cultivator);
    };
    // cultivator.enableGesture = false;
    world.add(cultivator);

    // final rankImagePath =
    //     'cultivation/cultivation${GameData.heroData['rank']}.png';

    // cultivationRankButton = SpriteButton(
    //   anchor: Anchor.center,
    //   sprite: Sprite(await Flame.images.load(rankImagePath)),
    //   position: GameUI.condensedPosition,
    //   size: GameUI.cultivationRankButton,
    //   priority: _kCultivationRankButtonPriority,
    // );
    // cultivationRankButton.onTap = (buttons, position) async {
    //   if (state == CultivationSceneState.expCollection) {
    //     await condenseAll();
    //     checkEXP();
    //   }
    // };
    // world.add(cultivationRankButton);

    // expDescription = RichTextComponent(
    //   position: cultivator.bottomCenter + Vector2(0, GameUI.indent),
    //   anchor: Anchor.center,
    //   size: GameUI.levelDescriptionSize,
    //   priority: _kCultivatorPriority,
    //   config: ScreenTextConfig(
    //     outlined: true,
    //     anchor: Anchor.topCenter,
    //     textStyle: const TextStyle(
    //       color: Colors.lightGreenAccent,
    //       fontSize: 16,
    //       fontFamily: GameUI.fontFamily,
    //     ),
    //   ),
    // );
    // world.add(expDescription);

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

    final int convertedExp = GameData.heroData['exp'];
    final int expForLevel = GameData.heroData['expForLevel'];
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
    cultivateButton.onTapUp = (buttons, position) async {
      if (buttons != kPrimaryButton) return;
      setMeditatingState(!isMeditating);
    };
    camera.viewport.add(cultivateButton);

    expCollectionButton = SpriteButton(
      text: engine.locale('autoCollectAll'),
      anchor: Anchor.center,
      position: GameUI.cultivateButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button.png',
    );
    expCollectionButton.onTapUp = (buttons, position) async {
      if (buttons != kPrimaryButton) return;
      setMeditatingState(false);
      expCollectionButton.enableGesture = false;
      await condenseAll();
      expCollectionButton.enableGesture = true;
    };
    camera.viewport.add(expCollectionButton);

    final exit = GameData.createSiteCard(
      id: 'exit',
      spriteId: 'location/card/exit2.png',
      title: engine.locale('exit'),
      position: GameUI.siteExitCardPositon,
    );
    exit.onTap = (_, __) {
      setMeditatingState(false);
      engine.popScene();
    };
    camera.viewport.add(exit);

    updateHeroPassivesDescription();
    udpateLevelDescription();
    updateExpDescription();
    addExpLightPoints();

    for (var i = 0; i < kTrackRadius.length; i++) {
      final radius = kTrackRadius[i].$1;
      final count = kTrackRadius[i].$2;
      final track = generateDividingPointsFromCircle(
          center.x, center.y, radius.toDouble(), count);
      for (var j = 0; j < track.length; j++) {
        final id = 'track_${i}_$j';
        _addGenreSkillButton(
          nodeId: id,
          position: track[j].position,
        );
      }
    }

    for (final nodeId in _skillButtons.keys) {
      final passiveTreeNodeData = GameData.passiveTree[nodeId];

      if (passiveTreeNodeData != null) {
        final button = _skillButtons[nodeId]!;
        final bool reverseParent =
            passiveTreeNodeData['reverseParent'] ?? false;
        final parentNodes = passiveTreeNodeData['parentNodes'];
        if (parentNodes is List) {
          for (final parentPositionId in parentNodes) {
            final parentTrackInfo = parentPositionId.split('_');
            final parentTrackId = int.parse(parentTrackInfo[1]);
            final parentTrackPos = int.parse(parentTrackInfo[2]);
            final nodeTrackInfo = nodeId.split('_');
            final nodeTrackId = int.parse(nodeTrackInfo[1]);
            final nodeTrackPos = int.parse(nodeTrackInfo[2]);
            if (((!reverseParent &&
                    parentTrackId == nodeTrackId &&
                    parentTrackPos > nodeTrackPos) ||
                (!reverseParent && parentTrackId > nodeTrackId))) {
              // 如果在同一轨道上，且父节点在子节点之前，略过
              // 如果在不同轨道上，且父节点在更靠外的轨道，略过
              continue;
            }
            final parentButton = _skillButtons[parentPositionId];
            if (parentButton != null) {
              final distance = math.sqrt(
                  math.pow(parentButton.center.x - button.center.x, 2) +
                      math.pow(parentButton.center.y - button.center.y, 2));
              final angle = math.atan2(parentButton.center.y - button.center.y,
                  parentButton.center.x - button.center.x);

              final line = SpriteComponent2(
                isVisible: false,
                position: button.center,
                size: Vector2(distance, 20.0),
                angle: angle,
                spriteId: 'cultivation/line_1.png',
                anchor: Anchor.centerLeft,
                priority: _kSkillButtonPriority - 1,
              );
              _nodeConnections.add(line);
              world.add(line);
            }
          }
        }
      }
    }

    final lightTrailCoordinates1 =
        generateDividingPointsFromCircle(center.x, center.y, 200, 24);
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
        generateDividingPointsFromCircle(center.x, center.y, 350, 30);
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
        generateDividingPointsFromCircle(center.x, center.y, 500, 36);
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

  /// 角色渡劫检测，返回值 true 代表将进入天道挑战
  /// 此时将不会正常升级，但仍会扣掉经验值
  bool checkTribulation(int targetLevel) {
    final targetRank = GameData.heroData['rank'] + 1;
    final levelMin = GameLogic.minLevelForRank(targetRank);

    bool doTribulation = false;
    if (targetLevel >= levelMin) {
      if (targetLevel == 5 && targetRank == 1) {
        doTribulation = true;
      } else {
        final levelMax = GameLogic.maxLevelForRank(targetRank);
        final probability =
            math.gradualValue(targetLevel - levelMin, levelMax - levelMin);
        final r = math.Random().nextDouble();
        if (r < probability) {
          doTribulation = true;
        }
      }

      if (doTribulation) {
        GameLogic.showTribulation(levelMin + 5, targetRank);
      }
    }

    return doTribulation;
  }

  /// 处理角色升级相关逻辑
  void checkEXP() {
    int level = GameData.heroData['level'];
    int expForLevel = GameData.heroData['expForLevel'];
    int exp = GameData.heroData['exp'];

    if (exp >= expForLevel) {
      // 无论渡劫是否成功，经验值都会被扣除
      exp -= expForLevel;
      int targetLevel = level + 1;

      bool tribulationCheckResult = checkTribulation(targetLevel);

      if (!tribulationCheckResult) {
        engine.hetu.invoke('levelUp', namespace: 'Player');

        hint(
          '${engine.locale('cultivationLevel')} + 1',
          positionOffsetY: 60,
          color: Colors.yellow,
        );
      } else {
        GameData.heroData['exp'] = exp;
      }
    }

    udpateLevelDescription();
    updateExpDescription();
  }

  // Future<void> checkRank() async {}

  Future<void> condenseOne(ExpLightPoint light,
      [void Function()? onComplete]) async {
    return light.moveTo(
      toPosition: GameUI.condensedPosition,
      duration: light.distance2CondensePoint / _kLightPointMoveSpeed,
      curve: Curves.linear,
      onComplete: () async {
        // if (condensedCenter.preferredSize.x < GameUI.maxCondenseSize.x &&
        //     condensedCenter.preferredSize.y < GameUI.maxCondenseSize.y) {
        //   condensedCenter.preferredSize = Vector2(
        //       condensedCenter.size.x + 10, condensedCenter.size.y + 10);
        // } else {
        //   condensedCenter.preferredSize = GameUI.maxCondenseSize;
        // }
        // condensedCenter.position = GameUI.condensedPosition;
        // condensedCenter.lightingConfig!.radius += 5;

        _lightPoints.remove(light);
        light.removeFromParent();

        GameData.heroData['unconvertedExp'] -= light.exp;
        GameData.heroData['exp'] += light.exp;
        expBar.setValue(GameData.heroData['exp']);

        onComplete?.call();

        hint('${engine.locale('exp')} + ${light.exp}');

        updateExpDescription();
        addExpLightPoints();
      },
    );
  }

  FutureOr<void> condenseAll() async {
    if (_lightPoints.isEmpty) {
      return;
    }

    int exp = GameData.heroData['exp'];
    final int expForLevel = GameData.heroData['expForLevel'];

    if (exp >= expForLevel) {
      checkEXP();
      return;
    }

    List<Future> futures = [];
    for (final light in _lightPoints) {
      futures.add(condenseOne(light));
      exp += light.exp;
      if (exp > expForLevel) {
        break;
      }
    }

    await Future.wait(futures);

    checkEXP();
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    super.onDragUpdate(pointer, buttons, details);

    if (buttons == kSecondaryButton) {
      camera.moveBy(-details.delta.toVector2() / camera.zoom);
    }
  }

  @override
  void onDragEnd(int pointer, int buttons, TapUpDetails details) {
    super.onDragEnd(pointer, buttons, details);

    _focusNode.requestFocus();
  }

  @override
  void onMouseScroll(MouseScrollDetails details) {
    super.onMouseScroll(details);

    final delta = details.scrollDelta.dy;
    if (delta > 0) {
      if (camera.zoom > 0.2) {
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

    if (isMeditating) {
      timer.update(dt);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          SceneWidget(scene: this),
          GameUIOverlay(
            enableNpcs: false,
            enableCultivation: false,
            enableAutoExhaust: false,
          ),
          Positioned(
            right: 10.0,
            top: 10.0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(5.0),
                border: Border.all(color: GameUI.foregroundColor),
              ),
              child: IconButton(
                onPressed: () {
                  GameDialogContent.show(
                    context,
                    engine.locale('help_cultivation'),
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
