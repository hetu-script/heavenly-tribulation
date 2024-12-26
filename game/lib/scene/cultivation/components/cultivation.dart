import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Tooltip;
import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:samsara/components/progress_indicator.dart';
import 'package:samsara/components/sprite_button.dart';
import 'package:samsara/utils/math.dart';
import 'package:samsara/components/text_component2.dart';
import 'package:hetu_script/utils.dart';
import 'package:samsara/components/tooltip.dart';
import 'package:samsara/components/sprite_component2.dart';
import 'package:hetu_script/values.dart';

// import 'cultivator.dart';
import 'light_trail.dart';
import 'light_point.dart';
import '../../../config.dart';
import '../../../logic/algorithm.dart';
import '../../../ui.dart';
// import '../../../common.dart';
import '../../../events.dart';
import '../../../data.dart';
import '../../../dialog/game_dialog/selection_dialog.dart';
import '../../../dialog/game_dialog/game_dialog.dart';

const _kLightPointMoveSpeed = 450.0;
// const _kButtonAnimationDuration = 1.2;
const _kExpPerLightPoint = 20;

const _kSkillTreePriority = 10;
const _kSkillButtonPriority = 20;

enum CultivationSceneState {
  expCollection, // 内观，可以通过时间流逝产生新的经验球，可以点击收集经验球
  // introspection,
  skillTree, // 悟道，技能模式，显示天赋树
}

class CultivationScene extends Scene {
  static final random = math.Random();

  late final SpriteComponent backgroundSprite;

  late final SpriteComponent2 skillTreeTracksSprite;

  dynamic _heroData;

  late final SpriteButton cultivator;

  final List<LightPoint> _lightPoints = [];

  final List<LightTrail> _lightTrails = [];

  // String? selectedGenre;

  late final TextComponent2 levelDescription;

  late final DynamicColorProgressIndicator expBar;

  late final SpriteButton //cultivationRankButton,
      cardPacksButton,
      cardLibraryButton,
      expCollectionPageButton,
      // introspectionButton,
      cultivationSkillPageButton;

  late bool _isFirstCultivation;

  final Map<String, SpriteButton> _skillButtons = {};

  CultivationSceneState state = CultivationSceneState.expCollection;

  void setState(CultivationSceneState state) {
    this.state = state;

    skillTreeTracksSprite.isVisible =
        (this.state == CultivationSceneState.skillTree);

    for (final trail in _lightTrails) {
      trail.isVisible = (this.state == CultivationSceneState.expCollection);
    }

    for (final light in _lightPoints) {
      light.isVisible = (this.state == CultivationSceneState.expCollection);
    }

    for (final button in _skillButtons.values) {
      button.isVisible = (this.state == CultivationSceneState.skillTree);
    }
  }

  dynamic _heroSkillsData = {};

  CultivationScene({
    required super.controller,
    required super.context,
    bool talentTreeMode = false,
  }) : super(id: 'cultivation', enableLighting: true) {
    // selectedGenre = heroData['cultivationGenre'];

    _heroData = engine.hetu.fetch('hero');

    _isFirstCultivation = _heroData['cultivationRank'] == 0;

    _heroSkillsData = deepCopy(_heroData['cultivationSkills']);
  }

  void udpateLevelDescription() {
    levelDescription.text =
        '${engine.locale('cultivationRank')}: ${engine.locale('cultivationRank.${_heroData['cultivationRank']}')} '
        '${engine.locale('availableSkillPoints')}: ${_heroData['availableSkillPoints']}';
    expBar.label =
        '${engine.locale('cultivationLevel')}: ${_heroData['cultivationLevel']} ${engine.locale('exp')}: ';
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

  void _addGenreSkillButton(
      {required String positionId, required Vector2 position}) {
    final skillTreeNodeData = GameData.cultivationSkillTreeData[positionId];
    final String? skillId = skillTreeNodeData?['skillId'];
    final skillData = GameData.cultivationSkillData[skillId];

    SpriteButton? button;

    if (skillTreeNodeData == null) {
      // 还未开放的技能，在debug模式下显示为占位符
      if (kDebugMode) {
        button = SpriteButton(
          anchor: Anchor.center,
          position: position,
          size: positionId.startsWith('major')
              ? GameUI.skillButtonSizeMedium
              : GameUI.skillButtonSizeSmall,
          spriteId: 'cultivation/skill/wip.png',
          isVisible: false,
          priority: _kSkillButtonPriority,
          // lightConfig: LightConfig(radius: 25),
        );
        button.onMouseEnter = () {
          Tooltip.show(
            scene: this,
            target: button!,
            direction: TooltipDirection.rightTop,
            content:
                '$positionId\nx:${button.position.x},\ny:${button.position.y}',
          );
        };
      } else {
        return;
      }
    } else {
      // 已经开发完毕，写好数据的技能
      final unlockedNodes = _heroData['skillTreeUnlockedNodes'] as HTStruct;
      final isLearned = unlockedNodes.contains(positionId);
      // 可以学的技能，如果邻近的上一个节点还未解锁，则无法学习
      bool isOpen = skillTreeNodeData['isMain'] ?? false;
      if (!isOpen) {
        for (final parent in skillTreeNodeData['parentNodes']) {
          if (unlockedNodes.contains(parent)) {
            isOpen = true;
            break;
          }
        }
      }
      // 是否是属性点天赋
      bool isAttribute = skillTreeNodeData['isAttribute'] ?? false;

      final buttonSize = switch (skillTreeNodeData['size']) {
        'large' => GameUI.skillButtonSizeLarge,
        'medium' => GameUI.skillButtonSizeMedium,
        _ => GameUI.skillButtonSizeSmall,
      };

      if (!isAttribute) {
        button = SpriteButton(
          anchor: Anchor.center,
          position: position,
          size: buttonSize,
          spriteId: skillData['icon'],
          unselectedSpriteId: skillData['unselectedIcon'],
          isVisible: false,
          isSelectable: true,
          isSelected: isLearned,
          priority: _kSkillButtonPriority,
          // isEnabled: isOpen,
          lightConfig: (isLearned || isOpen) ? LightConfig(radius: 25) : null,
        );

        button.onTapUp = (buttons, position) {
          if (buttons == kPrimaryButton) {
            if (!isLearned && isOpen) {
              if (_heroData['availableSkillPoints'] > 0) {
                --_heroData['availableSkillPoints'];

                button!.isSelected = true;
                unlockedNodes[positionId] = true;

                engine.hetu.invoke(
                  'characterCultivationSkillLevelUp',
                  positionalArgs: [
                    _heroData,
                    skillId,
                  ],
                  namedArgs: {
                    'incurIncident': false,
                  },
                );

                udpateLevelDescription();
              } else {
                // GameDialog.show(
                //   context: context,
                //   dialogData: {
                //     'lines': [engine.locale('noSkillPoints.prompt')],
                //   },
                // );
              }
            }
          } else if (buttons == kSecondaryButton) {
            if (isLearned) {
              // TODO:检查节点链接，如果有其他节点依赖于该节点，则不能退点
              ++_heroData['availableSkillPoints'];

              button!.isSelected = false;
              unlockedNodes.remove(positionId);

              engine.hetu.invoke(
                'characterCultivationSkillRefund',
                positionalArgs: [
                  _heroData,
                  skillId,
                ],
                namedArgs: {
                  'incurIncident': false,
                },
              );
            }
          }
        };
      } else {
        // 属性天赋点需要特殊处理
        // 分配新的属性天赋点时，从五种属性中选择一种，并获得3点该属性值
        // 分配后，按钮也会相应变成对应该属性的颜色
        // 身法：绿
        // 灵力：蓝
        // 体魄：红
        // 意志：白
        // 神识：黄

        button = SpriteButton(
          anchor: Anchor.center,
          position: position,
          size: buttonSize,
          spriteId: 'cultivation/skill/attribute_any_unselected.png',
          unselectedSpriteId: 'cultivation/skill/attribute_any_unselected.png',
          isVisible: false,
          isSelectable: true,
          isSelected: isLearned,
          priority: _kSkillButtonPriority,
          // isEnabled: isOpen,
          lightConfig: (isLearned || isOpen) ? LightConfig(radius: 25) : null,
        );

        final attributeId = unlockedNodes[positionId];
        final attributeSkillData = GameData.cultivationSkillData[attributeId];

        if (isLearned) {
          assert(attributeSkillData != null);
          button.spriteId = attributeSkillData['icon'];
        }

        button.onTapUp = (buttons, position) async {
          if (buttons == kPrimaryButton) {
            if (!isLearned && isOpen) {
              if (_heroData['availableSkillPoints'] > 0) {
                --_heroData['availableSkillPoints'];

                final selectedAttributeId = await SelectionDialog.show(
                    context: context,
                    selectionsData: {
                      'dexterity': engine.locale('dexterity'),
                      'spirituality': engine.locale('spirituality'),
                      'strength': engine.locale('strength'),
                      'willpower': engine.locale('willpower'),
                      'perception': engine.locale('perception'),
                      'cancel': engine.locale('cancel'),
                    });

                if (selectedAttributeId == 'cancel') return;

                // 属性点类的node，记录的是选择的具体属性的名字
                unlockedNodes[positionId] = selectedAttributeId;

                engine.hetu.invoke(
                  'characterCultivationSkillLevelUp',
                  positionalArgs: [
                    _heroData,
                    skillId,
                  ],
                  namedArgs: {
                    'incurIncident': false,
                  },
                );

                udpateLevelDescription();
              } else {
                // GameDialog.show(
                //   context: context,
                //   dialogData: {
                //     'lines': [engine.locale('noSkillPoints.prompt')],
                //   },
                // );
              }
            }
          } else if (buttons == kSecondaryButton) {
            if (isLearned) {
              button!.isSelected = false;
              assert(attributeId != null);

              ++_heroData['availableSkillPoints'];

              button.isSelected = false;
              unlockedNodes.remove(positionId);

              engine.hetu.invoke(
                'characterCultivationSkillRefund',
                positionalArgs: [
                  _heroData,
                  attributeId,
                ],
                namedArgs: {
                  'incurIncident': false,
                },
              );
            }
          }
        };
      }
      button.onMouseEnter = () {
        StringBuffer skillDescription = StringBuffer();
        skillDescription.writeln('<bold yellow>${engine.locale(skillId)}</>');
        skillDescription.writeln(' ');
        skillDescription.writeln(engine.locale('skill.$skillId.description'));
        skillDescription.writeln(' ');
        if (isLearned) {
          skillDescription.writeln(engine.locale('refund.hint'));
        } else if (isOpen) {
          if (_heroData['availableSkillPoints'] > 0) {
            skillDescription.writeln(engine.locale('unlock.hint'));
          } else {
            skillDescription.writeln(engine.locale('noPoints.hint'));
          }
        } else {
          skillDescription.writeln(engine.locale('locked.hint'));
        }
        Tooltip.show(
          scene: this,
          target: button!,
          direction: TooltipDirection.rightTop,
          content: skillDescription.toString(),
        );
      };
    }

    button.onMouseExit = () {
      Tooltip.hide();
    };
    _skillButtons[positionId] = button;
    world.add(button);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    backgroundSprite = SpriteComponent(
      position: Vector2(center.x, center.y - 130),
      sprite: Sprite(await Flame.images.load('cultivation/cave2.png')),
      anchor: Anchor.center,
    );
    world.add(backgroundSprite);

    skillTreeTracksSprite = SpriteComponent2(
      position: GameUI.cultivatorPosition,
      sprite:
          Sprite(await Flame.images.load('cultivation/skill_tree_tracks.png')),
      anchor: Anchor.center,
      priority: _kSkillTreePriority,
    );
    world.add(skillTreeTracksSprite);

    cultivator = SpriteButton(
      anchor: Anchor.center,
      sprite: Sprite(await Flame.images.load('cultivation/cultivator.png')),
      position: GameUI.cultivatorPosition,
      size: GameUI.cultivatorSize,
      onTap: (buttons, position) {
        if (state == CultivationSceneState.expCollection) {
          condenseAll();
        }
      },
      lightConfig: LightConfig(
        radius: 250,
        blurBorder: 500,
        shape: LightShape.circle,
        lightCenter: GameUI.condensedPosition,
      ),
    );
    cultivator.onMouseEnter = () {};
    world.add(cultivator);

    // String generateSkillStats() {
    //   StringBuffer sb = StringBuffer();
    //   return sb.toString();
    // }

    final exp = _heroData['unconvertedExp'];
    final lightPointCount = exp ~/ _kExpPerLightPoint;
    for (var i = 0; i < lightPointCount; ++i) {
      Vector2 randomPosition;
      do {
        randomPosition = Vector2(
            random.nextDouble() * (size.x * 0.8) + size.x * 0.1,
            random.nextDouble() * (size.y - GameUI.historyPanelSize.y));
      } while (cultivator.containsPoint(randomPosition));
      final lightPoint = LightPoint(
        position: randomPosition,
        flickerRate: 8,
        condensedPosition: GameUI.condensedPosition,
      );
      lightPoint.onTapDown = (int buttons, __) {
        if (buttons != kPrimaryButton) return;
        condenseOne(lightPoint, () {
          checkEXP();
          checkRank();
        });
      };
      lightPoint.onDragOver = (int buttons, __) {
        if (buttons != kPrimaryButton) return;
        condenseOne(lightPoint, () {
          checkEXP();
          checkRank();
        });
      };
      _lightPoints.add(lightPoint);
      world.add(lightPoint);
    }
    _lightPoints.sort((p1, p2) =>
        p1.distance2CondensePoint.compareTo(p2.distance2CondensePoint));

    levelDescription = TextComponent2(
      position: GameUI.levelDescriptionPosition,
      anchor: Anchor.center,
      config: ScreenTextConfig(
        textStyle: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontFamily: GameUI.fontFamily,
        ),
      ),
    );
    camera.viewport.add(levelDescription);

    int level = _heroData['cultivationLevel'];
    int points = _heroData['exp'];
    int expForNextLevel = expForLevel(level);
    expBar = DynamicColorProgressIndicator(
      anchor: Anchor.center,
      position: GameUI.expBarPosition,
      size: GameUI.expBarSize,
      borderRadius: 5,
      value: points,
      max: expForNextLevel,
      showNumber: true,
      colors: [Colors.lightBlue, Colors.deepPurple],
      borderPaint: Paint()
        ..color = Colors.white
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
      labelConfig: ScreenTextConfig(
        textStyle: TextStyle(fontFamily: GameUI.fontFamily),
      ),
    );
    // expBar.onMouseEnter = () {
    //   final level = heroData['cultivationLevel'];
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

    expCollectionPageButton = SpriteButton(
      text: engine.locale('meditate'),
      anchor: Anchor.center,
      position: GameUI.expCollectionPageButtonPosition,
      size: GameUI.stateButtonSize,
      spriteId: 'ui/button.png',
      textConfig: ScreenTextConfig(
        textStyle: TextStyle(fontFamily: GameUI.fontFamily),
      ),
    );
    expCollectionPageButton.onTapUp = (buttons, position) {
      if (buttons != kPrimaryButton) return;
      setState(CultivationSceneState.expCollection);
      expCollectionPageButton.removeFromParent();
      cultivator.enableGesture = true;
      camera.viewport.add(cultivationSkillPageButton);
      cultivationSkillPageButton.isHovering = true;
    };

    cultivationSkillPageButton = SpriteButton(
      text: engine.locale('cultivationSkills'),
      anchor: Anchor.center,
      position: GameUI.talentTreePageButtonPosition,
      size: GameUI.stateButtonSize,
      spriteId: 'ui/button2.png',
      textConfig: ScreenTextConfig(
        textStyle: TextStyle(fontFamily: GameUI.fontFamily),
      ),
    );
    cultivationSkillPageButton.onTapUp = (buttons, position) {
      if (buttons != kPrimaryButton) return;
      setState(CultivationSceneState.skillTree);
      cultivationSkillPageButton.removeFromParent();
      cultivator.enableGesture = false;
      camera.viewport.add(expCollectionPageButton);
      expCollectionPageButton.isHovering = true;
    };
    camera.viewport.add(cultivationSkillPageButton);

    final exit = GameData.getExitSiteCard(spriteId: 'exit_card2');
    exit.onTap =
        (_, __) => engine.emit(GameEvents.leaveCultivationScene, args: id);
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

    // 天赋树轨道半径：#128, 213, 298, #384, 469, 554, #640, 725, 810, #896, 981, 1066, #1152

    final majorSkillTrack1 =
        getDividingPointsFromCircle(center.x, center.y, 128, 5);
    for (var i = 0; i < majorSkillTrack1.length; i++) {
      final id = 'majorSkillTrack1_$i';
      _addGenreSkillButton(
        positionId: id,
        position: majorSkillTrack1[i].position,
      );
    }
    final minorSkillTrack1 =
        getDividingPointsFromCircle(center.x, center.y, 213, 10);
    for (var i = 0; i < minorSkillTrack1.length; i++) {
      final id = 'minorSkillTrack1_$i';
      _addGenreSkillButton(
        positionId: id,
        position: minorSkillTrack1[i].position,
      );
    }
    final minorSkillTrack2 =
        getDividingPointsFromCircle(center.x, center.y, 298, 10);
    for (var i = 0; i < minorSkillTrack2.length; i++) {
      final id = 'minorSkillTrack2_$i';
      _addGenreSkillButton(
        positionId: id,
        position: minorSkillTrack2[i].position,
      );
    }

    final majorSkillTrack2 =
        getDividingPointsFromCircle(center.x, center.y, 384, 5);
    for (var i = 0; i < majorSkillTrack2.length; i++) {
      final id = 'majorSkillTrack2_$i';
      _addGenreSkillButton(
        positionId: id,
        position: majorSkillTrack2[i].position,
      );
    }

    final minorSkillTrack3 =
        getDividingPointsFromCircle(center.x, center.y, 384, 20);
    for (var i = 0; i < minorSkillTrack3.length; i++) {
      if (i % 4 == 0) continue;
      final id = 'minorSkillTrack3_$i';
      _addGenreSkillButton(
        positionId: id,
        position: minorSkillTrack3[i].position,
      );
    }
    final minorSkillTrack4 =
        getDividingPointsFromCircle(center.x, center.y, 469, 20);
    for (var i = 0; i < minorSkillTrack4.length; i++) {
      final id = 'minorSkillTrack4_$i';
      _addGenreSkillButton(
        positionId: id,
        position: minorSkillTrack4[i].position,
      );
    }
    final minorSkillTrack5 =
        getDividingPointsFromCircle(center.x, center.y, 554, 20);
    for (var i = 0; i < minorSkillTrack5.length; i++) {
      final id = 'minorSkillTrack5_$i';
      _addGenreSkillButton(
        positionId: id,
        position: minorSkillTrack5[i].position,
      );
    }

    // final coordinates12b =
    //     getDividingPointsFromCircle(center.x, center.y, 384, 10);
    // for (var i = 0; i < coordinates12b.length; i++) {
    //   _addGenreSkillButton(
    //     id: 'circle2b_$i',
    //     skillId: skillId2,
    //     position: coordinates12b[i].position,
    //     size: GameUI.skillButtonSizeSmall,
    //     isEnabled: true,
    //   );
    // }

    final majorSkillTrack3 = getDividingPointsFromCircle(
        center.x, center.y, 640, 10,
        angleOffset: -18);
    for (var i = 0; i < majorSkillTrack3.length; i++) {
      final id = 'majorSkillTrack3_$i';
      _addGenreSkillButton(
        positionId: id,
        position: majorSkillTrack3[i].position,
      );
    }

    final minorSkillTrack6 =
        getDividingPointsFromCircle(center.x, center.y, 640, 40);
    for (var i = 0; i < minorSkillTrack6.length; i++) {
      if ((i - 2) % 4 == 0) continue;
      final id = 'minorSkillTrack6_$i';
      _addGenreSkillButton(
        positionId: id,
        position: minorSkillTrack6[i].position,
      );
    }

    final minorSkillTrack7 =
        getDividingPointsFromCircle(center.x, center.y, 725, 40);
    for (var i = 0; i < minorSkillTrack7.length; i++) {
      final id = 'minorSkillTrack7_$i';
      _addGenreSkillButton(
        positionId: id,
        position: minorSkillTrack7[i].position,
      );
    }

    final minorSkillTrack8 =
        getDividingPointsFromCircle(center.x, center.y, 810, 40);
    for (var i = 0; i < minorSkillTrack8.length; i++) {
      final id = 'minorSkillTrack8_$i';
      _addGenreSkillButton(
        positionId: id,
        position: minorSkillTrack8[i].position,
      );
    }

    final majorSkillTrack4 =
        getDividingPointsFromCircle(center.x, center.y, 896, 20);
    for (var i = 0; i < majorSkillTrack4.length; i++) {
      if ((i - 2) % 4 == 0) continue;
      final id = 'majorSkillTrack4_$i';
      _addGenreSkillButton(
        positionId: id,
        position: majorSkillTrack4[i].position,
      );
    }

    final minorSkillTrack9 =
        getDividingPointsFromCircle(center.x, center.y, 896, 40);
    for (var i = 0; i < minorSkillTrack9.length; i++) {
      if (i % 2 == 0) continue;
      final id = 'minorSkillTrack9_$i';
      _addGenreSkillButton(
        positionId: id,
        position: minorSkillTrack9[i].position,
      );
    }

    final minorSkillTrack10 =
        getDividingPointsFromCircle(center.x, center.y, 981, 40);
    for (var i = 0; i < minorSkillTrack10.length; i++) {
      final id = 'minorSkillTrack10_$i';
      _addGenreSkillButton(
        positionId: id,
        position: minorSkillTrack10[i].position,
      );
    }

    final minorSkillTrack11 =
        getDividingPointsFromCircle(center.x, center.y, 1066, 40);
    for (var i = 0; i < minorSkillTrack11.length; i++) {
      final id = 'minorSkillTrack11_$i';
      _addGenreSkillButton(
        positionId: id,
        position: minorSkillTrack11[i].position,
      );
    }

    final majorSkillTrack5 = getDividingPointsFromCircle(
        center.x, center.y, 1152, 20,
        angleOffset: -9);
    for (var i = 0; i < majorSkillTrack5.length; i++) {
      final id = 'majorSkillTrack5_$i';
      _addGenreSkillButton(
        positionId: id,
        position: majorSkillTrack5[i].position,
      );
    }

    final minorSkillTrack12 =
        getDividingPointsFromCircle(center.x, center.y, 1152, 80);
    for (var i = 0; i < minorSkillTrack12.length; i++) {
      if ((i - 2) % 4 == 0) continue;
      final id = 'minorSkillTrack12_$i';
      _addGenreSkillButton(
        positionId: id,
        position: minorSkillTrack12[i].position,
      );
    }

    // for (final skillData in GameData.cultivationSkillData.values) {
    //   final p = skillData['relativePosition'];
    //   if (p != null) {
    //     final String sizeDescriptor = skillData['size'];

    //     _addGenreSkillButton(
    //       skillId: skillData['skillId'],
    //       positionOffset: Vector2(p['x'], p['y']),
    //       size: size,
    //       isEnabled: skillData['isEnabled'] ?? false,
    //       isAttribute: skillData['isAttribute'] ?? false,
    //     );
    //   }
    // }

    final lightTrailCoordinates1 =
        getDividingPointsFromCircle(center.x, center.y, 200, 24);
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
        getDividingPointsFromCircle(center.x, center.y, 350, 30);
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
        getDividingPointsFromCircle(center.x, center.y, 500, 36);
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

    udpateLevelDescription();
  }

  Future<void> checkEXP() async {
    int level = _heroData['cultivationLevel'];
    int expForNextLevel = expForLevel(level);
    int exp = _heroData['exp'];

    while (exp >= expForNextLevel) {
      exp -= expForNextLevel;
      expForNextLevel = expForLevel(++level);

      engine.hetu
          .invoke('characterCultivationLevelUp', positionalArgs: [_heroData]);

      hint(
        '${engine.locale('cultivationLevel')} + 1',
        positionOffsetY: 60,
        color: Colors.yellow,
      );

      if (_isFirstCultivation) {
        _isFirstCultivation = false;
        //   // 初次修炼
        //   final majorAttribute =
        //       engine.hetu.invoke('getMajorAttribute', positionalArgs: [heroData]);
        //   selectedGenre = kAttributesToGenre[majorAttribute];
        //   cultivationGenreButton.spriteId =
        //       'cultivation/deckbuilding/$selectedGenre.png';
        //   cultivationGenreButton.hoverSpriteId =
        //       'cultivation/deckbuilding/${selectedGenre}_hover.png';
        //   await cultivationGenreButton.tryLoadSprite();
        //   cultivationGenreButton.fadeIn(duration: _kButtonAnimationDuration);
        //   cultivationGenreButton.moveTo(
        //       toPosition: GameUI.cultivationGenreButtonPosition,
        //       duration: _kButtonAnimationDuration,
        //       onComplete: () async {
        //         cultivationGenreButton.isEnabled = true;
        //         cardLibraryButton.fadeIn(duration: _kButtonAnimationDuration);
        //         cardLibraryButton.moveTo(
        //             toPosition: GameUI.cardLibraryButtonPosition,
        //             duration: _kButtonAnimationDuration,
        //             onComplete: () {
        //               cardLibraryButton.isEnabled = true;
        //             });
        //       });
        promoteRank();
      }

      udpateLevelDescription();
    }

    expBar.setValue(exp);
    expBar.max = expForNextLevel;
  }

  int promoteRank() {
    final newRank = engine.hetu
        .invoke('characterCultivationRankUp', positionalArgs: [_heroData]);
    // cultivationRankButton.spriteId = 'cultivation/cultivation$newRank.png';
    // cultivationRankButton.hoverSpriteId =
    //     'cultivation/cultivation${newRank}_hover.png';
    // cultivationRankButton.tryLoadSprite();

    final rankName = engine.locale('cultivationRank.$newRank');
    hint(
      '${engine.locale('rankUp!')} $rankName',
      positionOffsetY: 30,
      duration: 6,
      color: Colors.lightBlue,
    );

    return newRank;
  }

  Future<void> checkRank() async {}

  Future<void> condenseOne(LightPoint light,
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

        _heroData['unconvertedExp'] -= _kExpPerLightPoint;
        _heroData['exp'] += _kExpPerLightPoint;
        expBar.setValue(expBar.value + _kExpPerLightPoint);

        onComplete?.call();

        hint('${engine.locale('exp')} + $_kExpPerLightPoint');
      },
    );
  }

  FutureOr<void> condenseAll() async {
    if (_lightPoints.isEmpty) return;

    int level = _heroData['cultivationLevel'];
    int expForNextLevel = expForLevel(level);
    int points = _heroData['exp'];
    int exp = _heroData['unconvertedExp'];

    int number;
    if (exp >= expForNextLevel - points) {
      number = ((expForNextLevel - points) / 20).ceil();
      assert(number <= _lightPoints.length);
    } else {
      number = _lightPoints.length;
    }

    final completer = Completer();
    for (var i = 0; i < number; ++i) {
      final light = _lightPoints[i];
      final lastIndex = number - 1;

      condenseOne(light, () {
        if (i == lastIndex) {
          completer.complete();
          checkEXP();
          checkRank();
        }
      });
    }
    return completer.future;
  }

  @override
  void onDragUpdate(int pointer, int buttons, DragUpdateDetails details) {
    super.onDragUpdate(pointer, buttons, details);

    // if (buttons == kSecondaryButton) {
    camera.moveBy(-details.delta.toVector2() / camera.zoom);
    // }
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
}
