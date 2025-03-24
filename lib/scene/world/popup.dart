import 'package:flutter/material.dart';
import 'package:samsara/ui/ink_button.dart';

import '../../engine.dart';
import '../../game/ui.dart';

const _kPopupButtonSize = Size(40.0, 40.0);

class WorldMapPopup extends StatelessWidget {
  static const defaultSize = 160.0;

  final double left, top, width = defaultSize, height = defaultSize;

  final VoidCallback? onPanelTapped;

  /// 显示`移动`图标（位置：上，条件：点击非英雄所在位置）
  final bool moveToIcon;

  /// 显示`打坐`图标（位置：上，条件：点击英雄所在位置）
  final bool meditateIcon;

  /// 显示`进入`图标（位置：左，条件：有据点的地块）
  final bool enterIcon;

  /// 显示`神识探查`图标（位置：左，条件：无据点的地块）
  final bool exploreIcon;

  /// 显示`交互`图标（位置：下，条件：点击英雄所在位置）
  final bool interactIcon;

  /// 显示`技能`图标（位置：右，条件：点击非英雄所在位置）
  final bool skillIcon;

  final void Function()? onMoveTo;
  final void Function()? onMeditate;

  final void Function()? onEnter;
  final void Function()? onExplore;

  final void Function()? onInteract;

  final void Function()? onSkill;

  const WorldMapPopup({
    super.key,
    required this.left,
    required this.top,
    this.onPanelTapped,
    this.moveToIcon = false,
    this.onMoveTo,
    this.meditateIcon = false,
    this.onMeditate,
    this.enterIcon = false,
    this.onEnter,
    this.exploreIcon = false,
    this.onExplore,
    this.skillIcon = false,
    this.onSkill,
    this.interactIcon = false,
    this.onInteract,
    // this.description = '',
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          if (onPanelTapped != null) {
            onPanelTapped!();
          }
        },
        child: Container(
          color: Colors.transparent,
          width: width,
          height: height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withAlpha(50),
                  border: Border.all(color: GameUI.foregroundColor),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(128),
                      spreadRadius: 3,
                      blurRadius: 6,
                      offset: const Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
              ),
              if (moveToIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Tooltip(
                      message: engine.locale('moveTo'),
                      child: InkButton(
                        color: GameUI.foregroundColor.withAlpha(128),
                        border: Border.all(
                          color: GameUI.foregroundColor,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        size: _kPopupButtonSize,
                        onPressed: onMoveTo,
                        child: const Image(
                          image: AssetImage('assets/images/icon/move_to.png'),
                        ),
                      ),
                    ),
                  ),
                ),
              if (interactIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Tooltip(
                      message: engine.locale('interact'),
                      child: InkButton(
                        color: GameUI.foregroundColor.withAlpha(128),
                        border: Border.all(
                          color: GameUI.foregroundColor,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        size: _kPopupButtonSize,
                        onPressed: onInteract,
                        child: const Image(
                          image: AssetImage('assets/images/icon/hand.png'),
                        ),
                      ),
                    ),
                  ),
                ),
              if (enterIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Tooltip(
                      message: engine.locale('enter'),
                      child: InkButton(
                        color: GameUI.foregroundColor.withAlpha(128),
                        border: Border.all(
                          color: GameUI.foregroundColor,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        size: _kPopupButtonSize,
                        onPressed: onEnter,
                        child: const Image(
                          image: AssetImage('assets/images/icon/enter.png'),
                        ),
                      ),
                    ),
                  ),
                ),
              if (exploreIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Tooltip(
                      message: engine.locale('explore'),
                      child: InkButton(
                        color: GameUI.foregroundColor.withAlpha(128),
                        border: Border.all(
                          color: GameUI.foregroundColor,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        size: _kPopupButtonSize,
                        onPressed: onExplore,
                        child: const Image(
                          image: AssetImage('assets/images/icon/search.png'),
                        ),
                      ),
                    ),
                  ),
                ),
              if (meditateIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Tooltip(
                      message: engine.locale('meditate'),
                      child: InkButton(
                        color: GameUI.foregroundColor.withAlpha(128),
                        border: Border.all(
                          color: GameUI.foregroundColor,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        size: _kPopupButtonSize,
                        child: const Image(
                          image: AssetImage('assets/images/icon/meditate.png'),
                        ),
                        onPressed: () => onMeditate?.call(),
                      ),
                    ),
                  ),
                ),
              if (skillIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Tooltip(
                      message: engine.locale('useMapSkill'),
                      child: InkButton(
                        color: GameUI.foregroundColor.withAlpha(128),
                        border: Border.all(
                          color: GameUI.foregroundColor,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        size: _kPopupButtonSize,
                        onPressed: onSkill,
                        child: const Image(
                          image: AssetImage('assets/images/icon/skill.png'),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
