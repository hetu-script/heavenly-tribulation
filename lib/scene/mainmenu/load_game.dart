import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../state/game_save.dart';
import '../../engine.dart';
import '../../common.dart';
import '../../game/ui.dart';

class LoadGameDialog extends StatefulWidget {
  const LoadGameDialog({super.key});

  @override
  State<LoadGameDialog> createState() => _LoadGameDialogState();
}

class _LoadGameDialogState extends State<LoadGameDialog> {
  bool deleteButtonDisabled = false;

  @override
  Widget build(BuildContext context) {
    final saves = context.watch<GameSavesState>().saves;

    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('load')),
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
                    children: saves.values
                        .map(
                          (info) => Card(
                            color: GameUI.backgroundColor2,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(
                                color: GameUI.foregroundColor,
                                width: 1,
                              ),
                              borderRadius: GameUI.borderRadius,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(right: 10.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(engine.locale('saveName')),
                                        Text(engine.locale('world')),
                                        Text(
                                          engine.locale('timestamp'),
                                          softWrap: false,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          info.saveName,
                                        ),
                                        Text(
                                          info.currentWorldId,
                                        ),
                                        Text(
                                          info.timestamp!,
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
                                        child: fluent.FilledButton(
                                          onPressed: () {
                                            Navigator.of(context).pop(info);
                                          },
                                          child: Text(engine.locale('load')),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 5),
                                        child: fluent.FilledButton(
                                          onPressed: () {
                                            if (deleteButtonDisabled) return;
                                            setState(() {
                                              deleteButtonDisabled = true;
                                            });
                                            // TODO: 显示一个进度条动画，避免多次点击，或者将按钮改为无效

                                            final file = File(info.savePath);
                                            file.delete();
                                            final file2 = File(
                                                '${info.savePath}$kUniverseSaveFilePostfix');
                                            file2.delete();
                                            final file3 = File(
                                                '${info.savePath}$kHistorySaveFilePostfix');
                                            file3.delete();
                                            setState(() {
                                              saves.removeWhere(
                                                  (id, save) => save == info);
                                              if (saves.isEmpty) {
                                                Navigator.of(context).pop();
                                              }
                                            });
                                          },
                                          child: Text(engine.locale('delete')),
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
              child: fluent.FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(engine.locale('cancel')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
