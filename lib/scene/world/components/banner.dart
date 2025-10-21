import 'package:samsara/samsara.dart';
import 'package:samsara/components/ui/rich_text_component.dart';

import '../../../ui.dart';
import '../../common.dart';

class PromptTextBanner extends BorderComponent {
  late final Color backgroundColor;

  late final String text;

  late final RichTextComponent textComponent;

  PromptTextBanner({
    super.position,
    Color? backgroundColor,
    required this.text,
  }) : super(
          anchor: Anchor.center,
          size: GameUI.promptBannerSize,
          priority: kWorldMapAnimationPriority,
        ) {
    backgroundColor = backgroundColor ?? GameUI.backgroundColor2;
    paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
  }

  @override
  set opacity(double value) {
    super.opacity = value;

    if (isLoaded) {
      textComponent.opacity = value;
    }
  }

  @override
  void onLoad() async {
    textComponent = RichTextComponent(
      text: text,
      size: size,
      config: ScreenTextConfig(
        outlined: true,
        textStyle: GameUI.textTheme.titleLarge,
        anchor: Anchor.center,
        textAlign: TextAlign.center,
      ),
    );
    add(textComponent);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    canvas.drawRect(border, paint);
  }
}
