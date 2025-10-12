import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/richtext.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../game/ui.dart';
import '../../engine.dart';
import '../../state/new_prompt.dart';

class NewJournal extends StatelessWidget {
  const NewJournal({
    super.key,
    required this.journal,
    this.completer,
  });

  final dynamic journal;
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
                      '${engine.locale('journalUpdate')}: ${journal['title']}'),
                  if (journal['image'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Image(
                        image: AssetImage('assets/images/${journal['image']}'),
                      ),
                    ),
                  ...(journal['sequence'] as List).map((index) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Label(
                        journal['stages'][index],
                        textAlign: TextAlign.left,
                        textStyle: journal['stage'] > index
                            ? TextStyles.bodyMedium.copyWith(color: Colors.grey)
                            : TextStyles.bodyMedium
                                .copyWith(color: Colors.yellow),
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.only(top: 50.0),
                    child: fluent.FilledButton(
                      onPressed: () {
                        completer?.complete();
                        context.read<NewJournalState>().update();
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
