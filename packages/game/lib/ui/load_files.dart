import 'package:flutter/material.dart';

import 'shared/ink_image_button.dart';

class LoadGame extends StatelessWidget {
  static Future<void> show(
    BuildContext context, {
    List<String> list = const [],
    required void Function(String path) onLoad,
  }) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return Material(
          type: MaterialType.transparency,
          child: Align(
            alignment: Alignment.center,
            child: LoadGame(
              list: list,
              onLoad: onLoad,
            ),
          ),
        );
      },
    );
  }

  final List<String> list;

  final void Function(String path) onLoad;

  const LoadGame({Key? key, this.list = const [], required this.onLoad})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints.tight(const Size(200, 240)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(
          width: 2,
          color: Colors.lightBlue.withOpacity(0.5),
        ),
      ),
      padding: const EdgeInsets.all(10.0),
      child: SingleChildScrollView(
        child: ListView(
          shrinkWrap: true,
          children: list
              .map((element) => InkImageButton(
                    width: MediaQuery.of(context).size.width,
                    borderRadius: 5,
                    onPressed: () {
                      onLoad(element);
                    },
                    child: Text(
                      element,
                      softWrap: false,
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}
