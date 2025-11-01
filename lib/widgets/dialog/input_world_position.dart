import 'dart:async';

import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/widgets/ui/integer_input_field.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../global.dart';
import '../../ui.dart';
import '../../data/game.dart';
import '../ui/close_button2.dart';
import '../ui/menu_builder.dart';
import '../ui/responsive_view.dart';

class InputWorldPositionDialog extends StatefulWidget {
  static Future<(int, int, String?)?> show({
    required BuildContext context,
    int? defaultX,
    int? defaultY,
    int? maxX,
    int? maxY,
    String? title,
    String? worldId,
    bool enableWorldId = true,
    bool barrierDismissible = true,
  }) {
    return showDialog<(int, int, String?)>(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) {
        return InputWorldPositionDialog(
          defaultX: defaultX,
          defaultY: defaultY,
          maxX: maxX,
          maxY: maxY,
          title: title,
          worldId: worldId,
          enableWorldId: enableWorldId,
          barrierDismissible: barrierDismissible,
        );
      },
    );
  }

  const InputWorldPositionDialog({
    super.key,
    this.defaultX,
    this.defaultY,
    this.maxX,
    this.maxY,
    this.title,
    this.worldId,
    this.enableWorldId = true,
    this.barrierDismissible = true,
  });

  final int? defaultX, defaultY;
  final int? maxX, maxY;
  final String? title;
  final String? worldId;
  final bool enableWorldId;
  final bool barrierDismissible;

  @override
  State<InputWorldPositionDialog> createState() =>
      _InputWorldPositionDialogState();
}

class _InputWorldPositionDialogState extends State<InputWorldPositionDialog> {
  final _posXController = TextEditingController();
  final _posYController = TextEditingController();
  final _menuController = fluent.FlyoutController();

  late String _worldId;

  @override
  void initState() {
    super.initState();

    _posXController.text = widget.defaultX?.toString() ?? '';
    _posYController.text = widget.defaultY?.toString() ?? '';

    _worldId = widget.worldId ?? '';
  }

  @override
  void dispose() {
    super.dispose();

    _posXController.dispose();
    _posYController.dispose();
    _menuController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      barrierDismissible: widget.barrierDismissible,
      barrierColor: null,
      backgroundColor: GameUI.backgroundColorOpaque,
      width: 360.0,
      height: 280.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(widget.title ?? engine.locale('setWorldPosition')),
          actions: const [CloseButton2()],
        ),
        body: Container(
          alignment: AlignmentDirectional.center,
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              if (widget.enableWorldId)
                SizedBox(
                  width: 300,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 60.0,
                        child: Text('${engine.locale('worldId')}: '),
                      ),
                      Container(
                        width: 220.0,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 20.0),
                        child: fluent.FlyoutTarget(
                          controller: _menuController,
                          child: fluent.Button(
                            onPressed: () {
                              showFluentMenu(
                                controller: _menuController,
                                items: {
                                  for (final key in GameData.worldIds) key: key,
                                },
                                onSelectedItem: (String worldId) {
                                  setState(() {
                                    _worldId = worldId;
                                  });
                                },
                              );
                            },
                            child: Text(
                                _worldId.isEmpty
                                    ? engine.locale('none')
                                    : _worldId,
                                style: GameUI.textTheme.bodyLarge),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: 300,
                child: Row(
                  children: [
                    SizedBox(
                      width: 60.0,
                      child: Text('${engine.locale('worldPosition')}:'),
                    ),
                    Container(
                      width: 110.0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 20.0),
                      child: IntegerInputField(
                        autofocus: true,
                        initValue: widget.defaultX,
                        min: 0,
                        max: widget.maxX,
                        controller: _posXController,
                      ),
                    ),
                    Container(
                      width: 110.0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 20.0),
                      child: IntegerInputField(
                        initValue: widget.defaultY,
                        min: 0,
                        max: widget.maxY,
                        controller: _posYController,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(10.0),
                child: fluent.Button(
                  onPressed: () {
                    final worldId = _worldId.nonEmptyValue;
                    final x = int.tryParse(_posXController.text);
                    final y = int.tryParse(_posYController.text);
                    if (worldId != null) {
                      Navigator.of(context).pop((x, y, worldId));
                    } else {
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(
                    engine.locale('confirm'),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
