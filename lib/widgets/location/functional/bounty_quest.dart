import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';
import 'package:samsara/richtext.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../../game/ui.dart';
import '../../../game/data.dart';
import '../../../engine.dart';
import '../../ui/close_button2.dart';

class BountyQuestDetail extends StatelessWidget {
  const BountyQuestDetail({
    super.key,
    required this.bounty,
  });

  final dynamic bounty;

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 380.0,
      height: 360.0,
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
                          GameData.getBountyDetailDescription(bounty)),
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

class BountyQuestView extends StatefulWidget {
  final List<dynamic> data;

  const BountyQuestView({
    super.key,
    required this.data,
  });

  @override
  State<BountyQuestView> createState() => _BountyQuestViewState();
}

class _BountyQuestViewState extends State<BountyQuestView> {
  @override
  Widget build(BuildContext context) {
    final bounties = widget.data as List<dynamic>? ?? [];

    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 800.0,
      height: 500.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('bountyQuest')),
          actions: [
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
              children: bounties.map((bounty) {
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
                              FlutterCustomMemoryImageCursor(key: 'click'),
                          onTap: () async {
                            final accepted = await showDialog(
                              context: context,
                              builder: (context) {
                                return BountyQuestDetail(bounty: bounty);
                              },
                            );
                            if (accepted == true) {
                              bounties.remove(bounty);

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
