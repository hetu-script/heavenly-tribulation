import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
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
const _kSkillTreePriority = 15;
const _kCultivatorPriority = 20;
// const _kCultivationRankButtonPriority = 22;
const _kLightPriority = 25;
const _kSkillButtonPriority = 40;

const _kLightDisplayMax = 100;

/// 天赋树轨道半径，及轨道上的坐标点数量
const kTrackRadius = [
  (128, 5),
  (213, 5),
  (298, 5),
  (384, 20),
  (469, 10),
  (554, 10),
  (640, 40),
  (725, 20),
  (810, 20),
  (896, 40),
  (981, 20),
  (1066, 20),
  (1152, 40),
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

  late final SpriteComponent2 skillTreeTrack;

  String _heroSkillsDescription = '';

  late final SpriteButton cultivator;

  final List<ExpLightPoint> _lightPoints = [];

  final List<LightTrail> _lightTrails = [];

  late final RichTextComponent expDescription;

  late final RichTextComponent levelDescription;

  late final DynamicColorProgressIndicator expBar;

  late final SpriteButton cultivationRankButton,
      cardPacksButton,
      cardLibraryButton,
      cultivateButton,
      expCollectionButton;

  final Map<String, SpriteButton> _skillButtons = {};

  final List<SpriteComponent2> _skillTracks = [];

  bool _showSkillTree = false;

  void setSkillTreeState(bool state) {
    _showSkillTree = state;

    cultivateButton.isVisible = !_showSkillTree;
    expCollectionButton.isVisible = !_showSkillTree;
    for (final light in _lightPoints) {
      light.isVisible = !_showSkillTree;
    }
    for (final trail in _lightTrails) {
      trail.isVisible = isMeditating && !_showSkillTree;
    }

    skillTreeTrack.isVisible = state;
    for (final button in _skillButtons.values) {
      button.isVisible = _showSkillTree;
    }
    for (final line in _skillTracks) {
      line.isVisible = _showSkillTree;
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
    final int rank = GameData.heroData['rank'];
    final rankString =
        '<bold rank$rank>${engine.locale('cultivationRank_$rank')}</>';

    final int availablePoints = GameData.heroData['availableSkillPoints'];
    final pointsString = availablePoints > 0
        ? '<bold yellow>$availablePoints</>'
        : '<bold red>$availablePoints</>';

    levelDescription.text =
        '${engine.locale('cultivationLevel2')}: ${GameData.heroData['level']} ${engine.locale('cultivationRank')}: $rankString '
        '${engine.locale('availableSkillPoints')}: $pointsString';
  }

  void updateExpDescription() {
    expBar.setValue(GameData.heroData['exp']);
    expBar.max = GameLogic.expForLevel(GameData.heroData['level']);
    expDescription.text =
        '${engine.locale('unconvertedExp')}: ${GameData.heroData['unconvertedExp']}';
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
  (bool, bool) checkPassiveStatus(String positionId) {
    final passiveTreeNodeData = GameData.passiveTree[positionId];
    final unlockedNodes =
        GameData.heroData['passiveTreeUnlockedNodes'] as HTStruct;
    final isLearned = unlockedNodes.contains(positionId);
    // 可以学的技能，如果邻近的父节点无一解锁，则无法学习
    // 如果父节点数据是空的，则是入口节点，直接可以学习
    final List? parentNodes = passiveTreeNodeData?['parentNodes'];
    bool isOpen = parentNodes?.isEmpty ?? true;
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

    // final int level = GameData.heroData['level'];
    // final int expForNextLevel = GameLogic.expForLevel(level);

    // int expToDisplay = math.min(unconvertedExp, expForNextLevel);
    // int addedExp = expToDisplay;
    int addedExp = unconvertedExp;
    int expOnExistedLights = 0;
    for (final light in _lightPoints) {
      expOnExistedLights += light.exp;
    }
    addedExp -= expOnExistedLights;
    if (addedExp <= 0) return;

    // int lightPointCount = expToDisplay ~/ _kExpPerLightPoint;
    int lightPointCount = unconvertedExp ~/ _kExpPerLightPoint;
    int expPerLightPoint = _kExpPerLightPoint;
    if (lightPointCount > _kLightDisplayMax) {
      // 最多只显示 100 个光点
      lightPointCount = _kLightDisplayMax;
      // expPerLightPoint = expToDisplay ~/ lightPointCount;
      expPerLightPoint = unconvertedExp ~/ lightPointCount;
    }
    while (_lightPoints.length < lightPointCount) {
      addedExp -= expPerLightPoint;

      _addExpLightPoint(expPerLightPoint);
    }
    assert(addedExp >= 0);
    if (addedExp > 0) {
      _addExpLightPoint(addedExp);
    }
    // 这里排序是为了让condenseAll执行时可以准确的判断收集完全的时间点
    _lightPoints.sort((p1, p2) =>
        p1.distance2CondensePoint.compareTo(p2.distance2CondensePoint));
  }

  void _addGenreSkillButton(
      {required String positionId, required Vector2 position}) {
    final skillTreeNodeData = GameData.passiveTree[positionId];

    late SpriteButton button;

    final (isLearned, isOpen) = checkPassiveStatus(positionId);

    if (skillTreeNodeData == null) {
      // 还未开放的技能，在debug模式下显示为占位符，release模式下不显示
      if (kDebugMode) {
        button = SpriteButton(
          anchor: Anchor.center,
          position: position,
          size: GameUI.skillButtonSizeSmall,
          spriteId: 'cultivation/skill/wip.png',
          isVisible: false,
          priority: _kSkillButtonPriority,
          // lightConfig: LightConfig(radius: 25),
        );
        button.onMouseEnter = () {
          Hovertip.show(
            scene: this,
            target: button,
            direction: HovertipDirection.rightTop,
            content:
                '$positionId\nx:${button.position.x},\ny:${button.position.y}',
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
      final List? nodePassiveData = skillTreeNodeData['passives'];

      final buttonSize = switch (skillTreeNodeData['size']) {
        'large' => GameUI.skillButtonSizeLarge,
        'medium' => GameUI.skillButtonSizeMedium,
        _ => GameUI.skillButtonSizeSmall,
      };

      button = SpriteButton(
        anchor: Anchor.center,
        position: position,
        size: buttonSize,
        spriteId: skillTreeNodeData['icon'],
        unselectedSpriteId: skillTreeNodeData['unselectedIcon'],
        isVisible: false,
        isSelectable: true,
        isSelected: isLearned,
        priority: _kSkillButtonPriority,
        // isEnabled: isOpen,
        lightConfig: LightConfig(radius: 25),
      );

      // 是否是属性点天赋
      bool isAttribute = skillTreeNodeData['isAttribute'] ?? false;

      if (isAttribute && isLearned) {
        // 如果是属性节点，需要特殊处理
        // 分配新的属性天赋点时，从五种属性中选择一种，并获得3点该属性值
        // 分配后，按钮也会相应变成对应该属性的颜色
        // 身法：绿 灵力：蓝 体魄：红 意志：白 神识：黄
        final attributeId =
            GameData.heroData['passiveTreeUnlockedNodes'][positionId];
        assert(attributeId is String);
        final attributeSkillData = GameData.passives[attributeId];
        assert(attributeSkillData != null);
        button.tryLoadSprite(spriteId: attributeSkillData['icon']);
      }

      button.onTapUp = (buttons, position) async {
        final (isLearned, isOpen) = checkPassiveStatus(positionId);

        if (buttons == kPrimaryButton) {
          if (isLearned || !isOpen) return;
          Hovertip.hide(button);

          final rank = skillTreeNodeData['rank'] ?? 0;
          if (GameData.heroData['rank'] < rank) return;

          if (GameData.heroData['availableSkillPoints'] > 0) {
            final unlockedNodes = GameData.heroData['passiveTreeUnlockedNodes'];
            if (isAttribute) {
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
              --GameData.heroData['availableSkillPoints'];
              button.isSelected = true;

              // 属性点类的node，记录的是选择的具体属性的名字
              unlockedNodes[positionId] = selectedAttributeId;

              engine.hetu.invoke('gainPassive',
                  namespace: 'Player', positionalArgs: [selectedAttributeId]);

              updateHeroPassivesDescription();

              button.tryLoadSprite(
                  spriteId: GameData.passives[selectedAttributeId]['icon']);
            } else {
              --GameData.heroData['availableSkillPoints'];
              button.isSelected = true;
              unlockedNodes[positionId] = true;

              assert(nodePassiveData != null);
              for (final data in nodePassiveData!) {
                engine.hetu.invoke(
                  'gainPassive',
                  namespace: 'Player',
                  positionalArgs: [data['id']],
                  namedArgs: {'level': data['level']},
                );
              }

              updateHeroPassivesDescription();
            }

            udpateLevelDescription();

            engine.play('click-21156.mp3');
          } else {
            // GameDialog.show(
            //   context: context,
            //   dialogData: {
            //     'lines': [engine.locale('noSkillPoints.prompt')],
            //   },
            // );
          }
        } else if (buttons == kSecondaryButton) {
          if (!isLearned) return;
          Hovertip.hide(button);
          // TODO:检查节点链接，如果有其他节点依赖于该节点，则不能退点

          ++GameData.heroData['availableSkillPoints'];
          button.isSelected = false;

          final unlockedNodes = GameData.heroData['passiveTreeUnlockedNodes'];

          if (isAttribute) {
            final attributeId = unlockedNodes[positionId];
            assert(attributeId != null);

            unlockedNodes.remove(positionId);

            engine.hetu.invoke('refundPassive',
                namespace: 'Player', positionalArgs: [attributeId]);
          } else {
            unlockedNodes.remove(positionId);

            assert(nodePassiveData != null);
            for (final data in nodePassiveData!) {
              engine.hetu.invoke(
                'refundPassive',
                namespace: 'Player',
                positionalArgs: [data['id']],
                namedArgs: {'level': data['level']},
              );
            }
          }

          udpateLevelDescription();
        }
      };

      button.onMouseEnter = () {
        final (isLearned, isOpen) = checkPassiveStatus(positionId);

        StringBuffer skillDescription = StringBuffer();

        if (isAttribute && isLearned) {
          skillDescription.writeln(
              '<bold yellow>${engine.locale(skillTreeNodeData['title'])}</>');
          skillDescription.writeln(' ');

          final attributeId =
              GameData.heroData['passiveTreeUnlockedNodes'][positionId];
          assert(attributeId is String);
          final attributeSkillData = GameData.passives[attributeId];
          assert(attributeSkillData != null);
          String attributeDescription =
              engine.locale(attributeSkillData['description']);
          attributeDescription = attributeDescription
              .interpolate([attributeSkillData['increment']]);
          skillDescription.writeln(attributeDescription);
        } else {
          skillDescription.writeln(skillTreeNodeData['description']);
        }

        skillDescription.writeln(' ');
        if (isLearned) {
          skillDescription.writeln(engine.locale('skilltree_refund_hint'));
        } else {
          if (isOpen) {
            if (GameData.heroData['availableSkillPoints'] > 0) {
              final rankRequirement = skillTreeNodeData['rank'] ?? 0;
              if (GameData.heroData['rank'] >= rankRequirement) {
                skillDescription
                    .writeln(engine.locale('skilltree_unlock_hint'));
              } else {
                skillDescription.writeln(engine.locale('skilltree_rank_hint'));
              }
            } else {
              skillDescription.writeln(engine.locale('skilltree_points_hint'));
            }
          } else {
            skillDescription.writeln(engine.locale('skilltree_locked_hint'));
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

    _skillButtons[positionId] = button;
    // _skillButtons.add(button);
    world.add(button);
  }

  void updateHeroPassivesDescription() {
    _heroSkillsDescription = GameData.getHeroPassivesDescription();
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
          GameData.heroData['stats']['unconvertedExpCollectEfficiency'];

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
      1.0,
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

    skillTreeTrack = SpriteComponent2(
      isVisible: false,
      position: GameUI.cultivatorPosition,
      sprite:
          Sprite(await Flame.images.load('cultivation/skill_tree_tracks.png')),
      anchor: Anchor.center,
      priority: _kSkillTreePriority,
    );
    world.add(skillTreeTrack);

    cultivator = SpriteButton(
      anchor: Anchor.center,
      sprite: Sprite(await Flame.images.load('cultivation/cultivator2.png')),
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
      setSkillTreeState(!_showSkillTree);
    };
    cultivator.onMouseEnter = () {
      // if (state == CultivationSceneState.skillTree) {
      Hovertip.show(
        scene: this,
        target: cultivator,
        direction: HovertipDirection.rightTop,
        content: _heroSkillsDescription,
      );
      // }
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

    expDescription = RichTextComponent(
      position: cultivator.bottomCenter + Vector2(0, GameUI.indent),
      anchor: Anchor.center,
      size: GameUI.levelDescriptionSize,
      priority: _kCultivatorPriority,
      config: ScreenTextConfig(
        outlined: true,
        anchor: Anchor.topCenter,
        textStyle: const TextStyle(
          color: Colors.lightGreenAccent,
          fontSize: 16,
          fontFamily: GameUI.fontFamily,
        ),
      ),
    );
    world.add(expDescription);

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

    int level = GameData.heroData['level'];
    int convertedExp = GameData.heroData['exp'];
    int expForNextLevel = GameLogic.expForLevel(level);
    expBar = DynamicColorProgressIndicator(
      anchor: Anchor.center,
      position: GameUI.expBarPosition,
      size: GameUI.expBarSize,
      borderRadius: 5,
      label: '${engine.locale('exp')}: ',
      value: convertedExp,
      max: expForNextLevel,
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
      await condenseAll();
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
          positionId: id,
          position: track[j].position,
        );
      }
    }

    for (final positionId in _skillButtons.keys) {
      final skillTreeNodeData = GameData.passiveTree[positionId];

      if (skillTreeNodeData != null) {
        final button = _skillButtons[positionId]!;
        final parentNodes = skillTreeNodeData['parentNodes'];
        if (parentNodes is List) {
          for (final parentPositionId in parentNodes) {
            // 如果在相同轨道上就略过
            if (parentPositionId.split('_')[1] == positionId.split('_')[1]) {
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
              _skillTracks.add(line);
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

  /// 角色渡劫检测，返回值 false 代表将进入天道挑战
  /// 此时将不会正常升级，但仍会扣掉经验值
  bool checkTribulation(int targetLevel) {
    final targetRank = GameData.heroData['rank'] + 1;
    final levelMin = GameLogic.minLevelForRank(targetRank);

    if (targetLevel == 5 && targetRank == 1) {
      GameLogic.showTribulation(levelMin + 5, targetRank);
    } else {
      final levelMax = GameLogic.maxLevelForRank(targetRank);
      assert(targetLevel >= levelMin);
      final probability =
          math.gradualValue(targetLevel - levelMin, levelMax - levelMin);
      final r = math.Random().nextDouble();
      if (r < probability) {
        GameLogic.showTribulation(levelMin + 5, targetRank);
        return false;
      }
    }

    return true;
  }

  /// 处理角色升级相关逻辑
  void checkEXP() {
    int level = GameData.heroData['level'];
    int expForNextLevel = GameLogic.expForLevel(level);
    int exp = GameData.heroData['exp'];

    if (exp >= expForNextLevel) {
      // 无论渡劫是否成功，经验值都会被扣除
      exp -= expForNextLevel;
      int targetLevel = level + 1;

      bool success = true;
      int nextLevelMin =
          GameLogic.minLevelForRank(GameData.heroData['rank'] + 1);
      if (targetLevel >= nextLevelMin) {
        success = checkTribulation(targetLevel);
      }

      if (success) {
        engine.hetu.invoke('levelUp', namespace: 'Player');

        hint(
          '${engine.locale('cultivationLevel')} + 1',
          positionOffsetY: 60,
          color: Colors.yellow,
        );
      }
    }

    udpateLevelDescription();
    updateExpDescription();
  }

  // Future<void> checkRank() async {}

  Future<void> condenseOne(ExpLightPoint light,
      [void Function()? onComplete]) async {
    light.moveTo(
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
      checkEXP();
      return;
    } else {
      final completer = Completer();
      final lastIndex = _lightPoints.length - 1;
      for (var i = 0; i < _lightPoints.length; ++i) {
        final light = _lightPoints[i];
        condenseOne(light, () {
          // 这里不能直接和length比较，因为在condenseOne中会删除数组成员
          if (i == lastIndex) {
            checkEXP();
            completer.complete();
          }
        });
      }
      return completer.future;
    }
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
      if (camera.zoom > 0.5) {
        camera.zoom -= 0.2;
      }
    } else if (delta < 0) {
      if (camera.zoom < 4) {
        camera.zoom += 0.2;
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
          const Positioned(
            left: 0,
            top: 0,
            child: GameUIOverlay(
              enableNpcs: false,
              enableCultivation: false,
              enableAutoExhaust: false,
            ),
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
