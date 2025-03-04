import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

// import '../../../event/ui.dart';
import '../../engine.dart';
import '../../ui.dart';
import 'package:samsara/ui/label.dart';

class QuestCard extends StatelessWidget {
  const QuestCard({
    super.key,
    required this.siteData,
    required this.questData,
  });

  final HTStruct siteData, questData;

  @override
  Widget build(BuildContext context) {
    final heroData = engine.hetu.fetch('hero');

    return Container(
      width: 240,
      height: 150,
      decoration: BoxDecoration(
        borderRadius: GameUI.borderRadius,
        border: Border.all(color: GameUI.foregroundColor),
      ),
      child: ClipRRect(
        borderRadius: GameUI.borderRadius,
        child: Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      engine.locale(questData['category']),
                      style: const TextStyle(fontSize: 16.0),
                    ),
                    const Divider(),
                    Text(
                      questData['description'],
                      style: const TextStyle(fontSize: 12.0),
                    ),
                  ],
                ),
              ),
              Align(
                alignment: AlignmentDirectional.bottomEnd,
                child: ElevatedButton(
                  onPressed: () {
                    engine.hetu.invoke(
                      'characterAcceptQuest',
                      positionalArgs: [
                        heroData,
                        siteData,
                        questData,
                      ],
                    );
                    // engine.emit(const UIEvent.needRebuildUI());
                  },
                  child: Label(
                    padding: const EdgeInsets.all(0.0),
                    engine.locale('takeQuest'),
                    width: 30.0,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
