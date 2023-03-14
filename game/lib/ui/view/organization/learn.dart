import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../../global.dart';
import 'package:samsara/ui/flutter/responsive_window.dart';
import 'package:samsara/ui/flutter/close_button.dart';
import '../grid/entity_grid.dart';

// const _kGridPerLine = 6;
// const _kMinSlotCount = 30;
const _kSkillRankStart = -1;

class OrganizationLearningPanel extends StatelessWidget {
  final int characterRank;
  final HTStruct libraryData;

  const OrganizationLearningPanel({
    super.key,
    required this.characterRank,
    required this.libraryData,
  });

  @override
  Widget build(BuildContext context) {
    final grids = <Widget>[];
    final skillRecords = [];
    for (var i = _kSkillRankStart; i <= characterRank; ++i) {
      skillRecords.addAll(libraryData[i]);
    }
    // var rank = _kSkillRankStart;
    for (final skillRecord in skillRecords) {
      grids.add(
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: EntityGrid(
            entityData: skillRecord['skill'],
            style: GridStyle.card,
          ),
        ),
      );
    }

    return ResponsiveWindow(
      alignment: AlignmentDirectional.topStart,
      size: const Size(400.0, 400.0),
      child: Scaffold(
        backgroundColor: kBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale['selectSkillToLearn']),
          actions: const [CloseButton2()],
        ),
        body: Container(
          color: Colors.red,
          width: 250,
          height: 250,
          child: ListView(
            shrinkWrap: true,
            children: grids,
          ),
        ),
      ),
    );
  }
}
