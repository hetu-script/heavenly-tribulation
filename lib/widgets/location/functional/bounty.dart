import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:flutter_custom_cursor/flutter_custom_cursor.dart';
import 'package:samsara/richtext.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../../game/ui.dart';
import '../../../game/common.dart';
import '../../../game/data.dart';
import '../../../engine.dart';
import '../../ui/close_button2.dart';

String _buildBriefDescription(dynamic bounty) {
  final desc = StringBuffer();

  final kind = bounty['kind'];
  final int difficulty = bounty['difficulty'] ?? 0;
  final String difficultyLable = kDifficultyLabels[difficulty]!;
  final timeLimitDays = bounty['timeLimitDays'];
  desc.writeln(engine.locale('bounty_$kind'));
  desc.writeln(
      '${engine.locale('difficulty')}: <rank$difficulty>${engine.locale(difficultyLable)}</>');
  desc.writeln(
      '${engine.locale('timeLimit')}: <yellow>$timeLimitDays ${engine.locale('ageDay')}</>');

  return desc.toString();
}

String _buildBudget(dynamic budget) {
  final desc = StringBuffer();
  final kind = budget['kind'];
  final amount = budget['amount'];
  desc.writeln(kSeparateLine);
  desc.writeln(
      '<lightGreen>${engine.locale('budget')}: $amount ${engine.locale(kind)}</>');
  return desc.toString();
}

String _buildReward(List reward) {
  final desc = StringBuffer();
  desc.write('${engine.locale('reward')}: ');
  for (final itemInfo in reward) {
    if (itemInfo['type'] == 'material') {
      final kind = itemInfo['kind'];
      final amount = itemInfo['amount'];
      desc.writeln('$amount ${engine.locale(kind)}');
    }
  }
  return desc.toString();
}

String _buildDetailDescription(dynamic bounty) {
  final desc = StringBuffer();

  final brief = _buildBriefDescription(bounty);
  desc.write(brief);
  desc.writeln(kSeparateLine);
  desc.writeln('${engine.locale('quest_content')}:');

  final kind = bounty['kind'];
  assert(kQuestKinds.contains(kind), 'Unknown bounty kind: $kind');
  switch (kind) {
    case 'purchase_material':
      final amount = bounty['amount'];
      final materialKind = bounty['material'];
      final reportSiteId = bounty['reportSiteId'];
      final reportSite = GameData.getLocation(reportSiteId);
      final reportLocationId = bounty['reportLocationId'];
      final reportLocation = GameData.getLocation(reportLocationId);
      desc.writeln(engine
          .locale('bounty_purchase_material_description', interpolations: [
        amount,
        engine.locale(materialKind),
        reportLocation['name'],
        reportSite['name'],
      ]));
      final budget = _buildBudget(bounty['budget']);
      desc.writeln(budget);
    case 'purchase_item':
      final itemRequired = bounty['itemRequired'];
      final category = itemRequired['category'];
      String itemDesc;
      if (kEquipmentCategoryKinds.keys.contains(category)) {
        itemDesc =
            '${engine.locale(itemRequired['rarity'])}${engine.locale(itemRequired['kind'])}';
      } else if (category == 'potion') {
        itemDesc =
            '${engine.locale(itemRequired['rarity'])}${engine.locale(category)}';
      } else if (category == 'cardpack') {
        itemDesc =
            '${engine.locale('cultivationRank_${itemRequired['rank']}}')}${engine.locale('rank2"')}${engine.locale(category)}';
      } else {
        throw ('Unknown itemRequired category: $category');
      }
      final reportSiteId = bounty['reportSiteId'];
      final reportSite = GameData.getLocation(reportSiteId);
      final reportLocationId = bounty['reportLocationId'];
      final reportLocation = GameData.getLocation(reportLocationId);
      desc.writeln(
          engine.locale('bounty_purchase_item_description', interpolations: [
        itemDesc,
        reportLocation['name'],
        reportSite['name'],
      ]));
      final budget = _buildBudget(bounty['budget']);
      desc.writeln(budget);
    case 'deliver_material':
      final amount = bounty['amount'];
      final materialKind = bounty['material'];
      final reportSiteId = bounty['reportSiteId'];
      final reportSite = GameData.getLocation(reportSiteId);
      final reportLocationId = bounty['reportLocationId'];
      final reportLocation = GameData.getLocation(reportLocationId);
      desc.writeln(
          engine.locale('bounty_deliver_material_description', interpolations: [
        amount,
        engine.locale(materialKind),
        reportSite['name'],
        reportLocation?['name'] ?? engine.locale('worldMap'),
      ]));
      final reward = _buildReward(bounty['reward']);
      desc.writeln(reward);
    case 'deliver_item':
      final itemName = bounty['item']['name'];
      final reportSiteId = bounty['reportSiteId'];
      final reportSite = GameData.getLocation(reportSiteId);
      final reportLocationId = bounty['reportLocationId'];
      final reportLocation = GameData.getLocation(reportLocationId);
      desc.writeln();
      desc.writeln(
          engine.locale('bounty_deliver_item_description', interpolations: [
        itemName,
        reportSite['name'],
        reportLocation?['name'] ?? engine.locale('worldMap'),
      ]));
      final reward = _buildReward(bounty['reward']);
      desc.writeln(reward);
    case 'escort':
      final escorteeId = bounty['escorteeId'];
      final escortee = GameData.getCharacter(escorteeId);
      final reportSiteId = bounty['reportSiteId'];
      final reportSite = GameData.getLocation(reportSiteId);
      final reportLocationId = bounty['reportLocationId'];
      final reportLocation = GameData.getLocation(reportLocationId);
      desc.writeln();
      desc.writeln(engine.locale('bounty_escort_description', interpolations: [
        escortee['name'],
        reportSite['name'],
        reportLocation?['name'] ?? engine.locale('worldMap'),
      ]));
      final reward = _buildReward(bounty['reward']);
      desc.writeln(reward);
    case 'discover_location':
      final targetCityId = bounty['targetCityId'];
      final targetCity = GameData.getLocation(targetCityId);
      final organizationId = bounty['organizationId'];
      final organization = GameData.getOrganization(organizationId);
      desc.writeln(engine
          .locale('bounty_discover_location_description', interpolations: [
        organization['name'],
        targetCity['name'],
      ]));
      final reward = _buildReward(bounty['reward']);
      desc.writeln(reward);
  }

  return desc.toString();
}

class BountyDetail extends StatelessWidget {
  final dynamic bounty;

  const BountyDetail({super.key, required this.bounty});

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
          title: Text(
            engine.locale('editIdAndImage'),
          ),
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
                      children:
                          buildFlutterRichText(_buildDetailDescription(bounty)),
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

class BountyView extends StatefulWidget {
  final List<dynamic> data;

  const BountyView({
    super.key,
    required this.data,
  });

  @override
  State<BountyView> createState() => _BountyViewState();
}

class _BountyViewState extends State<BountyView> {
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
          title: Text(engine.locale('bounty')),
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
                                return BountyDetail(bounty: bounty);
                              },
                            );
                            if (accepted == true) {
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
                                      _buildBriefDescription(bounty)),
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
