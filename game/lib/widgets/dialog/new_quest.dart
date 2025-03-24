import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:samsara/richtext.dart';

import '../../game/ui.dart';
import '../../engine.dart';
import '../../state/new_prompt.dart';

class NewQuest extends StatelessWidget {
  const NewQuest({
    super.key,
    required this.questData,
  });

  final dynamic questData;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 500.0,
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: GameUI.backgroundColor,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            Label('${engine.locale('questUpdate')}: ${questData['name']}'),
            if (questData['image'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Image(
                  image: AssetImage('assets/images/${questData['image']}'),
                ),
              ),
            ...(questData['progress'] as List).map((index) {
              return Padding(
                padding: const EdgeInsets.only(top: 10.0),
                child: Label(
                  engine.locale('${questData['id']}_stage$index'),
                  textAlign: TextAlign.left,
                ),
              );
            }),
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: ElevatedButton(
                onPressed: () {
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
    );
  }
}
