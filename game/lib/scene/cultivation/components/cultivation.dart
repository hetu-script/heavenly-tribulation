import 'dart:async';
import 'dart:math' as math;

import 'package:samsara/gestures.dart';
import 'package:samsara/samsara.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:samsara/components/progress_indicator.dart';
import 'package:samsara/components/tooltip.dart';
import 'package:samsara/components/sprite_button.dart';
import 'package:samsara/components/fading_text.dart';
import 'package:samsara/utils/math.dart';
import 'package:samsara/components/text_component2.dart';
import 'package:hetu_script/utils.dart';

// import 'cultivator.dart';
import 'light_trail.dart';
import 'light_point.dart';
import '../../../config.dart';
import '../../../logic/algorithm.dart';
import '../../../ui.dart';
import '../../../common.dart';
import '../../common.dart';
import '../../../events.dart';

const _kLightPointMoveSpeed = 450.0;
// const _kButtonAnimationDuration = 1.2;
const _kExpPerLightPoint = 20;

enum CultivationSceneState {
  meditate, // 内观，可以通过时间流逝产生新的经验球，可以点击收集经验球，可以组合经验球来获得卡包
  // introspection,
  enlightenment, // 悟道，技能模式，显示天赋树
}

class CultivationScene extends Scene {
  static final random = math.Random();

  late final SpriteComponent backgroundSprite;

  final dynamic heroData;

  late final SpriteButton cultivator;

  final List<LightPoint> _lightPoints = [];

  final List<LightTrail> _lightTrails = [];

  // String? selectedGenre;

  late final TextComponent2 levelDescription;

  late final DynamicColorProgressIndicator expBar;

  late final SpriteButton //cultivationRankButton,
      cardPacksButton,
      cardLibraryButton,
      meditateButton,
      // introspectionButton,
      enlightenmentButton;

  late bool _isFirstCultivation;

  final Map<String, SpriteButton> _skillButtons = {};

  CultivationSceneState state = CultivationSceneState.meditate;

  void setState(CultivationSceneState state) {
    this.state = state;

    for (final trail in _lightTrails) {
      trail.isVisible = state == CultivationSceneState.meditate;
    }

    for (final light in _lightPoints) {
      light.isVisible = state == CultivationSceneState.meditate;
    }

    for (final button in _skillButtons.values) {
      button.isVisible = state == CultivationSceneState.enlightenment;
    }
  }

  Map<String, int> _skillLevels = {};

  void characterSkillLevelUp(String id) {
    int availablePoints = heroData['availableCultivationPoints'];
    if (availablePoints <= 0) return;

    heroData['availableCultivationPoints'] = --availablePoints;

    final current = (_skillLevels[id] ?? 0) + 1;
    _skillLevels[id] = current;
    final button = _skillButtons[id]!;
    _skillButtons[id]!.text = current.toString();
    button.isEnabled = false;
    // final current = _skillLevels[id];
    // if (current == null) {
    //   if (offset > 0) {
    //     _skillLevels[id] = offset;
    //     final button = _skillButtons[id]!;
    //     button.text = offset.toString();
    //     button.isDarkened = false;
    //   }
    // } else {
    //   final result = current + offset;
    //   if (result >= 0) {
    //     _skillLevels[id] = current + offset;
    //     final button = _skillButtons[id]!;
    //     if (result > 0) {
    //       button.text = _skillLevels[id].toString();
    //       button.isDarkened = false;
    //     } else {
    //       _skillButtons[id]!.text = null;
    //       button.isDarkened = true;
    //     }
    //   }
    // }

    setLevelDescription();
  }

  CultivationScene({
    required super.controller,
    required super.context,
    required this.heroData,
    bool talentTreeMode = false,
  }) : super(id: 'cultivation', enableLighting: true) {
    // selectedGenre = heroData['cultivationGenre'];

    _isFirstCultivation = heroData['cultivationRank'] == 0;

    _skillLevels =
        Map<String, int>.from(jsonify(deepCopy(heroData['cultivationSkills'])));
  }

  void addHintText(String text,
      {required double offset, double duration = 1.2, Color? textColor}) {
    final c2 = FadingText(
      text,
      position: Vector2(cultivator.center.x, cultivator.center.y - offset),
      movingUpOffset: 100,
      duration: duration,
      config: ScreenTextConfig(
        textStyle: TextStyle(
          color: textColor ?? Colors.white,
          fontSize: 28,
          fontWeight: FontWeight.bold,
          fontFamily: 'RuiZiYunZiKuLiBianTiGBK',
        ),
      ),
      priority: kHintTextPriority,
    );
    world.add(c2);
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

    cultivator = SpriteButton(
      anchor: Anchor.center,
      sprite: Sprite(await Flame.images.load('cultivation/cultivator.png')),
      position: GameUI.cultivatorPosition,
      size: GameUI.cultivatorSize,
      onTap: (buttons, position) {
        if (state == CultivationSceneState.meditate) {
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
    world.add(cultivator);

    final exp = heroData['unconvertedExp'];
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
      lightPoint.onTapDown = (_, __) {
        condenseOne(lightPoint, () {
          checkEXP();
          checkRank();
        });
      };
      lightPoint.onDragOver = (_, __) {
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
          fontFamily: 'RuiZiYunZiKuLiBianTiGBK',
        ),
      ),
    );
    setLevelDescription();
    camera.viewport.add(levelDescription);

    int level = heroData['cultivationLevel'];
    int points = heroData['exp'];
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
    );
    expBar.onMouseEnter = () {
      final level = heroData['cultivationLevel'];
      Tooltip.show(
        scene: this,
        target: expBar,
        direction: TooltipDirection.topLeft,
        content: '${engine.locale('exp')}: ${heroData['exp']}\n'
            '${engine.locale('cultivationPointsNeededForNextLevel')}: ${expForLevel(level)}',
      );
    };
    expBar.onMouseExit = () {
      Tooltip.hide();
    };
    camera.viewport.add(expBar);

    meditateButton = SpriteButton(
      text: engine.locale('meditate'),
      anchor: Anchor.center,
      position: GameUI.meditateButtonPosition,
      size: GameUI.stateButtonSize,
      spriteId: 'ui/button2.png',
      onTap: (buttons, position) {
        meditateButton.spriteId = 'ui/button2.png';
        meditateButton.tryLoadSprite();
        // introspectionButton.spriteId = 'ui/button.png';
        // introspectionButton.tryLoadSprite();
        enlightenmentButton.spriteId = 'ui/button.png';
        enlightenmentButton.tryLoadSprite();
        setState(CultivationSceneState.meditate);
      },
    );
    camera.viewport.add(meditateButton);

    // introspectionButton = SpriteButton(
    //   text: engine.locale('introspection'),
    //   anchor: Anchor.center,
    //   position: GameUI.introspectionButtonPosition,
    //   size: GameUI.stateButtonSize,
    //   spriteId: 'ui/button.png',
    //   onTap: (buttons, position) {
    //     meditateButton.spriteId = 'ui/button.png';
    //     meditateButton.tryLoadSprite();
    //     introspectionButton.spriteId = 'ui/button2.png';
    //     introspectionButton.tryLoadSprite();
    //     enlightenmentButton.spriteId = 'ui/button.png';
    //     enlightenmentButton.tryLoadSprite();
    //     setState(CultivationSceneState.introspection);
    //   },
    // );
    // camera.viewport.add(introspectionButton);

    enlightenmentButton = SpriteButton(
      text: engine.locale('enlightenment'),
      anchor: Anchor.center,
      position: GameUI.enlightenmentButtonPosition,
      size: GameUI.stateButtonSize,
      spriteId: 'ui/button.png',
      onTap: (buttons, position) {
        meditateButton.spriteId = 'ui/button.png';
        meditateButton.tryLoadSprite();
        // introspectionButton.spriteId = 'ui/button.png';
        // introspectionButton.tryLoadSprite();
        enlightenmentButton.spriteId = 'ui/button2.png';
        enlightenmentButton.tryLoadSprite();
        setState(CultivationSceneState.enlightenment);
      },
    );
    camera.viewport.add(enlightenmentButton);

    cardLibraryButton = SpriteButton(
        anchor: Anchor.center,
        position:
            // _isFirstCultivation
            //   ? GameUI.condensedPosition
            //   :
            GameUI.cardLibraryButtonPosition,
        size: GameUI.cardLibraryButtonSize,
        // isEnabled: selectedGenre != null,
        // opacity: selectedGenre != null ? 1 : 0,
        spriteId: 'cultivation/library.png',
        // selectedGenre != null ? '$selectedGenre.png' : null,
        hoverSpriteId: 'cultivation/library_hover.png'
        // selectedGenre != null
        //     ? 'cultivation/deckbuilding/${selectedGenre}_hover.png'
        //     : null,
        );
    camera.viewport.add(cardLibraryButton);

    cardPacksButton = SpriteButton(
      anchor: Anchor.center,
      position:
          // _isFirstCultivation
          //     ? GameUI.condensedPosition
          //     :
          GameUI.cardPacksButtonPosition,
      size: GameUI.cardPacksButtonSize,
      // isEnabled: rank > 0,
      // opacity: rank > 0 ? 1 : 0,
      spriteId: 'cultivation/cardpack.png',
      hoverSpriteId: 'cultivation/cardpack_hover.png',
      onTap: (buttons, position) {
        engine.emit(UIEvents.cardPacksButtonClicked);
      },
    );
    camera.viewport.add(cardPacksButton);

    final mainGenrePositions = getDividingPointsFromCircle(
        cultivator.center.x, cultivator.center.y, 140, 5);
    final mainGenreEnalbed = {
      0: true,
      1: false,
      2: false,
      3: false,
      4: true,
    };
    for (var i = 0; i < kMainCultivationGenres.length; ++i) {
      final genre = kMainCultivationGenres[i];
      final p = mainGenrePositions[i];
      final position = p.position;

      addGenreSkillButton(
        genre: genre,
        position: position,
        size: GameUI.talentTreeButtonSizeL,
        isEnabled: mainGenreEnalbed[i]!,
      );
    }

    final supportGenrePositions = getDividingPointsFromCircle(
        cultivator.center.x, cultivator.center.y, 200, 10,
        angleOffset: -18);
    final supportGenreEnalbed = {
      0: true,
      1: true,
      2: false,
      3: false,
      4: false,
      5: false,
      6: false,
      7: false,
      8: true,
      9: true,
    };
    for (var i = 0; i < kSupportCultivationGenres.length; ++i) {
      final genre = kSupportCultivationGenres[i];
      final position = supportGenrePositions[i].position;
      addGenreSkillButton(
        genre: genre,
        position: position,
        size: GameUI.talentTreeButtonSizeM,
        isEnabled: supportGenreEnalbed[i]!,
      );
    }

    final coordinates1 =
        getDividingPointsFromCircle(center.x, center.y, 200, 24);
    _lightTrails.addAll([
      LightTrail(
        radius: 200,
        index: 0,
        points: coordinates1,
      ),
      LightTrail(
        radius: 200,
        index: 8,
        points: coordinates1,
      ),
      LightTrail(
        radius: 200,
        index: 16,
        points: coordinates1,
      ),
    ]);

    final coordinates2 =
        getDividingPointsFromCircle(center.x, center.y, 350, 30);
    _lightTrails.addAll([
      LightTrail(
        radius: 350,
        index: 0,
        points: coordinates2,
      ),
      LightTrail(
        radius: 350,
        index: 6,
        points: coordinates2,
      ),
      LightTrail(
        radius: 350,
        index: 12,
        points: coordinates2,
      ),
      LightTrail(
        radius: 350,
        index: 18,
        points: coordinates2,
      ),
      LightTrail(
        radius: 350,
        index: 24,
        points: coordinates2,
      ),
    ]);

    final coordinates3 =
        getDividingPointsFromCircle(center.x, center.y, 500, 36);
    _lightTrails.addAll([
      LightTrail(
        radius: 500,
        index: 0,
        points: coordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 4,
        points: coordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 8,
        points: coordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 12,
        points: coordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 16,
        points: coordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 20,
        points: coordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 24,
        points: coordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 28,
        points: coordinates3,
      ),
      LightTrail(
        radius: 500,
        index: 32,
        points: coordinates3,
      ),
    ]);

    for (final lightTrail in _lightTrails) {
      world.add(lightTrail);
    }
  }

  void addGenreSkillButton({
    required String genre,
    required Vector2 position,
    required Vector2 size,
    bool isEnabled = true,
  }) {
    final button = SpriteButton(
      anchor: Anchor.center,
      position: position,
      size: size,
      spriteId: 'cultivation/deckbuilding/$genre.png',
      hoverSpriteId: 'cultivation/deckbuilding/${genre}_hover.png',
      borderSpriteId: 'cultivation/talent_background.png',
      isVisible: false,
      isEnabled: _skillLevels[genre] == null || _skillLevels[genre] == 0,
      priority: 20,
      lightConfig: LightConfig(radius: 25),
      onTap: (buttons, position) {
        if (buttons == kPrimaryButton) {
          characterSkillLevelUp(genre);
        } else if (buttons == kSecondaryButton) {
          // characterSkillLevelUp(genre, -1);
        }
      },
      text: _skillLevels[genre]?.toString(),
      textConfig: ScreenTextConfig(
        anchor: Anchor.bottomCenter,
        textStyle: const TextStyle(fontSize: 18),
      ),
    );
    _skillButtons[genre] = button;
    world.add(button);
  }

  void setLevelDescription() {
    levelDescription.text =
        '${engine.locale('cultivationRank')}: ${engine.locale('cultivationRank.${heroData['cultivationRank']}')} '
        '${engine.locale('cultivationLevel')}: ${heroData['cultivationLevel']} '
        '${engine.locale('availableCultivationPoints')}: ${heroData['availableCultivationPoints']}';
  }

  Future<void> checkEXP() async {
    int level = heroData['cultivationLevel'];
    int expForNextLevel = expForLevel(level);
    int points = heroData['exp'];

    while (points >= expForNextLevel) {
      points -= expForNextLevel;
      expForNextLevel = expForLevel(++level);

      engine.hetu
          .invoke('characterCultivationLevelUp', positionalArgs: [heroData]);

      addHintText('${engine.locale('cultivationLevel')}+1',
          offset: 60, duration: 4, textColor: Colors.yellow);

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

      setLevelDescription();
    }

    expBar.setValue(points);
    expBar.max = expForNextLevel;
  }

  int promoteRank() {
    final newRank = engine.hetu
        .invoke('characterCultivationRankUp', positionalArgs: [heroData]);
    // cultivationRankButton.spriteId = 'cultivation/cultivation$newRank.png';
    // cultivationRankButton.hoverSpriteId =
    //     'cultivation/cultivation${newRank}_hover.png';
    // cultivationRankButton.tryLoadSprite();

    final rankName = engine.locale('cultivationRank.$newRank');
    addHintText('${engine.locale('rankUp!')} $rankName',
        offset: 30, duration: 6, textColor: Colors.lightBlue);

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

        heroData['unconvertedExp'] -= _kExpPerLightPoint;
        heroData['exp'] += _kExpPerLightPoint;
        expBar.setValue(expBar.value + _kExpPerLightPoint);

        onComplete?.call();

        addHintText('${engine.locale('exp')}+$_kExpPerLightPoint', offset: 0);
      },
    );
  }

  FutureOr<void> condenseAll() async {
    if (_lightPoints.isEmpty) return;

    int level = heroData['cultivationLevel'];
    int expForNextLevel = expForLevel(level);
    int points = heroData['exp'];
    int exp = heroData['unconvertedExp'];

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

    if (buttons == kSecondaryButton) {
      camera.moveBy(-details.delta.toVector2());
    }
  }
}
