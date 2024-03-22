import 'package:flutter/material.dart';
import 'package:samsara/ui/ink_button.dart';

import '../../config.dart';

const _kPopupButtonSize = Size(40.0, 40.0);

class WorldMapPopup extends StatelessWidget {
  static const defaultSize = 160.0;

  final double left, top, width = defaultSize, height = defaultSize;

  final VoidCallback? onPanelTapped;

  // 位置：上
  final bool moveToIcon;
  final bool meditateIcon;

  // 位置：左
  final bool enterIcon;
  final bool exploreIcon;

  // final bool talkIcon;

  // 位置：下
  final bool interactIcon;

  // 位置：右

  // final String description;

  final void Function()? onMoveTo;
  final void Function()? onMeditate;

  final void Function()? onEnter;
  final void Function()? onExplore;

  // final void Function()? onTalk;
  final void Function()? onInteract;

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
    // this.talkIcon = false,
    // this.onTalk,
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
                  color: Theme.of(context).primaryColor.withOpacity(0.2),
                  border: Border.all(color: kForegroundColor),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 3,
                      blurRadius: 6,
                      offset: const Offset(0, 2), // changes position of shadow
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(20),
                // child: Align(
                //   alignment: Alignment.center,
                //   child: Text(
                //     description,
                //     style: const TextStyle(
                //       fontSize: 12,
                //     ),
                //   ),
                // ),
              ),
              if (moveToIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Tooltip(
                      message: engine.locale('moveTo'),
                      child: InkButton(
                        size: _kPopupButtonSize,
                        child: const Image(
                          image: AssetImage('assets/images/icon/move_to.png'),
                        ),
                        onPressed: () => onMoveTo?.call(),
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
                        size: _kPopupButtonSize,
                        child: const Image(
                          image: AssetImage('assets/images/icon/hand.png'),
                        ),
                        onPressed: () => onInteract?.call(),
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
                        size: _kPopupButtonSize,
                        child: const Image(
                          image: AssetImage('assets/images/icon/enter.png'),
                        ),
                        onPressed: () => onEnter?.call(),
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
                        size: _kPopupButtonSize,
                        child: const Image(
                          image: AssetImage('assets/images/icon/search.png'),
                        ),
                        onPressed: () => onExplore?.call(),
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
                        size: _kPopupButtonSize,
                        child: const Image(
                          image: AssetImage('assets/images/icon/meditate.png'),
                        ),
                        onPressed: () => onMeditate?.call(),
                      ),
                    ),
                  ),
                ),
              // if (practiceIcon)
              //   Positioned.fill(
              //     child: Align(
              //       alignment: Alignment.centerLeft,
              //       child: InkImageButton(
              //         width: _kPopupButtonSize,
              //         height: _kPopupButtonSize,
              //         tooltip: engine.locale('practice'],
              //         child: const Image(
              //           image: AssetImage('assets/images/icon/practice.png'),
              //         ),
              //         onPressed: () {
              //           if (onPractice != null) {
              //             onPractice!();
              //           }
              //         },
              //       ),
              //     ),
              //   ),
            ],
          ),
        ),
      ),
    );
  }
}
