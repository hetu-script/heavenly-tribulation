import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:flutter/services.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../../engine.dart';
import '../../game/ui.dart';
import '../../common.dart';
import '../ui/menu_builder.dart';
import '../ui/close_button2.dart';

class EditCharacterBasics extends StatefulWidget {
  /// 返回以下值
  /// id,
  /// surName,
  /// name,
  /// isFemale,
  /// race,
  /// icon,
  /// illustration
  /// model,
  const EditCharacterBasics({
    super.key,
    this.id,
    this.surName,
    this.shortName,
    this.isFemale,
    this.race,
    this.icon,
    this.illustration,
    this.model,
  });

  final String? id;
  final String? shortName;
  final bool? isFemale;
  final String? race;
  final String? model;
  final String? surName;
  final String? icon;
  final String? illustration;

  @override
  State<EditCharacterBasics> createState() => _EditCharacterBasicsState();
}

class _EditCharacterBasicsState extends State<EditCharacterBasics> {
  final _idEditingController = TextEditingController();
  final _shortNameEditingController = TextEditingController();
  final _modelEditingController = TextEditingController();
  final _surNameEditingController = TextEditingController();
  final _iconEditingController = TextEditingController();
  final _illustrationEditingController = TextEditingController();

  bool _isFemale = false;
  String _race = 'xianzu';

  @override
  void initState() {
    super.initState();

    _idEditingController.text = widget.id ?? '';
    _shortNameEditingController.text = widget.shortName ?? '';
    _modelEditingController.text = widget.model ?? '';
    _surNameEditingController.text = widget.surName ?? '';
    _iconEditingController.text = widget.icon ?? '';
    _illustrationEditingController.text = widget.illustration ?? '';
  }

  @override
  void dispose() {
    super.dispose();

    _idEditingController.dispose();
    _shortNameEditingController.dispose();
    _modelEditingController.dispose();
    _surNameEditingController.dispose();
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
                    child: TextField(
                      controller: _idEditingController,
                      inputFormatters: [FilteringTextInputFormatter.deny(' ')],
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100.0,
                    child: Text('${engine.locale('surName')}: '),
                  ),
                  SizedBox(
                    width: 180.0,
                    child: TextField(
                      controller: _surNameEditingController,
                    ),
                  ),
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100.0,
                    child: Text('${engine.locale('shortName')}: '),
                  ),
                  SizedBox(
                    width: 180.0,
                    child: TextField(
                      controller: _shortNameEditingController,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 90,
                      child: Text('${engine.locale('gender')}: '),
                    ),
                    Container(
                      width: 55,
                      padding: const EdgeInsets.only(right: 10.0),
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: Switch(
                          value: _isFemale,
                          activeColor: Colors.white,
                          onChanged: (bool value) {
                            setState(() {
                              _isFemale = value;
                            });
                          },
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60.0,
                      child: Text(_isFemale
                          ? engine.locale('female')
                          : engine.locale('male')),
                    ),
                    SizedBox(
                      width: 100,
                      child: Text('${engine.locale('race')}: '),
                    ),
                    fluent.DropDownButton(
                      title: Text(engine.locale(_race)),
                      items: buildFluentMenuItems(
                        items: {
                          for (final key in kRaces) engine.locale(key): key,
                        },
                        onSelectedItem: (String race) {
                          setState(() {
                            _race = race;
                          });
                        },
                      ),
                    ),
                  ],
                ),
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 100.0,
                    child: Text('${engine.locale('model')}: '),
                  ),
                  SizedBox(
                    width: 450.0,
                    height: 40.0,
                    child: TextField(
                      controller: _modelEditingController,
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
                        String? id = _idEditingController.text.nonEmptyValue;
                        String? surName =
                            _surNameEditingController.text.nonEmptyValue;
                        String? shortName =
                            _shortNameEditingController.text.nonEmptyValue;
                        String? icon =
                            _iconEditingController.text.nonEmptyValue;
                        String? illustration =
                            _illustrationEditingController.text.nonEmptyValue;
                        String? model =
                            _modelEditingController.text.nonEmptyValue;

                        Navigator.of(context).pop((
                          id,
                          surName,
                          shortName,
                          _isFemale,
                          _race,
                          icon,
                          illustration,
                          model,
                        ));
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
