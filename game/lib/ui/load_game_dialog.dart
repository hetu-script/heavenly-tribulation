import 'dart:io';

import 'package:flutter/material.dart';
import 'package:samsara/flutter_ui/responsive_window.dart';

import '../global.dart';

class SaveInfo {
  final String worldId;
  final String timestamp;
  final String savepath1;
  final String savepath2;

  SaveInfo({
    required this.worldId,
    required this.timestamp,
    required this.savepath1,
    required this.savepath2,
  });
}

class LoadGameDialog extends StatefulWidget {
  static Future<SaveInfo?> show(BuildContext context,
      {List<SaveInfo> list = const []}) {
    return showDialog<SaveInfo>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return LoadGameDialog(list: list);
      },
    );
  }

  final List<SaveInfo> list;

  const LoadGameDialog({super.key, this.list = const []});

  @override
  State<LoadGameDialog> createState() => _LoadGameDialogState();
}

class _LoadGameDialogState extends State<LoadGameDialog> {
  @override
  Widget build(BuildContext context) {
    final layout = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(engine.locale['loadGame']),
        actions: const [CloseButton()],
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(5.0),
              child: SingleChildScrollView(
                child: ListView(
                  shrinkWrap: true,
                  children: widget.list
                      .map(
                        (info) => Card(
                          color: kBackgroundColor,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(
                              color: kForegroundColor,
                              width: 1,
                            ),
                            borderRadius: kBorderRadius,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        info.worldId,
                                      ),
                                      Text(
                                        info.timestamp,
                                        softWrap: false,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(context).pop(info);
                                        },
                                        child: Text(engine.locale['load']),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 5),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          final file = File(info.savepath1);
                                          file.delete();
                                          final file2 = File(info.savepath2);
                                          file2.delete();
                                          setState(() {
                                            widget.list.removeWhere(
                                                (element) => element == info);
                                            if (widget.list.isEmpty) {
                                              Navigator.of(context).pop();
                                            }
                                          });
                                        },
                                        child: Text(engine.locale['delete']),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(engine.locale['cancel']),
            ),
          ),
        ],
      ),
    );

    return ResponsiveWindow(
      alignment: AlignmentDirectional.center,
      child: layout,
    );
  }
}
