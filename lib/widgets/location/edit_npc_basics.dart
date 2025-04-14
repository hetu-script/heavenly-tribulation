import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../game/ui.dart';
import '../../game/data.dart';

class EditNpcBasics extends StatefulWidget {
  /// 返回以下值
  /// id,
  /// name,
  /// icon,
  /// illustration
  const EditNpcBasics({
    super.key,
    required this.id,
    this.name,
    this.icon,
    this.illustration,
  });

  final String id;
  final String? name;
  final String? icon;
  final String? illustration;

  @override
  State<EditNpcBasics> createState() => _EditNpcBasicsState();
}

class _EditNpcBasicsState extends State<EditNpcBasics> {
  final _nameEditingController = TextEditingController();
  final _iconEditingController = TextEditingController();
  final _illustrationEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _nameEditingController.text = widget.name ?? '';
    _iconEditingController.text = widget.icon ?? '';
    _illustrationEditingController.text = widget.illustration ?? '';
  }

  @override
  void dispose() {
    super.dispose();

    _nameEditingController.dispose();
    _iconEditingController.dispose();
    _illustrationEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 600.0,
      height: 480.0,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const SizedBox(
                    width: 100.0,
                    child: Text('ID: '),
                  ),
                  SizedBox(
                    width: 180.0,
                    child: Text(widget.id),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100.0,
                    child: Text('${engine.locale('name')}: '),
                  ),
                  SizedBox(
                    width: 180.0,
                    child: TextField(
                      controller: _nameEditingController,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100.0,
                    child: Text('${engine.locale('icon')}: '),
                  ),
                  SizedBox(
                    width: 450.0,
                    height: 40.0,
                    child: TextField(
                      controller: _iconEditingController,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100.0,
                    child: Text('${engine.locale('illustration')}: '),
                  ),
                  SizedBox(
                    width: 450.0,
                    height: 40.0,
                    child: TextField(
                      controller: _illustrationEditingController,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: fluent.FilledButton(
                      onPressed: () {
                        dynamic npcData = GameData.gameData['npcs'][widget.id];
                        if (npcData != null) {
                          npcData['name'] = _nameEditingController.text;
                          npcData['icon'] = _iconEditingController.text;
                          npcData['illustration'] =
                              _illustrationEditingController.text;
                        } else {
                          npcData = engine.hetu.invoke(
                            'Npc',
                            namedArgs: {
                              'id': widget.id,
                              'name': _nameEditingController.text,
                              'icon': _iconEditingController.text,
                              'illustration':
                                  _illustrationEditingController.text,
                            },
                          );
                        }
                        Navigator.of(context).pop(npcData);
                      },
                      child: Text(
                        engine.locale('confirm'),
                      ),
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
