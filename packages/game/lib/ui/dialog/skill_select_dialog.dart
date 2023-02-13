import 'package:flutter/material.dart';
import 'package:hetu_script/values.dart';

import '../../global.dart';
import 'package:samsara/ui/shared/responsive_window.dart';
import 'package:samsara/ui/shared/close_button.dart';
import '../view/grid/entity_grid.dart';
import '../view/grid/entity_info.dart';

class SkillSelectDialog extends StatelessWidget {
  static Future<dynamic> show({
    required BuildContext context,
    required String title,
    required HTStruct skillsData,
    bool showCloseButton = true,
  }) async {
    return await showDialog<dynamic>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return SkillSelectDialog(
          title: title,
          skillsData: skillsData,
          showCloseButton: showCloseButton,
        );
      },
    );
  }

  final String title;
  final HTStruct skillsData;
  final bool showCloseButton;

  const SkillSelectDialog({
    super.key,
    required this.title,
    required this.skillsData,
    this.showCloseButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final grids = <Widget>[];
    for (final data in skillsData.values) {
      grids.add(
        Padding(
          padding: const EdgeInsets.all(5.0),
          child: EntityGrid(
            entityData: data,
            hasBorder: true,
            style: GridStyle.card,
            onItemTapped: (data, offset) => showDialog(
              context: context,
              barrierColor: Colors.transparent,
              builder: (context) {
                return EntityInfo(
                  entityData: data,
                  left: offset.dx,
                );
              },
            ),
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(data);
              },
              child: Text(engine.locale['select']),
            ),
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
          title: Text(engine.locale['selectSkill']),
          actions: [if (showCloseButton) const ButtonClose()],
        ),
        body: SingleChildScrollView(
          child: ListView(
            shrinkWrap: true,
            children: grids,
          ),
        ),
      ),
    );
  }
}
