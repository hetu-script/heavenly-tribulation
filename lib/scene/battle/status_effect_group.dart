import 'package:samsara/samsara.dart';
import 'package:samsara/gestures.dart';
import 'package:flame/sprite.dart';
import 'package:samsara/components/ui/hovertip.dart';

import '../../global.dart';
import '../../ui.dart';
import 'status_effect.dart';

enum StatusDisplayGroupHoverMode {
  effectList,
  valueList,
  parameterList,
}

final class StatusDisplayGroupConfig {
  final String id;
  final String icon;
  final String title;
  final String description;
  final int priority;
  final StatusDisplayGroupHoverMode hoverMode;
  final String? valueParameter;
  final String valueSuffix;

  const StatusDisplayGroupConfig({
    required this.id,
    required this.icon,
    required this.title,
    required this.description,
    required this.hoverMode,
    this.priority = 0,
    this.valueParameter,
    this.valueSuffix = '',
  });
}

const kStatusDisplayGroups = <String, StatusDisplayGroupConfig>{
  'scry': StatusDisplayGroupConfig(
    id: 'scry',
    icon: 'icon/status/permanent/scry.png',
    title: 'status_display_group_scry',
    description: 'status_display_group_scry_description',
    hoverMode: StatusDisplayGroupHoverMode.effectList,
  ),
  'kind_damage': StatusDisplayGroupConfig(
    id: 'kind_damage',
    icon: 'icon/status/permanent/increase_damage.png',
    title: 'status_display_group_kind_damage',
    description: 'status_display_group_kind_damage_description',
    hoverMode: StatusDisplayGroupHoverMode.valueList,
  ),
  'elemental_resist': StatusDisplayGroupConfig(
    id: 'elemental_resist',
    icon: 'icon/status/permanent/resistant_elemental.png',
    title: 'status_display_group_elemental_resist',
    description: 'status_display_group_elemental_resist_description',
    hoverMode: StatusDisplayGroupHoverMode.valueList,
  ),
  'attack_type': StatusDisplayGroupConfig(
    id: 'attack_type',
    icon: 'icon/status/permanent/enhance.png',
    title: 'status_display_group_attack_type',
    description: 'status_display_group_attack_type_description',
    hoverMode: StatusDisplayGroupHoverMode.valueList,
  ),
  'turn_start_resource': StatusDisplayGroupConfig(
    id: 'turn_start_resource',
    icon: 'icon/status/permanent/turn_start_resource.png',
    title: 'status_display_group_turn_start_resource',
    description: 'status_display_group_turn_start_resource_description',
    hoverMode: StatusDisplayGroupHoverMode.parameterList,
    valueParameter: 'resourceAmount',
  ),
};

class StatusEffectGroup extends BorderComponent with HandlesGesture {
  final StatusDisplayGroupConfig config;
  final List<StatusEffect> _effects = [];

  late final Sprite sprite;

  List<StatusEffect> get effects => List.unmodifiable(_effects);
  String get id => config.id;
  int get effectPriority => config.priority;

  StatusEffectGroup({
    required this.config,
    required StatusEffect effect,
    super.position,
    super.anchor,
  }) {
    _effects.add(effect);
    size = GameUI.permanentStatusEffectIconSize;

    onMouseEnter = () {
      Hovertip.show(
        scene: game,
        target: this,
        direction: HovertipDirection.topLeft,
        content: description,
        width: 280.0,
      );
    };
    onMouseExit = () {
      Hovertip.hide(this);
    };
  }

  void addEffect(StatusEffect effect) {
    if (!_effects.contains(effect)) _effects.add(effect);
  }

  void removeEffect(StatusEffect effect) {
    _effects.remove(effect);
  }

  bool get isEmpty => _effects.isEmpty;

  String get description {
    final buffer = StringBuffer(
      '${engine.locale(config.title)}\n${engine.locale(config.description)}',
    );
    final sorted = _effects.toList()
      ..sort((a, b) {
        final byPriority = b.effectPriority.compareTo(a.effectPriority);
        return byPriority != 0 ? byPriority : a.id.compareTo(b.id);
      });
    for (final effect in sorted) {
      final title = engine.locale(effect.data['title']);
      switch (config.hoverMode) {
        case StatusDisplayGroupHoverMode.valueList:
          buffer.write('\n$title：${effect.amount}%');
        case StatusDisplayGroupHoverMode.parameterList:
          final value = effect.data[config.valueParameter] ?? 0;
          buffer.write('\n$title：$value${config.valueSuffix}');
        case StatusDisplayGroupHoverMode.effectList:
          buffer.write(
            '\n$title\n${engine.locale(effect.data['description'])}',
          );
      }
    }
    return buffer.toString();
  }

  @override
  Future<void> onLoad() async {
    sprite = await Sprite.load(config.icon);
  }

  @override
  void render(Canvas canvas) {
    sprite.render(canvas, size: size);
  }
}
