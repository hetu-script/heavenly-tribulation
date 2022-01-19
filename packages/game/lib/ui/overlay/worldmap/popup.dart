import 'package:flutter/material.dart';

import '../../../engine/engine.dart';
import '../../shared/ink_image_button.dart';

class WorldMapPopup extends StatelessWidget {
  static const defaultSize = 160.0;

  final double left, top, width = defaultSize, height = defaultSize;

  final void Function()? onPanelTapped;

  final bool moveToIcon;
  final bool checkIcon;
  final bool enterIcon;
  final bool talkIcon;
  final bool restIcon;
  final String title;

  final void Function()? onMoveToIconTapped;
  final void Function()? onCheckIconTapped;
  final void Function()? onEnterIconTapped;
  final void Function()? onTalkIconTapped;
  final void Function()? onRestIconTapped;

  const WorldMapPopup({
    Key? key,
    required this.left,
    required this.top,
    this.onPanelTapped,
    this.moveToIcon = false,
    this.onMoveToIconTapped,
    this.checkIcon = false,
    this.onCheckIconTapped,
    this.enterIcon = false,
    this.onEnterIconTapped,
    this.talkIcon = false,
    this.onTalkIconTapped,
    this.restIcon = false,
    this.onRestIconTapped,
    this.title = '',
  }) : super(key: key);

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
            children: <Widget>[
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: Colors.blue,
                    width: 2,
                  ),
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
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              if (moveToIcon)
                Positioned.fill(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: InkImageButton(
                      tooltip: engine.locale['moveTo'],
                      child: const Image(
                        image: AssetImage('assets/images/icon/move_to.png'),
                      ),
                      onPressed: () {
                        if (onMoveToIconTapped != null) {
                          onMoveToIconTapped!();
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
                      tooltip: engine.locale['check'],
                      child: const Image(
                        image: AssetImage('assets/images/icon/check.png'),
                      ),
                      onPressed: () {
                        if (onCheckIconTapped != null) {
                          onCheckIconTapped!();
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
                      tooltip: engine.locale['enter'],
                      child: const Image(
                        image: AssetImage('assets/images/icon/enter.png'),
                      ),
                      onPressed: () {
                        if (onEnterIconTapped != null) {
                          onEnterIconTapped!();
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
                      tooltip: engine.locale['talk'],
                      child: const Image(
                        image: AssetImage('assets/images/icon/talk.png'),
                      ),
                      onPressed: () {
                        if (onTalkIconTapped != null) {
                          onTalkIconTapped!();
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
                      tooltip: engine.locale['rest'],
                      child: const Image(
                        image: AssetImage('assets/images/icon/rest.png'),
                      ),
                      onPressed: () {
                        if (onRestIconTapped != null) {
                          onRestIconTapped!();
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
