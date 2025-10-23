import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/empty_placeholder.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../state/game_save.dart';
import '../../engine.dart';
import '../../data/common.dart';
import '../../ui.dart';
import '../../widgets/ui/responsive_view.dart';

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
      width: 1000.0,
      height: 600.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('load')),
        ),
        body: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(5.0),
                child: saves.values.isNotEmpty
                    ? SingleChildScrollView(
                        child: ListView(
                          shrinkWrap: true,
                          children: saves.values
                              .map(
                                (info) => Card(
                                  color: GameUI.backgroundColor,
                                  shape: GameUI.roundedRectangleBorder,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Row(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              right: 10.0),
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
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5),
                                              child: fluent.Button(
                                                onPressed: () {
                                                  Navigator.of(context)
                                                      .pop(info);
                                                },
                                                child:
                                                    Text(engine.locale('load')),
                                              ),
                                            ),
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 5),
                                              child: fluent.Button(
                                                onPressed: () {
                                                  if (deleteButtonDisabled) {
                                                    return;
                                                  }
                                                  setState(() {
                                                    deleteButtonDisabled = true;
                                                  });
                                                  // TODO: 显示一个进度条动画，避免多次点击，或者将按钮改为无效

                                                  final file =
                                                      File(info.savePath);
                                                  if (file.existsSync()) {
                                                    file.deleteSync();
                                                  }
                                                  final file2 = File(
                                                      '${info.savePath}$kUniverseSaveFilePostfix');
                                                  if (file2.existsSync()) {
                                                    file2.deleteSync();
                                                  }
                                                  final file3 = File(
                                                      '${info.savePath}$kHistorySaveFilePostfix');
                                                  if (file3.existsSync()) {
                                                    file3.deleteSync();
                                                  }
                                                  final file4 = File(
                                                      '${info.savePath}$kScenesSaveFilePostfix');
                                                  if (file4.existsSync()) {
                                                    file4.deleteSync();
                                                  }
                                                  setState(() {
                                                    saves.removeWhere(
                                                        (id, save) =>
                                                            save == info);
                                                    deleteButtonDisabled =
                                                        false;
                                                    if (saves.isEmpty) {
                                                      Navigator.of(context)
                                                          .pop();
                                                    }
                                                  });
                                                },
                                                child: Text(
                                                    engine.locale('delete')),
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
                      )
                    : EmptyPlaceholder(
                        engine.locale('noSavesFound'),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: fluent.Button(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(engine.locale('close')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
