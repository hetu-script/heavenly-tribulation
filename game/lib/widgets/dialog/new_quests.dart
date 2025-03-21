import 'package:flutter/material.dart';
import 'package:samsara/ui/label.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/responsive_view.dart';

import '../../game/ui.dart';
import '../../engine.dart';
import '../../state/hoverinfo.dart';
import '../../state/new_prompt.dart';

class NewQuests extends StatelessWidget {
  const NewQuests({
    super.key,
    required this.questsData,
  });

  final Iterable questsData;

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 400.0,
      height: 300.0,
      child: Scaffold(
        backgroundColor: GameUI.backgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('newQuests')),
        ),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ScrollConfiguration(
                behavior: MaterialScrollBehavior(),
                child: SingleChildScrollView(
                  child: ListView(
                    shrinkWrap: true,
                    children: questsData.map((data) {
                      return Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: GameUI.foregroundColor,
                            width: 1.0,
                          ),
                        ),
                        margin: const EdgeInsets.all(5.0),
                        child: TextButton(
                          onPressed: () {},
                          child: Label(
                            data['name'],
                            width: 400.0,
                            textStyle: GameUI.textTheme.bodyMedium,
                            onMouseEnter: (rect) {
                              final questDescription =
                                  data['stages'][0]['description'];
                              context
                                  .read<HoverInfoContentState>()
                                  .set(questDescription, rect);
                            },
                            onMouseExit: () {
                              context.read<HoverInfoContentState>().hide();
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  context.read<NewQuestsState>().update();
                },
                child: Text(
                  engine.locale('confirm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
