import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';
import 'package:samsara/event.dart';

import '../../../event/ui.dart';
import 'package:samsara/ui/flutter/close_button.dart';
import '../../../global.dart';
import 'package:samsara/ui/flutter/responsive_window.dart';
import 'quest_card.dart';

enum BuildViewType {
  player,
  npc,
}

class QuestsView extends StatefulWidget {
  static Future<bool?> show({
    required BuildContext context,
    required HTStruct siteData,
    double priceFactor = 1.0,
  }) {
    return showDialog<bool>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (context) {
        return QuestsView(
          key: UniqueKey(),
          siteData: siteData,
        );
      },
    );
  }

  const QuestsView({
    super.key,
    required this.siteData,
  });

  final HTStruct siteData;

  @override
  State<QuestsView> createState() => _QuestsViewState();
}

class _QuestsViewState extends State<QuestsView> {
  HTStruct? _questsData;

  @override
  void initState() {
    super.initState();

    engine.addEventListener(
      UIEvents.needRebuildUI,
      EventHandler(
        ownerKey: widget.key!,
        handle: (GameEvent event) {
          if (!mounted) return;
          setState(() {
            _questsData = widget.siteData['quests'];
            if (_questsData!.isEmpty) {
              Navigator.of(context).pop();
            }
          });
        },
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _questsData = widget.siteData['quests'];

    final List<Widget> questCards = _questsData!.values.map((questData) {
      return QuestCard(
        siteData: widget.siteData,
        questData: questData,
      );
    }).toList();

    return ResponsiveWindow(
      size: const Size(720.0, 420.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale['quest']),
          actions: const [CloseButton2()],
        ),
        body: Container(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Wrap(
                    spacing: 8.0, // gap between adjacent chips
                    runSpacing: 4.0, // gap between lines
                    children: questCards,
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
