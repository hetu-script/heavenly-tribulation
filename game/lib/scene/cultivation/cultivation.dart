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

import 'exp_light_point.dart';
import '../../engine.dart';
import '../../game/logic.dart';
import '../../game/ui.dart';
import '../../game/data.dart';
import '../game_dialog/selection_dialog.dart';
import '../../widgets/ui_overlay.dart';
import '../../common.dart';
import '../common.dart';
import '../game_dialog/game_dialog_controller.dart';

const _kLightPointMoveSpeed = 450.0;
// const _kButtonAnimationDuration = 1.2;
const _kExpPerLightPoint = 10;

const _kBackgroundPriority = 10;
const _kSkillTreePriority = 15;
const _kCultivatorPriority = 20;
const _kCultivationRankButtonPriority = 22;
const _kLightPriority = 25;
const _kSkillButtonPriority = 40;

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

enum CultivationSceneState {
  expCollection, // 收集经验球提升等级和境界
  // introspection,
  skillTree, // 显示和分配天赋树技能
}

class CultivationScene extends Scene {
  static final random = math.Random();

  final _focusNode = FocusNode();

  late final SpriteComponent backgroundSprite;

  late final SpriteComponent2 skillTreeTrack;

  late final dynamic _heroPassiveData;

  String _heroSkillsDescription = '';

  late final SpriteButton cultivator;

  final List<ExpLightPoint> _lightPoints = [];

  // final List<LightTrail> _lightTrails = [];

  // String? selectedGenre;

  late final RichTextComponent levelDescription;

  late final DynamicColorProgressIndicator expBar;

  late final SpriteButton cultivationRankButton,
      cardPacksButton,
      cardLibraryButton,
      expCollectionPageButton,
      // introspectionButton,
      cultivationSkillPageButton;

  final Map<String, SpriteButton> _skillButtons = {};

  final List<SpriteComponent2> _skillTracks = [];

  CultivationSceneState state = CultivationSceneState.expCollection;

  void setState(CultivationSceneState state) {
    this.state = state;

    cultivationRankButton.isVisible =
        (this.state == CultivationSceneState.expCollection);

    for (final light in _lightPoints) {
      light.isVisible = this.state == CultivationSceneState.expCollection;
    }

    skillTreeTrack.isVisible = this.state == CultivationSceneState.skillTree;

    cultivator.enableGesture = this.state == CultivationSceneState.skillTree;

    for (final button in _skillButtons.values) {
      button.isVisible = this.state == CultivationSceneState.skillTree;
    }

    for (final line in _skillTracks) {
      line.isVisible = this.state == CultivationSceneState.skillTree;
    }

    // for (final trail in _lightTrails) {
    //   trail.isVisible = (this.state == CultivationSceneState.expCollection);
    // }
  }

  CultivationScene({
    required super.context,
    bool talentTreeMode = false,
  }) : super(id: Scenes.cultivation, enableLighting: true);

  void udpateLevelDescription() {
    final int rank = GameData.heroData['rank'];
    final rankString =
        '<bold rank$rank>${engine.locale('cultivationRank_$rank')}</>';

    final int availablePoints = GameData.heroData['availableSkillPoints'];
    final pointsString = availablePoints > 0
        ? '<bold yellow>$availablePoints</>'
        : '<bold red>$availablePoints</>';

    levelDescription.text = '${engine.locale('cultivationRank')}: $rankString '
        '${engine.locale('availableSkillPoints')}: $pointsString';
    expBar.label =
        '${engine.locale('cultivationLevel')}: ${GameData.heroData['level']} ${engine.locale('exp')}: ';
  }

  void hint(
    String text, {
    double positionOffsetY = 0.0,
    double duration = 4,
    Color? color,
  }) {
    addHintText(
      text,
      position:
          Vector2(cultivator.center.x, cultivator.center.y + positionOffsetY),
      duration: duration,
      textStyle: TextStyle(
        fontSize: 20,
        fontFamily: GameUI.fontFamily,
        color: color,
      ),
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

  void updateHeroSkillsDescription() {
    StringBuffer builder = StringBuffer();
    builder.writeln(engine.locale('skilltree_hero_skills_description_title'));
    builder.writeln(' ');
    if (_heroPassiveData.isEmpty) {
      builder.writeln('<grey>${engine.locale('none')}</>');
    } else {
      final List skillList = (_heroPassiveData.values as Iterable)
          .where((value) => value != null)
          .toList();
      skillList.sort((data1, data2) {
        return ((data2['priority'] ?? 0) as int)
            .compareTo((data1['priority'] ?? 0) as int);
      });
      for (final skillData in skillList) {
        final skillDescription = engine.locale(skillData['description']);
        final value = skillData['value'];
        final description = skillDescription.interpolate([value]);
        builder.writeln('<lightBlue>$description</>');
      }
    }
    _heroSkillsDescription = builder.toString();
  }

  void _addExpLightPoints(int exp) {
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
        // checkRank();
      });
    };
    lightPoint.onDragOver = (int buttons, __) {
      if (buttons != kPrimaryButton) return;
      condenseOne(lightPoint, () {
        checkEXP();
        // checkRank();
      });
    };
    _lightPoints.add(lightPoint);
    world.add(lightPoint);
  }

  /// 出于性能考虑，永远只显示足以升到下一级的光点
  void addExpLightPoints() {
    final int unconvertedExp = GameData.heroData['unconvertedExp'];
    final int level = GameData.heroData['level'];
    final int expForNextLevel = GameLogic.expForLevel(level);

    int expDisplayed = math.min(unconvertedExp, expForNextLevel);
    int lightPointCount = expDisplayed ~/ _kExpPerLightPoint;
    int expPerLightPoint = _kExpPerLightPoint;

    if (lightPointCount > 100) {
      // 最多只显示 100 个光点
      lightPointCount = 100;
      expPerLightPoint = expDisplayed ~/ lightPointCount;
    }

    while (_lightPoints.length < lightPointCount) {
      expDisplayed -= expPerLightPoint;

      _addExpLightPoints(expPerLightPoint);
    }

    if (expDisplayed > 0) {
      _addExpLightPoints(expDisplayed);
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
        button.spriteId = attributeSkillData['icon'];
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
                'dexterity': engine.locale('dexterity'),
                'spirituality': engine.locale('spirituality'),
                'strength': engine.locale('strength'),
                'willpower': engine.locale('willpower'),
                'perception': engine.locale('perception'),
                'cancel': engine.locale('cancel'),
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

              updateHeroSkillsDescription();

              button.spriteId = GameData.passives[selectedAttributeId]['icon'];
              button.tryLoadSprite();
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
              updateHeroSkillsDescription();
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

            engine.hetu.invoke('refundPassive', positionalArgs: [attributeId]);
          } else {
            unlockedNodes.remove(positionId);

            assert(nodePassiveData != null);
            for (final data in nodePassiveData!) {
              engine.hetu.invoke(
                'refundPassive',
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

  @override
  Future<void> onLoad() async {
    super.onLoad();

    // _heroSkillsData = deepCopy(GameData.heroData['passives']);
    _heroPassiveData = GameData.heroData['passives'];

    updateHeroSkillsDescription();

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
      sprite: Sprite(await Flame.images.load('cultivation/cultivator.png')),
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
    cultivator.onMouseEnter = () {
      if (state == CultivationSceneState.skillTree) {
        Hovertip.show(
          scene: this,
          target: cultivator,
          direction: HovertipDirection.rightTop,
          content: _heroSkillsDescription,
        );
      }
    };
    cultivator.onMouseExit = () {
      Hovertip.hide(cultivator);
    };
    cultivator.enableGesture = false;
    world.add(cultivator);

    final rankImagePath =
        'cultivation/cultivation${GameData.heroData['rank']}.png';
    cultivationRankButton = SpriteButton(
      anchor: Anchor.center,
      sprite: Sprite(await Flame.images.load(rankImagePath)),
      position: GameUI.condensedPosition,
      size: GameUI.cultivationRankButton,
      priority: _kCultivationRankButtonPriority,
    );
    cultivationRankButton.onTap = (buttons, position) async {
      if (state == CultivationSceneState.expCollection) {
        if (GameData.heroData['exp']) {}

        await condenseAll();
        checkEXP();
      }
    };

    world.add(cultivationRankButton);

    // String generateSkillStats() {
    //   StringBuffer sb = StringBuffer();
    //   return sb.toString();
    // }

    addExpLightPoints();

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
    // expBar.onMouseEnter = () {
    //   final level = heroData['level'];
    //   Tooltip.show(
    //     scene: this,
    //     target: expBar,
    //     direction: TooltipDirection.topCenter,
    //     width: 120,
    //     config: ScreenTextConfig(anchor: Anchor.topCenter),
    //     content: '${engine.locale('exp')}: ${heroData['exp']}\n'
    //         '${engine.locale('expForNextLevel')}: ${expForLevel(level)}',
    //   );
    // };
    // expBar.onMouseExit = () {
    //   Tooltip.hide();
    // };
    camera.viewport.add(expBar);

    udpateLevelDescription();

    expCollectionPageButton = SpriteButton(
      text: engine.locale('meditate'),
      anchor: Anchor.center,
      position: GameUI.expCollectionPageButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button.png',
    );
    expCollectionPageButton.onTapUp = (buttons, position) {
      if (buttons != kPrimaryButton) return;
      setState(CultivationSceneState.expCollection);
      expCollectionPageButton.removeFromParent();
      // cultivator.enableGesture = true;
      camera.viewport.add(cultivationSkillPageButton);
      cultivationSkillPageButton.isHovering = true;
    };

    cultivationSkillPageButton = SpriteButton(
      text: engine.locale('cultivationSkills'),
      anchor: Anchor.center,
      position: GameUI.talentTreePageButtonPosition,
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
    );
    cultivationSkillPageButton.onTapUp = (buttons, position) {
      if (buttons != kPrimaryButton) return;
      setState(CultivationSceneState.skillTree);
      cultivationSkillPageButton.removeFromParent();
      // cultivator.enableGesture = false;
      camera.viewport.add(expCollectionPageButton);
      expCollectionPageButton.isHovering = true;
    };
    camera.viewport.add(cultivationSkillPageButton);

    final exit = GameData.createSiteCard(
      id: 'exit',
      spriteId: 'exit2.png',
      title: engine.locale('exit'),
      position: GameUI.siteExitCardPositon,
    );
    exit.onTap = (_, __) {
      engine.popScene();
    };
    camera.viewport.add(exit);

    // cardLibraryButton = SpriteButton(
    //     anchor: Anchor.center,
    //     position:
    //         // _isFirstCultivation
    //         //   ? GameUI.condensedPosition
    //         //   :
    //         GameUI.cardLibraryButtonPosition,
    //     size: GameUI.cardLibraryButtonSize,
    //     // isEnabled: selectedGenre != null,
    //     // opacity: selectedGenre != null ? 1 : 0,
    //     spriteId: 'cultivation/library.png',
    //     // selectedGenre != null ? '$selectedGenre.png' : null,
    //     hoverSpriteId: 'cultivation/library_hover.png'
    //     // selectedGenre != null
    //     //     ? 'cultivation/deckbuilding/${selectedGenre}_hover.png'
    //     //     : null,
    //     );
    // camera.viewport.add(cardLibraryButton);

    // cardPacksButton = SpriteButton(
    //   anchor: Anchor.center,
    //   position:
    //       // _isFirstCultivation
    //       //     ? GameUI.condensedPosition
    //       //     :
    //       GameUI.cardPacksButtonPosition,
    //   size: GameUI.cardPacksButtonSize,
    //   // isEnabled: rank > 0,
    //   // opacity: rank > 0 ? 1 : 0,
    //   spriteId: 'cultivation/cardpack.png',
    //   hoverSpriteId: 'cultivation/cardpack_hover.png',
    //   onTap: (buttons, position) {
    //     engine.emit(UIEvents.cardPacksButtonClicked);
    //   },
    // );
    // camera.viewport.add(cardPacksButton);

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

    // final lightTrailCoordinates1 =
    //     generateDividingPointsFromCircle(center.x, center.y, 200, 24);
    // _lightTrails.addAll([
    //   LightTrail(
    //     radius: 200,
    //     index: 0,
    //     points: lightTrailCoordinates1,
    //   ),
    //   LightTrail(
    //     radius: 200,
    //     index: 8,
    //     points: lightTrailCoordinates1,
    //   ),
    //   LightTrail(
    //     radius: 200,
    //     index: 16,
    //     points: lightTrailCoordinates1,
    //   ),
    // ]);

    // final lightTrailCoordinates2 =
    //     generateDividingPointsFromCircle(center.x, center.y, 350, 30);
    // _lightTrails.addAll([
    //   LightTrail(
    //     radius: 350,
    //     index: 0,
    //     points: lightTrailCoordinates2,
    //   ),
    //   LightTrail(
    //     radius: 350,
    //     index: 6,
    //     points: lightTrailCoordinates2,
    //   ),
    //   LightTrail(
    //     radius: 350,
    //     index: 12,
    //     points: lightTrailCoordinates2,
    //   ),
    //   LightTrail(
    //     radius: 350,
    //     index: 18,
    //     points: lightTrailCoordinates2,
    //   ),
    //   LightTrail(
    //     radius: 350,
    //     index: 24,
    //     points: lightTrailCoordinates2,
    //   ),
    // ]);

    // final lightTrailCoordinates3 =
    //     generateDividingPointsFromCircle(center.x, center.y, 500, 36);
    // _lightTrails.addAll([
    //   LightTrail(
    //     radius: 500,
    //     index: 0,
    //     points: lightTrailCoordinates3,
    //   ),
    //   LightTrail(
    //     radius: 500,
    //     index: 4,
    //     points: lightTrailCoordinates3,
    //   ),
    //   LightTrail(
    //     radius: 500,
    //     index: 8,
    //     points: lightTrailCoordinates3,
    //   ),
    //   LightTrail(
    //     radius: 500,
    //     index: 12,
    //     points: lightTrailCoordinates3,
    //   ),
    //   LightTrail(
    //     radius: 500,
    //     index: 16,
    //     points: lightTrailCoordinates3,
    //   ),
    //   LightTrail(
    //     radius: 500,
    //     index: 20,
    //     points: lightTrailCoordinates3,
    //   ),
    //   LightTrail(
    //     radius: 500,
    //     index: 24,
    //     points: lightTrailCoordinates3,
    //   ),
    //   LightTrail(
    //     radius: 500,
    //     index: 28,
    //     points: lightTrailCoordinates3,
    //   ),
    //   LightTrail(
    //     radius: 500,
    //     index: 32,
    //     points: lightTrailCoordinates3,
    //   ),
    // ]);

    // for (final lightTrail in _lightTrails) {
    //   world.add(lightTrail);
    // }
  }

  /// 处理角色升级相关逻辑
  Future<void> checkEXP() async {
    int level = GameData.heroData['level'];
    int expForNextLevel = GameLogic.expForLevel(level);
    int exp = GameData.heroData['exp'];

    while (exp >= expForNextLevel) {
      exp -= expForNextLevel;
      expForNextLevel = GameLogic.expForLevel(++level);

      engine.hetu.invoke('levelUp', namespace: 'Player');

      hint(
        '${engine.locale('cultivationLevel')} + 1',
        positionOffsetY: 60,
        color: Colors.yellow,
      );

      final newRank = level ~/ kLevelPerRank + 1;
      final rank = GameData.heroData['rank'];
      if (newRank > rank) {
        if (rank == 0) {
          // 触发第一次修炼事件
        }

        // engine.hetu
        //     .invoke('characterCultivationRankUp', positionalArgs: [GameData.heroData]);
        // // cultivationRankButton.spriteId = 'cultivation/cultivation$newRank.png';
        // // cultivationRankButton.hoverSpriteId =
        // //     'cultivation/cultivation${newRank}_hover.png';
        // // cultivationRankButton.tryLoadSprite();

        // final rankName = engine.locale('cultivationRank_$newRank');
        // hint(
        //   '${engine.locale('rankUp!')} $rankName',
        //   positionOffsetY: 30,
        //   duration: 6,
        //   color: getColorFromRank(newRank),
        // );
      }

      udpateLevelDescription();

      addExpLightPoints();
    }

    expBar.setValue(exp);
    expBar.max = expForNextLevel;
  }

  // Future<void> checkRank() async {}

  Future<void> condenseOne(ExpLightPoint light,
      [void Function()? onComplete]) async {
    light.moveTo(
      toPosition: GameUI.condensedPosition,
      duration: light.distance2CondensePoint / _kLightPointMoveSpeed,
      curve: Curves.easeIn,
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
        expBar.setValue(expBar.value + light.exp);

        onComplete?.call();

        hint('${engine.locale('exp')} + ${light.exp}');
      },
    );
  }

  FutureOr<void> condenseAll() async {
    if (_lightPoints.isEmpty) return;

    // int level = GameData.heroData['level'];
    // int expForNextLevel = expForLevel(level);
    // int points = GameData.heroData['exp'];
    // int exp = GameData.heroData['unconvertedExp'];

    // int number;
    // if (exp >= expForNextLevel - points) {
    //   number = ((expForNextLevel - points) / 20).ceil();
    //   assert(number <= _lightPoints.length);
    // } else {
    //   number = _lightPoints.length;
    // }

    final completer = Completer();
    final lastIndex = _lightPoints.length - 1;
    for (var i = 0; i < _lightPoints.length; ++i) {
      final light = _lightPoints[i];

      condenseOne(light, () {
        // 这里不能直接和length比较，因为在condenseOne中会删除数组成员
        if (i == lastIndex) {
          completer.complete();
          // checkRank();
        }
      });
    }
    return completer.future;
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    super.onDragUpdate(pointer, buttons, details);

    if (buttons == kSecondaryButton) {
      camera.moveBy(-details.delta.toVector2() / camera.zoom);
    }
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
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      autofocus: true,
      focusNode: _focusNode,
      onKeyEvent: (event) {
        if (event is KeyDownEvent) {
          engine.debug('keydown: ${event.logicalKey.keyLabel}');
          if (event.logicalKey == LogicalKeyboardKey.space) {
            camera.snapTo(Vector2.zero());
          }
        }
      },
      child: Stack(
        children: [
          SceneWidget(scene: this),
          const Positioned(
            left: 0,
            top: 0,
            child: GameUIOverlay(),
          ),
          GameDialogController(),
        ],
      ),
    );
  }
}
