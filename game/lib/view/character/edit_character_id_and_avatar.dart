import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/responsive_window.dart';
import 'package:samsara/ui/close_button.dart';
import 'package:flutter/services.dart';

import '../../config.dart';

class EditCharacterIdAndAvatar extends StatefulWidget {
  const EditCharacterIdAndAvatar({
    super.key,
    required this.id,
    required this.name,
    required this.skin,
    this.familyName,
    this.iconPath,
    this.illustrationPath,
  });

  final String id;
  final String name;
  final String skin;
  final String? familyName;
  final String? iconPath;
  final String? illustrationPath;

  @override
  State<EditCharacterIdAndAvatar> createState() =>
      _EditCharacterIdAndAvatarState();
}

class _EditCharacterIdAndAvatarState extends State<EditCharacterIdAndAvatar> {
  final _idEditingController = TextEditingController();
  final _nameEditingController = TextEditingController();
  final _skinEditingController = TextEditingController();
  final _familyNameEditingController = TextEditingController();
  final _iconEditingController = TextEditingController();
  final _illustrationEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _idEditingController.text = widget.id;
    _nameEditingController.text = widget.name;
    _skinEditingController.text = widget.skin;
    _familyNameEditingController.text = widget.familyName ?? '';
    _iconEditingController.text = widget.iconPath ?? '';
    _illustrationEditingController.text = widget.illustrationPath ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveWindow(
      color: kBackgroundColor,
      alignment: AlignmentDirectional.center,
      size: const Size(350.0, 400.0),
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
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 280.0,
                    height: 40.0,
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 90.0,
                          child: Text('ID'),
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
                      children: [
                        SizedBox(
                          width: 90.0,
                          child: Text('${engine.locale('familyName')}: '),
                        ),
                        SizedBox(
                          width: 60.0,
                          height: 40.0,
                          child: TextField(
                            controller: _familyNameEditingController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 150.0,
                    height: 40.0,
                    child: Row(
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
                  SizedBox(
                    width: 280.0,
                    height: 40.0,
                    child: Row(
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
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    String? id = _idEditingController.text.nonEmptyValueOrNull;
                    String? name =
                        _nameEditingController.text.nonEmptyValueOrNull;
                    String? skin =
                        _skinEditingController.text.nonEmptyValueOrNull;
                    String? familyName =
                        _familyNameEditingController.text.nonEmptyValueOrNull;
                    String? icon =
                        _iconEditingController.text.nonEmptyValueOrNull;
                    String? illustration =
                        _illustrationEditingController.text.nonEmptyValueOrNull;

                    Navigator.of(context).pop((
                      id,
                      name,
                      familyName,
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
