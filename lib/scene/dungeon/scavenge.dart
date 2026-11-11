import 'package:flame/components.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:samsara/components.dart';
import 'package:samsara/samsara.dart';

import '../../data/game.dart';
import '../../global.dart';
import '../../ui.dart';
import '../../widgets/common.dart';

class DungeonScavengeComponent extends PositionComponent {
  DungeonScavengeComponent({
    required this.candidates,
    required this.onSelected,
    required this.onSkip,
    required this.onClose,
    this.isPermanent = false,
  }) : super(
          size: GameUI.size,
          priority: 10050,
        );

  final List candidates;
  final void Function(dynamic card) onSelected;
  final VoidCallback onSkip;
  final VoidCallback onClose;
  final bool isPermanent;

  @override
  Future<void> onLoad() async {
    super.onLoad();

    add(RectangleComponent(
      size: GameUI.size,
      paint: Paint()..color = const Color(0x99000000),
    ));

    add(RichTextComponent(
      position: Vector2(GameUI.center.x, GameUI.center.y - 260),
      anchor: Anchor.center,
      text:
          '${engine.locale(isPermanent ? 'scavengePermanentTitle' : 'scavengeTitle')}\n${engine.locale(isPermanent ? 'scavengePermanentHint' : 'scavengeHint')}',
      config: ScreenTextConfig(
        anchor: Anchor.center,
        outlined: true,
        textAlign: TextAlign.center,
        textStyle: TextStyles.titleMedium,
      ),
    ));

    for (var i = 0; i < candidates.length; ++i) {
      final card = GameData.createBattleCard(candidates[i]);
      card.anchor = Anchor.center;
      card.position = GameUI.cardpackCardPositions[i];
      card.size = GameUI.libraryCardSize;
      card.isFlipped = false;
      card.enableGesture = true;
      card.onTapUp = (button, position) {
        if (button == kSecondaryButton) return;
        onSelected(candidates[i]);
      };
      card.onMouseEnter = () {
        card.showGlow = true;
        previewCard(
          card.data,
          card.toAbsoluteRect(),
          showAffixes: true,
          character: GameData.hero,
        );
      };
      card.onMouseExit = () {
        card.showGlow = false;
        unpreviewCard();
      };
      add(card);
    }

    final closeButton = SpriteButton(
      text: engine.locale('close'),
      anchor: Anchor.center,
      position: Vector2(GameUI.center.x - 150, GameUI.size.y - 100),
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
    );
    closeButton.onTapUp = (button, position) {
      if (button == kSecondaryButton) return;
      onClose();
    };
    add(closeButton);

    final skipButton = SpriteButton(
      text: engine.locale('scavengeSkip'),
      anchor: Anchor.center,
      position: Vector2(GameUI.center.x + 150, GameUI.size.y - 100),
      size: GameUI.buttonSizeMedium,
      spriteId: 'ui/button2.png',
    );
    skipButton.onTapUp = (button, position) {
      if (button == kSecondaryButton) return;
      onSkip();
    };
    add(skipButton);
  }

  @override
  void onRemove() {
    unpreviewCard();
    super.onRemove();
  }
}
