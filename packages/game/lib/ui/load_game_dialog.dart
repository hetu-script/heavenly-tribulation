import 'dart:io';

import 'package:flutter/material.dart';

import '../global.dart';
import 'shared/responsive_route.dart';

class SaveInfo {
  final String timestamp;
  final String path;

  SaveInfo({
    required this.timestamp,
    required this.path,
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

  const LoadGameDialog({Key? key, this.list = const []}) : super(key: key);

  @override
  _LoadGameDialogState createState() => _LoadGameDialogState();
}

class _LoadGameDialogState extends State<LoadGameDialog> {
  @override
  Widget build(BuildContext context) {
    final layout = Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: Text(engine.locale['loadGame']),
        actions: const [CloseButton()],
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(5.0),
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
                              child: Text(
                                info.timestamp,
                                softWrap: false,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Column(
                              children: [
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      Navigator.of(context).pop(info);
                                    },
                                    child: Text(engine.locale['load']),
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 5),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      final file = File(info.path);
                                      file.delete();
                                      final file2 = File(info.path + '2');
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
          const Spacer(),
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

    return ResponsiveRoute(
      alignment: AlignmentDirectional.center,
      child: layout,
    );
  }
}
