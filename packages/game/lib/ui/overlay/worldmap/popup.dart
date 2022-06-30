import 'package:flutter/material.dart';

import '../../../global.dart';
import '../../shared/ink_image_button.dart';

const _kPopupButtonSize = 40.0;

class WorldMapPopup extends StatelessWidget {
  static const defaultSize = 160.0;

  final double left, top, width = defaultSize, height = defaultSize;

  final VoidCallback? onPanelTapped;

  final bool moveToIcon;
  final bool checkIcon;
  final bool enterIcon;
  final bool talkIcon;
  final bool restIcon;
  final String title;

  final VoidCallback? onMoveTo;
  final VoidCallback? onCheck;
  final VoidCallback? onEnter;
  final VoidCallback? onTalk;
  final VoidCallback? onRest;

  const WorldMapPopup({
    super.key,
    required this.left,
    required this.top,
    this.onPanelTapped,
    this.moveToIcon = false,
    this.onMoveTo,
    this.checkIcon = false,
    this.onCheck,
    this.enterIcon = false,
    this.onEnter,
    this.talkIcon = false,
    this.onTalk,
    this.restIcon = false,
    this.onRest,
    this.title = '',
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
                child: Align(
                  alignment: Alignment.center,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              if (moveToIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: InkImageButton(
                      width: _kPopupButtonSize,
                      height: _kPopupButtonSize,
                      tooltip: engine.locale['moveTo'],
                      child: const Image(
                        image: AssetImage('assets/images/icon/move_to.png'),
                      ),
                      onPressed: () {
                        if (onMoveTo != null) {
                          onMoveTo!();
                        }
                      },
                    ),
                  ),
                ),
              if (checkIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: InkImageButton(
                      width: _kPopupButtonSize,
                      height: _kPopupButtonSize,
                      tooltip: engine.locale['check'],
                      child: const Image(
                        image: AssetImage('assets/images/icon/check.png'),
                      ),
                      onPressed: () {
                        if (onCheck != null) {
                          onCheck!();
                        }
                      },
                    ),
                  ),
                ),
              if (enterIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: InkImageButton(
                      width: _kPopupButtonSize,
                      height: _kPopupButtonSize,
                      tooltip: engine.locale['enter'],
                      child: const Image(
                        image: AssetImage('assets/images/icon/enter.png'),
                      ),
                      onPressed: () {
                        if (onEnter != null) {
                          onEnter!();
                        }
                      },
                    ),
                  ),
                ),
              if (talkIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: InkImageButton(
                      width: _kPopupButtonSize,
                      height: _kPopupButtonSize,
                      tooltip: engine.locale['talk'],
                      child: const Image(
                        image: AssetImage('assets/images/icon/talk.png'),
                      ),
                      onPressed: () {
                        if (onTalk != null) {
                          onTalk!();
                        }
                      },
                    ),
                  ),
                ),
              if (restIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: InkImageButton(
                      width: _kPopupButtonSize,
                      height: _kPopupButtonSize,
                      tooltip: engine.locale['rest'],
                      child: const Image(
                        image: AssetImage('assets/images/icon/rest.png'),
                      ),
                      onPressed: () {
                        if (onRest != null) {
                          onRest!();
                        }
                      },
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
