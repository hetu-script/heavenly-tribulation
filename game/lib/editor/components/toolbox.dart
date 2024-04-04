import 'package:flutter/material.dart';
import 'package:samsara/ui/ink_button.dart';
import 'package:provider/provider.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/extensions.dart';

import '../../config.dart';
import '../../state/editor_tool.dart';

const Size kTileSize = Size(32, 64);

class Toolbox extends StatefulWidget {
  const Toolbox({
    super.key,
    required this.onItemClicked,
  });

  final void Function(String item) onItemClicked;

  @override
  State<Toolbox> createState() => _ToolboxState();
}

class _ToolboxState extends State<Toolbox> {
  SpriteSheet? terrainSpriteSheet;

  @override
  void initState() {
    super.initState();

    load();
  }

  Future<void> load() async {
    terrainSpriteSheet = SpriteSheet(
      image: await Flame.images.load('fantasyhextiles_v3_borderless.png'),
      srcSize: Vector2(32.0, 64.0),
    );

    setState(() {});
  }

  Widget buildToolButton(
      BuildContext context, String? selectedItem, String me) {
    return Tooltip(
      message: engine.locale(me),
      child: InkButton(
        size: kTileSize,
        padding: const EdgeInsets.only(right: 5.0),
        borderRadius: BorderRadius.circular(5.0),
        image: AssetImage(
          'assets/images/object/$me.png',
        ),
        isSelected: selectedItem == me,
        onPressed: () {
          context.read<EditorToolState>().selectItem(me);
          widget.onItemClicked(me);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = context.watch<EditorToolState>().item;

    return ResponsiveWindow(
      color: kBackgroundColor,
      size: const Size(640, 170),
      padding: const EdgeInsets.all(10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 420,
            height: 150,
            child: SingleChildScrollView(
              child: ListView(
                shrinkWrap: true,
                children: [
                  Row(
                    children: [
                      buildToolButton(context, item, 'delete'),
                      buildToolButton(context, item, 'nonInteractable'),
                      buildToolButton(context, item, 'sea'),
                      buildToolButton(context, item, 'plain'),
                      buildToolButton(context, item, 'farmfield'),
                      buildToolButton(context, item, 'forest'),
                      buildToolButton(context, item, 'mountain'),
                      buildToolButton(context, item, 'dungeonStonePavedTile'),
                    ],
                  ),
                  Row(
                    children: [
                      // buildToolButton(context, item, 'pond'),
                      // buildToolButton(context, item, 'shelf'),
                      buildToolButton(context, item, 'fishTile'),
                      buildToolButton(context, item, 'stormTile'),
                      buildToolButton(context, item, 'spiritTile'),
                      buildToolButton(context, item, 'city'),
                      buildToolButton(context, item, 'portalArray'),
                      buildToolButton(context, item, 'dungeon'),
                      buildToolButton(context, item, 'dungeonStoneGate'),
                      buildToolButton(context, item, 'portal'),
                      buildToolButton(context, item, 'glowingTile'),
                      buildToolButton(context, item, 'lever'),
                    ],
                  ),
                  Row(
                    children: [
                      buildToolButton(context, item, 'statue'),
                      buildToolButton(context, item, 'treasureBox'),
                      buildToolButton(context, item, 'coffin'),
                      buildToolButton(context, item, 'stoneStairs'),
                      buildToolButton(context, item, 'stoneStairsDebris'),
                      buildToolButton(context, item, 'characterDefault'),
                      buildToolButton(context, item, 'characterMan'),
                      buildToolButton(context, item, 'characterOld'),
                      buildToolButton(context, item, 'characterGirl'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              ElevatedButton(
                onPressed: () {},
                child: Text(engine.locale('editMapId')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
