import 'package:flutter/material.dart';
import 'package:samsara/ui/ink_button.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/extensions.dart';

import '../../../engine.dart';
import '../../../ui.dart';
import '../../../state/editor_tool.dart';
// import '../../data.dart';

const double kToolbarTabBarHeight = 30.0;

const Size kTileSize = Size(32, 64);

class Toolbox extends StatefulWidget {
  const Toolbox({
    super.key,
    required this.onToolClicked,
  });

  final void Function(String toolId) onToolClicked;

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
      BuildContext context, String? selectedItem, String toolId) {
    // final toolItemData = GameData.editorToolItemsData[toolId];
    return Tooltip(
      message: engine.locale(toolId),
      child: InkButton(
        size: kTileSize,
        padding: const EdgeInsets.only(right: 5.0),
        borderRadius: BorderRadius.circular(5.0),
        image: AssetImage(
          'assets/images/object/$toolId.png',
        ),
        isSelected: selectedItem == toolId,
        onPressed: () {
          context.read<EditorToolState>().select(toolId);
          widget.onToolClicked(toolId);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = context.watch<EditorToolState>().selectedId;

    return ResponsiveWindow(
      color: GameUI.backgroundColor,
      size: const Size(640, 200),
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
                                  buildToolButton(context, item, 'delete'),
                                  buildToolButton(
                                      context, item, 'nonInteractable'),
                                  buildToolButton(context, item, 'sea'),
                                  buildToolButton(context, item, 'plain'),
                                  buildToolButton(context, item, 'farmfield'),
                                  buildToolButton(context, item, 'forest'),
                                  buildToolButton(context, item, 'mountain'),
                                  buildToolButton(
                                      context, item, 'dungeonStonePavedTile'),
                                ],
                              ),
                              Wrap(
                                children: [
                                  // buildToolButton(context, item, 'pond'),
                                  // buildToolButton(context, item, 'shelf'),
                                  buildToolButton(context, item, 'fishTile'),
                                  buildToolButton(context, item, 'stormTile'),
                                  buildToolButton(context, item, 'spiritTile'),
                                  buildToolButton(context, item, 'city'),
                                  buildToolButton(context, item, 'portalArray'),
                                  buildToolButton(context, item, 'dungeon'),
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
                                      context, item, 'dungeonStoneGate'),
                                  buildToolButton(context, item, 'portal'),
                                  buildToolButton(context, item, 'glowingTile'),
                                  buildToolButton(context, item, 'lever'),
                                  buildToolButton(
                                      context, item, 'pressurePlate'),
                                  buildToolButton(context, item, 'statue'),
                                  buildToolButton(context, item, 'treasureBox'),
                                  buildToolButton(context, item, 'coffin'),
                                  buildToolButton(context, item, 'oldWell'),
                                  buildToolButton(
                                      context, item, 'meditationCushion'),
                                  buildToolButton(context, item, 'stoneStairs'),
                                  buildToolButton(
                                      context, item, 'stoneStairsDebris'),
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
                                      context, item, 'characterBoy'),
                                  buildToolButton(
                                      context, item, 'characterYoungMan'),
                                  buildToolButton(
                                      context, item, 'characterMan'),
                                  buildToolButton(
                                      context, item, 'characterOldMan'),
                                  buildToolButton(
                                      context, item, 'characterGirl'),
                                  buildToolButton(
                                      context, item, 'characterYoungWoman'),
                                  buildToolButton(
                                      context, item, 'characterWoman'),
                                  buildToolButton(
                                      context, item, 'characterOldWoman'),
                                  buildToolButton(context, item, 'python'),
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
