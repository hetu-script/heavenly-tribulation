import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;
import 'package:samsara/widgets/ui/label.dart';

import '../../widgets/ui/avatar.dart';
import '../../ui.dart';
import '../../logic/logic.dart';
import '../../global.dart';
import '../../state/meeting.dart';

// 预设的头像位置
const _avatarPositions = [
  // 掌门/主位
  Alignment(0.0, -0.6),
  // 中左
  Alignment(-0.25, 0),
  // 中右
  Alignment(0.25, 0),
  // 正中
  Alignment(0, 0),
  // 下中
  Alignment(0, 0.45),
  // 下左
  Alignment(-0.25, 0.45),
  // 下右
  Alignment(0.25, 0.45),
];

/// 用于显示门派会议等场景的UI
class Meeting extends StatelessWidget {
  const Meeting({
    super.key,
    required this.people,
    this.showExitButton = false,
  });

  final List people;
  final bool showExitButton;

  @override
  Widget build(BuildContext context) {
    final peopleWidgets = <Widget>[];
    for (int i = 0; i < people.length; i++) {
      // 超出预设位置则不显示
      if (i >= _avatarPositions.length) break;

      final character = people[i];
      final position = _avatarPositions[i];

      peopleWidgets.add(
        Align(
          alignment: position,
          child: Avatar(
            characterData: character,
            size: const Size(120, 120),
            // showBorderImage: true,
            nameAlignment: AvatarNameAlignment.inside,
            onPressed: (character) async {
              await GameLogic.onInteractCharacter(character);
              context.read<MeetingState>().remove(character);
            },
          ),
        ),
      );
    }

    return Stack(
      children: [
        // 半透明黑色背景
        ModalBarrier(
          color: GameUI.barrierColor,
          onDismiss: () {},
        ),
        // 头像列表
        ...peopleWidgets,
        // 退出按钮
        if (showExitButton)
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: fluent.Button(
                child: Label(
                  engine.locale('leave'),
                  width: 200,
                  textStyle: TextStyles.titleSmall,
                ),
                onPressed: () {
                  // 清空人员并隐藏
                  context.read<MeetingState>().update();
                },
              ),
            ),
          ),
      ],
    );
  }
}
