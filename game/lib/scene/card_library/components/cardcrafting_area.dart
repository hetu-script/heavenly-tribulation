// import 'package:flame/components.dart';
// import 'package:flame/flame.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/components.dart';
import 'package:samsara/gestures.dart';
// import 'package:samsara/samsara.dart';
// import 'package:samsara/components/hovertip.dart';
import 'package:samsara/samsara.dart';
// import 'package:samsara/components/sprite_component2.dart';

import '../../../ui.dart';
import '../../../engine.dart';
import 'common.dart';
import '../../../dialog/game_dialog/game_dialog.dart';
import '../../../data.dart';

class CardCraftingArea extends GameComponent {
  bool _isCrafting = false;
  bool get isCrafting => _isCrafting;

  late final BorderComponent buttonContainer;

  late final SpriteButton craftButton;

  final List<SpriteButton> craftOptionButtons = [];

  late final Function() onStartCraft;
  late final Function(GameCard card) onRemoveCard;

  late final PiledZone craftingZone;

  bool get isFull => craftingZone.isFull;

  Future<void> startCraft() async {
    onStartCraft.call();
    _isCrafting = true;

    await craftButton.moveTo(
      duration: 0.3,
      toPosition: GameUI.cardCraftingZonePosition,
    );

    game.world.add(craftingZone);
    game.camera.viewport.add(buttonContainer);
  }

  Future<void> endCraft() async {
    _isCrafting = false;

    Hovertip.hide(craftButton);

    removeCard();

    craftButton.moveTo(
      duration: 0.3,
      toPosition: GameUI.cardCraftingZoneInitialPosition,
    );

    craftingZone.removeFromParent();
    buttonContainer.removeFromParent();
  }

  void removeCard() {
    if (craftingZone.isFull) {
      Hovertip.hide(craftButton);
      final c = craftingZone.removeCardByIndex(0) as GameCard;
      onRemoveCard(c);
    }
  }

  void showCardInfo() {
    Hovertip.show(
      scene: game,
      target: craftButton,
      direction: HovertipDirection.leftCenter,
      content: (craftingZone.cards.first as CustomGameCard).extraDescription,
      config: ScreenTextConfig(anchor: Anchor.topCenter),
    );
  }

  void addCard(GameCard card) async {
    if (craftingZone.isFull) {
      removeCard();
    }
    card.enableGesture = false;
    await craftingZone.placeCard(card);

    showCardInfo();
  }

  CardCraftingArea({
    super.priority,
    required this.onStartCraft,
    required this.onRemoveCard,
  }) : super(
          position: GameUI.cardCraftingZoneInitialPosition,
          size: GameUI.cardCraftingZoneSize,
        );

  @override
  void onLoad() async {
    super.onLoad();

    craftButton = SpriteButton(
      spriteId: 'cultivation/cardlibrary_cardcraft.png',
      size: size,
      position: GameUI.cardCraftingZoneInitialPosition,
      priority: kBarPriority,
    );

    craftButton.onTapUp = (buttons, position) {
      if (isCrafting) {
        if (craftingZone.isFull) {
          if (buttons == kPrimaryButton) {
            Hovertip.toogle(craftButton, scene: game);
          } else if (buttons == kSecondaryButton) {
            removeCard();
          }
        }
      } else {
        Hovertip.hide(craftButton);
        if (buttons == kPrimaryButton) {
          startCraft();
        }
      }
    };

    craftButton.onMouseEnter = () {
      if (isCrafting) {
        if (craftingZone.isFull) {
          if (Hovertip.hastip(craftButton)) {
            Hovertip.toogle(craftButton, scene: game, justShow: true);
          }
        } else {
          Hovertip.show(
            scene: game,
            target: craftButton,
            direction: HovertipDirection.leftCenter,
            content: engine.locale('deckbuilding.crafingCardHint'),
            config: ScreenTextConfig(anchor: Anchor.topCenter),
            width: 200,
          );
        }
      } else {
        Hovertip.show(
          scene: game,
          target: craftButton,
          direction: HovertipDirection.topCenter,
          content: engine.locale('deckbuilding.crafingCard'),
          config: ScreenTextConfig(anchor: Anchor.topCenter),
          width: 200,
        );
      }
    };
    craftButton.onMouseExit = () {
      if (!craftingZone.isFull) {
        Hovertip.hide(craftButton);
      }
    };
    game.world.add(craftButton);

    craftingZone = PiledZone(
      position: GameUI.cardCraftingZonePosition,
      pileMargin: Vector2(15, 35),
      piledCardSize: GameUI.deckbuildingCardSize,
      limit: 1,
      priority: kCardCraftingZonePriority,
    );

    buttonContainer = BorderComponent(
      position: GameUI.cardCraftingZonePosition +
          Vector2(GameUI.cardCraftingZoneSize.x / 2,
              GameUI.cardCraftingZoneSize.y + GameUI.largeIndent),
    );

    _getAffixOperationButton('identifyAffix');
    _getAffixOperationButton('addAffix');
    _getAffixOperationButton('rerollAffix');
    _getAffixOperationButton('replaceAffix');
    _getAffixOperationButton('upgradeCard');
    _getAffixOperationButton('upgradeRank');

    for (var i = 0; i < craftOptionButtons.length; i++) {
      final button = craftOptionButtons[i];
      button.position = Vector2(0, (GameUI.buttonSizeSmall.y + 10) * i);
    }
  }

  SpriteButton _getAffixOperationButton(String id) {
    final SpriteButton button = SpriteButton(
      anchor: Anchor.topCenter,
      spriteId: 'ui/button10.png',
      size: Vector2(140, 30),
      text: engine.locale('deckbuilding_$id'),
    );
    button.onTapUp = (buttons, position) {
      Hovertip.hide(button);
      _affixOperation(craftingZone.cards.firstOrNull as CustomGameCard?, id);
    };
    button.onMouseEnter = () {
      Hovertip.show(
        scene: game,
        target: button,
        direction: HovertipDirection.leftTop,
        content: engine.locale('deckbuilding_${id}_description'),
        config: ScreenTextConfig(anchor: Anchor.topCenter),
      );
    };
    button.onMouseExit = () {
      Hovertip.hide(button);
    };

    buttonContainer.add(button);
    craftOptionButtons.add(button);
    return button;
  }

  void _affixOperation(CustomGameCard? card, String id) {
    if (card == null) {
      GameDialog.show(
        context: game.context,
        dialogData: {
          'lines': [engine.locale('deckbuilding_no_card_hint')],
        },
      );
      return;
    }

    final result = engine.hetu.invoke(id, positionalArgs: [card.data]);

    if (result != null) {
      // 如果不能进行精炼，返回的是错误信息的本地化字符串key
      GameDialog.show(
        context: game.context,
        dialogData: {
          'lines': [engine.locale(result)],
        },
      );
    } else {
      engine.play('hammer-hitting-an-anvil-25390.mp3');

      game.addHintText(
        engine.locale('deckbuilding_${id}_hint'),
        position: card.center,
        offsetY: 30.0,
        textStyle: TextStyle(
          fontFamily: GameUI.fontFamily,
        ),
        horizontalVariation: 0.0,
        verticalVariation: 0.0,
      );

      final (description, extraDescription) =
          GameData.getDescriptionFromCardData(card.data);
      card.description = description;
      card.extraDescription = extraDescription;
      showCardInfo();
    }
  }
}
