import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter/widgets.dart';
// import 'package:samsara/samsara.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';
import 'package:samsara/ui/integer_input_field.dart';

import '../../engine.dart';
import '../../view/dropdown_menu_button.dart';
import '../../ui.dart';

const kObjectTypes = {
  "portal",
  "mapEntry",
};

class EditObject extends StatefulWidget {
  const EditObject({
    super.key,
    this.worldId,
    this.id,
    this.left,
    this.top,
    this.mapWidth,
    this.mapHeight,
    this.entityType,
    this.spriteSrc,
    this.useCustomInteraction,
  });

  final String? worldId, id;
  final int? left, top;
  final int? mapWidth, mapHeight;
  final String? entityType;
  final String? spriteSrc;
  final bool? useCustomInteraction;

  @override
  State<EditObject> createState() => _EditObjectState();
}

class _EditObjectState extends State<EditObject> {
  final _worldIdEditingController = TextEditingController();
  final _idEditingController = TextEditingController();
  final _posXController = TextEditingController();
  final _posYController = TextEditingController();
  final _entityTypeEditingController = TextEditingController();
  final _spriteSrcEditingController = TextEditingController();

  bool _useCustomInteraction = false;

  String? _selectedObjectType = kObjectTypes.first;

  @override
  void initState() {
    super.initState();

    _worldIdEditingController.text = widget.worldId ?? '';
    _idEditingController.text = widget.id ?? '';
    _posXController.text = widget.left?.toString() ?? '1';
    _posYController.text = widget.top?.toString() ?? '1';
    _entityTypeEditingController.text = widget.entityType ?? '';
    _spriteSrcEditingController.text = widget.spriteSrc ?? '';
    _useCustomInteraction = widget.useCustomInteraction ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWindow(
      color: kBackgroundColor,
      alignment: AlignmentDirectional.center,
      size: const Size(350.0, 550.0),
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            engine.locale('edit'),
          ),
          actions: const [CloseButton2()],
        ),
        body: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 280,
                height: 40,
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 90.0,
                      child: Text('${engine.locale('worldId')}: '),
                    ),
                    SizedBox(
                      width: 190.0,
                      child: TextField(
                        autofocus: true,
                        controller: _worldIdEditingController,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(' ')
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 280,
                height: 40,
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 90.0,
                      child: Text('${engine.locale('coordinates')}:'),
                    ),
                    Container(
                      width: 95,
                      padding: const EdgeInsets.only(right: 10.0),
                      child: IntegerInputField(
                        initValue: widget.left,
                        min: 1,
                        max: widget.mapWidth,
                        controller: _posXController,
                      ),
                    ),
                    Container(
                      width: 95,
                      padding: const EdgeInsets.only(left: 10.0),
                      child: IntegerInputField(
                        initValue: widget.top,
                        min: 1,
                        max: widget.mapHeight,
                        controller: _posYController,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 280,
                height: 40,
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 90.0,
                      child: Text('ID:'),
                    ),
                    SizedBox(
                      width: 190.0,
                      height: 40.0,
                      child: TextField(
                        controller: _idEditingController,
                        inputFormatters: [
                          FilteringTextInputFormatter.deny(' ')
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 280,
                height: 60,
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90.0,
                      child: Text('${engine.locale('type')}:'),
                    ),
                    SizedBox(
                        width: 190.0,
                        height: 40.0,
                        child: DropdownMenuButton(
                          selections: {
                            for (final element in kObjectTypes)
                              engine.locale(element): element
                          },
                          selected: _selectedObjectType,
                          onChanged: (newValue) {
                            setState(() {
                              _selectedObjectType = newValue;
                            });
                          },
                        )),
                  ],
                ),
              ),
              Container(
                width: 280,
                height: 40,
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90.0,
                      child: Text('${engine.locale('image')}:'),
                    ),
                    SizedBox(
                      width: 190.0,
                      height: 40.0,
                      child: TextField(
                        controller: _spriteSrcEditingController,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 280,
                height: 40,
                padding: const EdgeInsets.only(top: 20),
                child: Row(
                  children: [
                    Checkbox(
                      value: _useCustomInteraction,
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() {
                            _useCustomInteraction = newValue;
                          });
                        }
                      },
                    ),
                    Text(engine.locale('useCustomInteraction'))
                  ],
                ),
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(top: 10.0, bottom: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    engine.locale('confirm'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
