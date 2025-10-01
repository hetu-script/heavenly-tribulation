import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/richtext.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../game/ui.dart';
import '../../engine.dart';
import '../../state/new_prompt.dart';

class NewQuest extends StatelessWidget {
  const NewQuest({
    super.key,
    required this.questData,
    this.completer,
  });

  final dynamic questData;
  final Completer? completer;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          ModalBarrier(color: GameUI.backgroundColor2),
          Align(
            alignment: Alignment.center,
            child: Container(
              width: 500.0,
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: GameUI.backgroundColor2,
              ),
              child: ListView(
                shrinkWrap: true,
                children: [
                  Label(
                      '${engine.locale('questUpdate')}: ${questData['title']}'),
                  if (questData['image'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Image(
                        image:
                            AssetImage('assets/images/${questData['image']}'),
                      ),
                    ),
                  ...(questData['sequence'] as List).map((index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Label(
                        engine.locale(
                          'quest_${questData['id']}_stage_$index',
                          interpolations: questData['interpolations'],
                        ),
                        textAlign: TextAlign.left,
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 10.0),
                    child: fluent.FilledButton(
                      onPressed: () {
                        completer?.complete();
                        context.read<NewQuestState>().update();
                      },
                      child: Text(
                        engine.locale('confirm'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
