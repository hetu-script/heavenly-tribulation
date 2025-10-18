import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../../widgets/avatar.dart';
import '../../../ui.dart';
import '../../../engine.dart';
import '../../../state/meeting.dart';

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
  });

  final List people;

  List<Widget> _buildAvatars(List<dynamic> people) {
    final widgets = <Widget>[];
    for (int i = 0; i < people.length; i++) {
      if (i >= _avatarPositions.length) break; // 超出预设位置则不显示

      final character = people[i];
      final position = _avatarPositions[i];

      widgets.add(
        Align(
          alignment: position,
          child: Avatar(
            character: character,
            size: const Size(120, 120),
            showBorderImage: true,
            nameAlignment: AvatarNameAlignment.bottom,
            onPressed: (characterId) {},
          ),
        ),
      );
    }
    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 半透明黑色背景
        ModalBarrier(
          color: GameUI.backgroundColor,
          onDismiss: () {},
        ),
        // 头像列表
        ..._buildAvatars(people),
        // 退出按钮
        Positioned(
          bottom: 40,
          left: 0,
          right: 0,
          child: Center(
            child: fluent.FilledButton(
              child: Text(engine.locale('end')),
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
