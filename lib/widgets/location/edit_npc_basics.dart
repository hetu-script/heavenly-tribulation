import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../ui.dart';
import '../../game/game.dart';
import '../ui/close_button2.dart';

class EditNpcBasics extends StatefulWidget {
  /// 返回以下值
  /// id,
  /// name,
  /// icon,
  /// illustration
  const EditNpcBasics({
    super.key,
    required this.atLocation,
    required this.id,
    this.nameId,
    this.icon,
    this.illustration,
    this.useCustomLogic = false,
  });

  final dynamic atLocation;
  final String id;
  final String? nameId;
  final String? icon;
  final String? illustration;
  final bool useCustomLogic;

  @override
  State<EditNpcBasics> createState() => _EditNpcBasicsState();
}

class _EditNpcBasicsState extends State<EditNpcBasics> {
  final _nameIdEditingController = TextEditingController();
  final _iconEditingController = TextEditingController();
  final _illustrationEditingController = TextEditingController();
  bool _useCustomLogic = false;

  @override
  void initState() {
    super.initState();

    _nameIdEditingController.text = widget.nameId ?? '';
    _iconEditingController.text = widget.icon ?? '';
    _illustrationEditingController.text = widget.illustration ?? '';

    _useCustomLogic = widget.useCustomLogic;
  }

  @override
  void dispose() {
    super.dispose();

    _nameIdEditingController.dispose();
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
                    width: 450.0,
                    child: Text(
                      widget.id,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100.0,
                    child: Text('${engine.locale('name')}ID: '),
                  ),
                  SizedBox(
                    width: 180.0,
                    child: TextField(
                      controller: _nameIdEditingController,
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
              Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(
                      width: 200.0,
                      child: Text('${engine.locale('useCustomLogic')}:'),
                    ),
                    Container(
                      width: 20.0,
                      height: 22.0,
                      padding: const EdgeInsets.only(top: 2),
                      child: fluent.Checkbox(
                        checked: _useCustomLogic,
                        // activeColor: Colors.white,
                        onChanged: (bool? value) {
                          if (value != null) {
                            setState(() {
                              _useCustomLogic = value;
                            });
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: fluent.FilledButton(
                      onPressed: () {
                        GameData.data['npcs'].remove(widget.id);
                        widget.atLocation.remove('npcId');
                        Navigator.of(context).pop(null);
                      },
                      child: Text(
                        engine.locale('delete'),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: fluent.FilledButton(
                      onPressed: () {
                        dynamic npcData = GameData.data['npcs'][widget.id];
                        if (npcData != null) {
                          npcData['nameId'] = _nameIdEditingController.text;
                          npcData['name'] =
                              engine.locale(_nameIdEditingController.text);
                          npcData['icon'] = _iconEditingController.text;
                          npcData['illustration'] =
                              _illustrationEditingController.text;
                          npcData['useCustomLogic'] = _useCustomLogic;
                        } else {
                          npcData = engine.hetu.invoke(
                            'Npc',
                            namedArgs: {
                              'id': widget.id,
                              'nameId': _nameIdEditingController.text,
                              'icon': _iconEditingController.text,
                              'illustration':
                                  _illustrationEditingController.text,
                              'atLocationId': widget.atLocation['id'],
                              'useCustomLogic': _useCustomLogic,
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
