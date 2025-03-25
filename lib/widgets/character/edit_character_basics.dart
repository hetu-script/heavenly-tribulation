import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:flutter/services.dart';

import '../../engine.dart';
import '../../game/ui.dart';

class EditCharacterBasics extends StatefulWidget {
  /// 返回以下值
  /// id,
  /// name,
  /// surName,
  /// isFemale,
  /// skin,
  /// icon,
  /// illustration
  const EditCharacterBasics({
    super.key,
    this.id,
    this.name,
    this.skin,
    this.surName,
    this.iconPath,
    this.illustrationPath,
  });

  final String? id;
  final String? name;
  final String? skin;
  final String? surName;
  final String? iconPath;
  final String? illustrationPath;

  @override
  State<EditCharacterBasics> createState() => _EditCharacterBasicsState();
}

class _EditCharacterBasicsState extends State<EditCharacterBasics> {
  final _idEditingController = TextEditingController();
  final _nameEditingController = TextEditingController();
  final _skinEditingController = TextEditingController();
  final _surNameEditingController = TextEditingController();
  final _iconEditingController = TextEditingController();
  final _illustrationEditingController = TextEditingController();

  bool _isFemale = false;

  @override
  void initState() {
    super.initState();

    _idEditingController.text = widget.id ?? '';
    _nameEditingController.text = widget.name ?? '';
    _skinEditingController.text = widget.skin ?? '';
    _surNameEditingController.text = widget.surName ?? '';
    _iconEditingController.text = widget.iconPath ?? '';
    _illustrationEditingController.text = widget.illustrationPath ?? '';
  }

  @override
  void dispose() {
    super.dispose();

    _idEditingController.dispose();
    _nameEditingController.dispose();
    _skinEditingController.dispose();
    _surNameEditingController.dispose();
    _iconEditingController.dispose();
    _illustrationEditingController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 350.0,
      height: 450.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            engine.locale('edit'),
          ),
          actions: const [CloseButton2()],
        ),
        body: Container(
          width: 350.0,
          height: 400.0,
          alignment: Alignment.center,
          padding: const EdgeInsets.only(top: 20.0),
          child: Column(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 280.0,
                    height: 40.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const SizedBox(
                          width: 90.0,
                          child: Text('ID: '),
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
                  SizedBox(
                    width: 150.0,
                    height: 40.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 90.0,
                          child: Text('${engine.locale('surName')}: '),
                        ),
                        SizedBox(
                          width: 60.0,
                          height: 40.0,
                          child: TextField(
                            controller: _surNameEditingController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 150.0,
                    height: 40.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 90.0,
                          child: Text('${engine.locale('shortName')}: '),
                        ),
                        SizedBox(
                          width: 60.0,
                          height: 40.0,
                          child: TextField(
                            controller: _nameEditingController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 220.0,
                    height: 40.0,
                    margin: const EdgeInsets.only(top: 20.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text('${engine.locale('isFemale')}: '),
                        ),
                        SizedBox(
                          width: 50,
                          height: 30,
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
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 280.0,
                    height: 40.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 90.0,
                          child: Text('${engine.locale('icon')}: '),
                        ),
                        SizedBox(
                          width: 190.0,
                          height: 40.0,
                          child: TextField(
                            controller: _iconEditingController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 280.0,
                    height: 40.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 90.0,
                          child: Text('${engine.locale('illustration')}: '),
                        ),
                        SizedBox(
                          width: 190.0,
                          height: 40.0,
                          child: TextField(
                            controller: _illustrationEditingController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 280.0,
                    height: 40.0,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SizedBox(
                          width: 90.0,
                          child: Text('${engine.locale('characterSkin')}: '),
                        ),
                        SizedBox(
                          width: 190.0,
                          height: 40.0,
                          child: TextField(
                            controller: _skinEditingController,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: ElevatedButton(
                  onPressed: () {
                    String? id = _idEditingController.text.nonEmptyValue;
                    String? name = _nameEditingController.text.nonEmptyValue;
                    String? skin = _skinEditingController.text.nonEmptyValue;
                    String? surName =
                        _surNameEditingController.text.nonEmptyValue;
                    String? icon = _iconEditingController.text.nonEmptyValue;
                    String? illustration =
                        _illustrationEditingController.text.nonEmptyValue;

                    Navigator.of(context).pop((
                      id,
                      name,
                      surName,
                      _isFemale,
                      skin,
                      icon,
                      illustration,
                    ));
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
