import 'dart:io';

import 'package:flutter/material.dart';

import '../engine/engine.dart';

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
        return Material(
          type: MaterialType.transparency,
          child: Align(
            alignment: Alignment.center,
            child: LoadGameDialog(list: list),
          ),
        );
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
    return Container(
      width: 300,
      height: 400,
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
        borderRadius: BorderRadius.circular(5.0),
        border: Border.all(
          width: 2,
          color: Colors.lightBlue,
        ),
      ),
      padding: const EdgeInsets.all(10.0),
      child: Column(
        children: <Widget>[
          SingleChildScrollView(
            child: ListView(
              shrinkWrap: true,
              children: widget.list
                  .map(
                    (info) => Card(
                      color: Theme.of(context).backgroundColor,
                      shape: RoundedRectangleBorder(
                          side: const BorderSide(
                              color: Colors.lightBlue, width: 2),
                          borderRadius: BorderRadius.circular(8.0)),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          children: <Widget>[
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
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(engine.locale['cancel']),
          )
        ],
      ),
    );
  }
}
