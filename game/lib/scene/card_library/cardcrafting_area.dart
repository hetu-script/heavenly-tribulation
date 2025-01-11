// import 'package:flame/components.dart';
// import 'package:flame/flame.dart';
import 'package:samsara/cardgame/cardgame.dart';
import 'package:samsara/components.dart';
import 'package:samsara/gestures.dart';
// import 'package:samsara/samsara.dart';
// import 'package:samsara/components/hovertip.dart';
import 'package:samsara/samsara.dart';
// import 'package:samsara/components/sprite_component2.dart';

import '../../ui.dart';
import '../../engine.dart';
import 'common.dart';
import '../game_dialog/game_dialog.dart';
import '../../data.dart';

class CardCraftingArea extends PiledZone {
  bool _isCrafting = false;
  bool get isCrafting => _isCrafting;

  late final BorderComponent buttonContainer;

  late final SpriteButton craftButton;

  final List<SpriteButton> craftOptionButtons = [];

  late final void Function() onStartCraft;
  late final void Function(GameCard card) onRemoveCard;

  void hide() async {}

  Future<void> startCraft() async {
    onStartCraft.call();
    _isCrafting = true;

    await craftButton.moveTo(
      duration: 0.3,
      toPosition: GameUI.cardCraftingZonePosition,
    );

    // game.world.add(craftingZone);
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

    // craftingZone.removeFromParent();
    buttonContainer.removeFromParent();
  }

  void removeCard() {
    if (isFull) {
      Hovertip.hide(craftButton);
      final c = removeCardByIndex(0) as GameCard;
      onRemoveCard(c);
    }
  }

  void showCardInfo() {
    final (_, description) = GameData.getDescriptionFromCardData(
        (cards.first as CustomGameCard).data,
        isDetailed: true);
    Hovertip.show(
      scene: game,
      target: craftButton,
      direction: HovertipDirection.leftCenter,
      content: description,
      config: ScreenTextConfig(anchor: Anchor.topCenter),
    );
  }

  @override
  String? tryAddCard(GameCard card,
      {int? index, bool animated = true, bool clone = false}) {
    if (clone) {
      card = card.clone();
      game.world.add(card);
    }

    if (isFull) {
      removeCard();
    }
    card.enableGesture = false;
    placeCard(card).then((_) {
      showCardInfo();
    });

    return null;
  }

  CardCraftingArea({
    required this.onStartCraft,
    required this.onRemoveCard,
  }) : super(
          position: GameUI.cardCraftingZonePosition,
          pileMargin: Vector2(25, 30),
          limit: 1,
          priority: kCardCraftingZonePriority,
          piledCardSize: GameUI.deckbuildingCardSize,
        );

  // position: GameUI.cardCraftingZonePosition,

  @override
  void onLoad() async {
    super.onLoad();

    craftButton = SpriteButton(
      spriteId: 'cultivation/cardlibrary_cardcraft.png',
      size: GameUI.cardCraftingZoneSize,
      position: GameUI.cardCraftingZoneInitialPosition,
      priority: kTopBarPriority,
    );
    craftButton.onTapUp = (buttons, position) {
      if (isCrafting) {
        if (isFull) {
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
        if (isFull) {
          if (Hovertip.hastip(craftButton)) {
            Hovertip.toogle(craftButton, scene: game, justShow: true);
          }
        } else {
          Hovertip.show(
            scene: game,
            target: craftButton,
            direction: HovertipDirection.leftCenter,
            content: engine.locale('deckbuilding_crafing_hint'),
            config: ScreenTextConfig(anchor: Anchor.topCenter),
            width: 200,
          );
        }
      } else {
        Hovertip.show(
          scene: game,
          target: craftButton,
          direction: HovertipDirection.bottomLeft,
          content: engine.locale('deckbuilding_crafing'),
          config: ScreenTextConfig(anchor: Anchor.topCenter),
          width: 200,
        );
      }
    };
    craftButton.onMouseExit = () {
      if (!isFull) {
        Hovertip.hide(craftButton);
      }
    };
    game.world.add(craftButton);

    buttonContainer = BorderComponent(
      position: GameUI.cardCraftingZonePosition +
          Vector2(GameUI.smallIndent,
              GameUI.cardCraftingZoneSize.y + GameUI.largeIndent),
    );

    _getAffixOperationButton('identifyCard');
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
      anchor: Anchor.topLeft,
      spriteId: 'ui/button10.png',
      size: Vector2(140, 30),
      text: engine.locale('deckbuilding_$id'),
    );
    button.onTapUp = (buttons, position) {
      Hovertip.hide(button);
      _affixOperation(cards.firstOrNull as CustomGameCard?, id);
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

      final (description, _) = GameData.getDescriptionFromCardData(card.data);
      card.description = description;
      showCardInfo();
    }
  }
}
