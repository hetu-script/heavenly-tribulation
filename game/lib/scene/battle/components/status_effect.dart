import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:flame/sprite.dart';
import 'package:flame/flame.dart';
import 'package:samsara/components/tooltip.dart';

import '../../../config.dart';
import '../../../data.dart';
import '../../../ui.dart';

enum StatusEffectType {
  permenant,
  block,
  buff,
  debuff,
  none,
}

StatusEffectType getStatusEffectType(String? id) {
  return StatusEffectType.values.firstWhere((element) => element.name == id,
      orElse: () => StatusEffectType.none);
}

class StatusEffect extends BorderComponent with HandlesGesture {
  static ScreenTextConfig defaultEffectCountStyle = const ScreenTextConfig(
    anchor: Anchor.bottomRight,
    outlined: true,
    textStyle: TextStyle(
      color: Colors.white,
      fontSize: 10.0,
      fontWeight: FontWeight.bold,
    ),
  );

  final String id;

  dynamic data;

  late final Sprite sprite;

  int amount;

  late bool allowNegative;

  late final int effectPriority;

  late final StatusEffectType type;

  bool get isPermenant => type == StatusEffectType.permenant;

  late final bool isUnique;

  final List<String> callbacks = [];

  String? soundId;

  late ScreenTextConfig countTextConfig;

  late final String title, description;

  StatusEffect({
    required this.id,
    required this.amount,
    super.position,
    super.anchor,
    super.priority,
  }) {
    assert(amount >= 1);
    assert(GameData.statusEffectsData.containsKey(id));
    data = GameData.statusEffectsData[id];
    assert(data != null);
    type = getStatusEffectType(data['type']);
    isUnique = data['unique'] ?? false;
    allowNegative = data['allowNegative'] ?? false;
    effectPriority = data['priority'] ?? 0;
    size = isPermenant
        ? GameUI.permenantStatusEffectIconSize
        : GameUI.statusEffectIconSize;
    for (final callbackId in data['callbacks']) {
      callbacks.add(callbackId);
    }
    soundId = data['sound'];
    countTextConfig = defaultEffectCountStyle.copyWith(size: size);

    description =
        '${engine.locale('$id.title')}\n${engine.locale('$id.description')}';

    onMouseEnter = () {
      Tooltip.show(
        scene: gameRef,
        target: this,
        direction: anchor.x == 0
            ? TooltipDirection.topLeft
            : TooltipDirection.topRight,
        content: description,
      );
    };
    onMouseExit = () {
      Tooltip.hide();
    };
  }

  @override
  Future<void> onLoad() async {
    sprite = Sprite(await Flame.images.load('icon/status/$id.png'));
  }

  @override
  void render(Canvas canvas) {
    sprite.render(canvas, size: size);
    drawScreenText(canvas, '$amount', config: countTextConfig);
  }
}
