import 'package:flutter/material.dart';
import 'package:samsara/ui/ink_button.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/extensions.dart';

import '../../../engine.dart';
import '../../../ui.dart';
import '../../../state/editor_tool.dart';
import '../../../data.dart';

const double kToolbarTabBarHeight = 30.0;

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
  SpriteSheet? terrainSpriteSheet;
  late final List<Tab> _tabs;

  @override
  void initState() {
    super.initState();

    _tabs = [
      Tab(
        height: kToolbarTabBarHeight,
        text: engine.locale('terrainTiles'),
      ),
      Tab(
        height: kToolbarTabBarHeight,
        text: engine.locale('decorationTiles'),
      ),
      Tab(
        height: kToolbarTabBarHeight,
        text: engine.locale('objectTiles'),
      ),
    ];

    load();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> load() async {
    terrainSpriteSheet = SpriteSheet(
      image: await Flame.images.load('fantasyhextiles_v3_borderless.png'),
      srcSize: Vector2(32.0, 64.0),
    );

    setState(() {});
  }

  Widget buildToolButton(
    BuildContext context,
    String toolId, {
    bool isTile = true,
    required String? selectedItem,
  }) {
    final toolItemData = GameData.tilesData[toolId];
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
      color: GameUI.backgroundColor,
      width: 640,
      height: 200,
      margin: const EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 600,
            height: 200,
            child: DefaultTabController(
              length: _tabs.length,
              child: Column(
                children: [
                  PreferredSize(
                    preferredSize: const Size.fromHeight(kToolbarTabBarHeight),
                    child: TabBar(
                      tabs: _tabs,
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
                                    'nonInteractable',
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
                                    'farmfield',
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
                                    'dungeonStonePavedTile',
                                    selectedItem: item,
                                  ),
                                ],
                              ),
                              Wrap(
                                children: [
                                  // buildToolButton(context, item, 'pond'),
                                  // buildToolButton(context, item, 'shelf'),
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
                                    'dungeonStoneGate',
                                    selectedItem: item,
                                  ),
                                  buildToolButton(
                                    context,
                                    'portal',
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
                                    'stoneStairsDebris',
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
                  //     ElevatedButton(
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
