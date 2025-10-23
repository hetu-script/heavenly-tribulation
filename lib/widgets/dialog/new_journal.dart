import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/richtext.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../ui.dart';
import '../../engine.dart';
import '../../state/new_prompt.dart';
import '../ui/responsive_view.dart';

class NewJournal extends StatelessWidget {
  const NewJournal({
    super.key,
    required this.journal,
    this.selections,
    this.completer,
  });

  final dynamic journal;
  final Map<String, String>? selections;
  final Completer<String?>? completer;

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      barrierColor: null,
      width: 500.0,
      child: Padding(
        padding: const EdgeInsets.all(10.0),
        child: ListView(
          shrinkWrap: true,
          children: [
            Text(
              journal['title'],
              textAlign: TextAlign.center,
              style: TextStyles.titleSmall,
            ),
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
                      : TextStyles.bodyMedium.copyWith(color: Colors.yellow),
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: SizedBox.shrink(),
            ),
            if (selections != null)
              Padding(
                padding: const EdgeInsets.only(
                    top: 10.0, left: 50.0, right: 50.0, bottom: 10.0),
                child: Column(
                  children: selections!.entries.map(
                    (entry) {
                      return Container(
                        padding: const EdgeInsets.all(10.0),
                        child: fluent.Button(
                          onPressed: () {
                            completer?.complete(entry.key);
                            context.read<JournalPromptState>().update();
                          },
                          child: Text(
                            engine.locale(entry.value),
                          ),
                        ),
                      );
                    },
                  ).toList(),
                ),
              )
            else
              Padding(
                padding:
                    const EdgeInsets.only(top: 10.0, left: 50.0, right: 50.0),
                child: fluent.Button(
                  onPressed: () {
                    completer?.complete(null);
                    context.read<JournalPromptState>().update();
                    engine.hetu.invoke(
                      'setActiveJournal',
                      namespace: 'Player',
                      positionalArgs: [journal],
                    );
                  },
                  child: Text(
                    engine.locale('confirm'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
