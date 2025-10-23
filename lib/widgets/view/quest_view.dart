import 'package:flutter/material.dart';
import 'package:samsara/richtext.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../ui.dart';
import '../../data/game.dart';
import '../../engine.dart';
import '../ui/close_button2.dart';
import '../ui/responsive_view.dart';

class QuestDetail extends StatelessWidget {
  const QuestDetail({
    super.key,
    required this.quest,
  });

  final dynamic quest;

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 380.0,
      height: 360.0,
      barrierDismissible: true,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('detail')),
          actions: const [CloseButton2()],
        ),
        body: Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 580.0,
                height: 250.0,
                child: SingleChildScrollView(
                  child: RichText(
                    textAlign: TextAlign.left,
                    text: TextSpan(
                      children: buildFlutterRichText(
                          GameData.getQuestDetailDescription(quest)),
                      style: TextStyle(
                        fontFamily: GameUI.fontFamily,
                        fontSize: 16.0,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 5.0),
                    child: fluent.FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(false);
                      },
                      child: Text(engine.locale('close')),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 5.0),
                    child: fluent.FilledButton(
                      onPressed: () {
                        Navigator.of(context).pop(true);
                      },
                      child: Text(engine.locale('accept')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuestView extends StatefulWidget {
  const QuestView({
    super.key,
    required this.quests,
    this.showCloseButton = true,
  });

  final List<dynamic> quests;
  final bool showCloseButton;

  @override
  State<QuestView> createState() => _QuestViewState();
}

class _QuestViewState extends State<QuestView> {
  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 800.0,
      height: 500.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('bountyQuest')),
          actions: [
            if (widget.showCloseButton)
              CloseButton2(
                onPressed: () {
                  Navigator.of(context).pop();
                },
              )
          ],
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: widget.quests.map((bounty) {
                return Card(
                  child: Ink(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white70),
                        borderRadius: GameUI.borderRadius,
                      ),
                      width: 160,
                      height: 90,
                      child: Material(
                        type: MaterialType.transparency,
                        child: InkWell(
                          mouseCursor:
                              GameUI.cursor.resolve({WidgetState.hovered}),
                          onTap: () async {
                            final accepted = await showDialog(
                              context: context,
                              builder: (context) {
                                return QuestDetail(quest: bounty);
                              },
                            );
                            if (accepted == true) {
                              widget.quests.remove(bounty);

                              Navigator.of(context).pop(bounty);
                            }
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: RichText(
                                textAlign: TextAlign.left,
                                text: TextSpan(
                                  children: buildFlutterRichText(
                                      GameData.getQuestBriefDescription(
                                          bounty)),
                                  style: TextStyle(
                                    fontFamily: GameUI.fontFamily,
                                    fontSize: 16.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
