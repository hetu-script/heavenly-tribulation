import 'package:flutter/material.dart';
import 'package:samsara/widgets/ui/ink_button.dart';
import 'package:provider/provider.dart';
import 'package:samsara/widgets/ui/responsive_view.dart';

import '../../../engine.dart';
import '../../../ui.dart';
import '../../../state/editor_tool.dart';
import '../../../game/game.dart';
import '../../../widgets/common.dart';

const Size kTileSize = Size(32, 64);

class Toolbox extends StatefulWidget {
  const Toolbox({
    super.key,
    this.onToolClicked,
  });

  final void Function(String toolId)? onToolClicked;

  @override
  State<Toolbox> createState() => _ToolboxState();
}

class _ToolboxState extends State<Toolbox> {
  static List<Tab> tabs = [
    Tab(text: engine.locale('terrainTiles')),
    Tab(text: engine.locale('decorationTiles')),
    Tab(text: engine.locale('tileMapDecoration')),
    Tab(text: engine.locale('objectTiles')),
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget buildToolButton(
    BuildContext context,
    String toolId, {
    bool isTile = true,
    required String? selectedItem,
  }) {
    final toolItemData = GameData.tiles[toolId];
    final name = toolItemData?['name'] ?? toolId;
    final icon = toolItemData?['icon'] ?? 'assets/images/object/$toolId.png';
    return Tooltip(
      message: engine.locale(name),
      child: InkButton(
        size: kTileSize,
        padding: const EdgeInsets.only(right: 5.0),
        borderRadius: BorderRadius.circular(5.0),
        image: AssetImage(icon),
        isSelected: selectedItem == toolId,
        onPressed: () {
          context.read<EditorToolState>().select(toolId);
          widget.onToolClicked?.call(toolId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = context.watch<EditorToolState>().selectedId;

    return ResponsiveView(
      alignment: Alignment.bottomCenter,
      backgroundColor: GameUI.backgroundColor2,
      width: 640,
      height: 200,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 600,
            height: 200,
            child: DefaultTabController(
              length: tabs.length,
              child: Column(
                children: [
                  PreferredSize(
                    preferredSize: const Size.fromHeight(kToolbarTabBarHeight),
                    child: TabBar(
                      tabs: tabs,
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                children: [
                                  buildToolButton(
                                    context,
                                    'delete',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'isNotEnterable',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'isEnterable',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'sea',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'plain',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'river',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'snow_plain',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'snow_mountain',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'snow_forest',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'forest',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'mountain',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'farmfield',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'shelf',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'shore',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'dungeonStonePavedTile',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'city',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'portalArray',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'dungeon',
                                    selectedItem: item,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                children: [
                                  buildToolButton(
                                    context,
                                    'fishTile',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'stormTile',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'spiritTile',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'portal',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'dungeonStoneGate',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'glowingTile',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'lever',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'pressurePlate',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'statue',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'treasureBox',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'coffin',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'oldWell',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'meditationCushion',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'stoneStairs',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'stoneDebris',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'stoneStele',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'furnace',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'stain1',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'stain2',
                                    selectedItem: item,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                children: [
                                  buildToolButton(
                                    context,
                                    'meteorCrater',
                                    selectedItem: item,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                children: [
                                  buildToolButton(
                                    context,
                                    'characterBoy1',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'characterMan1',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'characterMan11',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'characterMan12',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'characterMan31',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'characterGirl1',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'characterWoman1',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'characterWoman11',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'characterWoman31',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'python',
                                    selectedItem: item,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // const Spacer(),
                  // Column(
                  //   children: [
                  //     fluent.FilledButton(
                  //       onPressed: () {},
                  //       child: Text(engine.locale('editMapId')),
                  //     ),
                  //   ],
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
