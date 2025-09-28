import 'package:flutter/material.dart';
import 'package:heavenly_tribulation/common.dart';
import 'package:heavenly_tribulation/widgets/ui/menu_builder.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:fluent_ui/fluent_ui.dart' as fluent;

import '../dialog/character_select.dart';
import '../../engine.dart';
import '../../game/data.dart';
import '../../game/ui.dart';
import '../ui/close_button2.dart';

class EditOrganizationBasics extends StatefulWidget {
  const EditOrganizationBasics({
    super.key,
    this.id,
    this.name,
    this.category,
    this.genre,
    this.headId,
    this.headquartersData,
  });

  final String? id;
  final String? name;
  final String? category;
  final String? genre;
  final String? headId;
  final dynamic headquartersData;

  @override
  State<EditOrganizationBasics> createState() => _EditOrganizationBasicsState();
}

class _EditOrganizationBasicsState extends State<EditOrganizationBasics> {
  final _idEditingController = TextEditingController();
  final _nameEditingController = TextEditingController();
  final _headIdEditingController = TextEditingController();

  late String selectedCategory, selectedGenre;

  void randomName() {
    _nameEditingController.text =
        engine.hetu.invoke('generateOrganizationName')['name'];
  }

  @override
  void dispose() {
    super.dispose();

    _idEditingController.dispose();
    _nameEditingController.dispose();
    _headIdEditingController.dispose();
  }

  @override
  void initState() {
    super.initState();

    if (widget.name != null) {
      _nameEditingController.text = widget.name!;
    } else {
      randomName();
    }

    _idEditingController.text = widget.id ?? _nameEditingController.text;

    selectedCategory = widget.category ?? kOrganizationCategories.random;
    selectedGenre = widget.genre ?? kCultivationGenres.random;

    _headIdEditingController.text = widget.headId ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor2,
      alignment: AlignmentDirectional.center,
      width: 500.0,
      height: 400.0,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(
            engine.locale('edit'),
          ),
          actions: const [CloseButton2()],
        ),
        body: Container(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            children: [
              Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 15.0),
                        width: 100.0,
                        child: Text(
                          '${engine.locale('headquartersTilePosition')}: ',
                        ),
                      ),
                      Text(
                        '${widget.headquartersData['name']}'
                        '(${widget.headquartersData['worldPosition']['left']}, ${widget.headquartersData['worldPosition']['top']})',
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 100.0,
                        child: const Text('ID:'),
                      ),
                      SizedBox(
                        width: 180.0,
                        height: 40.0,
                        child: TextField(
                          controller: _idEditingController,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 100.0,
                        child: Text(
                          '${engine.locale('name')}: ',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(right: 20.0),
                        width: 180.0,
                        height: 40.0,
                        child: TextField(
                          controller: _nameEditingController,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100.0,
                          child: Text('${engine.locale('category')}: '),
                        ),
                        fluent.DropDownButton(
                          title: Text(engine.locale(selectedCategory)),
                          items: buildFluentMenuItems(
                            items: {
                              for (final key in kOrganizationCategories)
                                engine.locale(key): key,
                            },
                            onSelectedItem: (String value) {
                              setState(() {
                                selectedCategory = value;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 20.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100.0,
                          child: Text('${engine.locale('genre')}: '),
                        ),
                        fluent.DropDownButton(
                          title: Text(engine.locale(selectedGenre)),
                          items: buildFluentMenuItems(
                            items: {
                              for (final key in kCultivationGenres)
                                engine.locale(key): key,
                            },
                            onSelectedItem: (String value) {
                              setState(() {
                                selectedGenre = value;
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
                      Container(
                        padding: const EdgeInsets.only(top: 15.0),
                        width: 100.0,
                        child: Text(
                          '${engine.locale('headId')}: ',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(right: 20.0),
                        width: 180.0,
                        height: 40.0,
                        child: TextField(
                          controller: _headIdEditingController,
                        ),
                      ),
                      fluent.FilledButton(
                        onPressed: () async {
                          final key = await CharacterSelectDialog.show(
                            context: context,
                            title: engine.locale('selectCharacter'),
                            characters: GameData.game['characters'].values,
                            showCloseButton: true,
                          );
                          _headIdEditingController.text = key ?? '';
                        },
                        child: Text(engine.locale('select')),
                      )
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: fluent.FilledButton(
                  onPressed: () {
                    String? id = _idEditingController.text.nonEmptyValue;
                    String? name = _nameEditingController.text.nonEmptyValue;
                    String? category = selectedCategory;
                    String? genre = selectedGenre;
                    String? headId =
                        _headIdEditingController.text.nonEmptyValue;

                    Navigator.of(context).pop((
                      id,
                      name,
                      category,
                      genre,
                      headId,
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
