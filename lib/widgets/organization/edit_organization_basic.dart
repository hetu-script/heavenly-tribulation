import 'package:flutter/material.dart';
import 'package:samsara/samsara.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';

import '../dialog/character_select.dart';
import '../../engine.dart';
import '../../game/data.dart';
import '../../game/ui.dart';

class EditOrganizationBasics extends StatefulWidget {
  const EditOrganizationBasics({
    super.key,
    this.id,
    this.name,
    this.category,
    this.genre,
    this.headquartersId,
    this.headId,
  });

  final String? id;
  final String? name;
  final String? category;
  final String? genre;
  final String? headquartersId;
  final String? headId;

  @override
  State<EditOrganizationBasics> createState() => _EditOrganizationBasicsState();
}

class _EditOrganizationBasicsState extends State<EditOrganizationBasics> {
  final _idEditingController = TextEditingController();
  final _nameEditingController = TextEditingController();
  final _headquartersIdEditingController = TextEditingController();
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
    _headquartersIdEditingController.dispose();
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

    selectedCategory =
        widget.category ?? GameData.organizationCategoryNames.keys.random;
    selectedGenre = widget.genre ?? GameData.cultivationGenreNames.keys.random;

    _headquartersIdEditingController.text = widget.headquartersId ?? '';
    _headIdEditingController.text = widget.headId ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      backgroundColor: GameUI.backgroundColor,
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
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
          child: Column(
            children: [
              Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 15.0),
                        width: 100.0,
                        child: const Text('ID:'),
                      ),
                      SizedBox(
                        width: 140.0,
                        height: 40.0,
                        child: TextField(
                          controller: _idEditingController,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 15.0),
                        width: 100.0,
                        child: Text(
                          '${engine.locale('name')}: ',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(right: 20.0),
                        width: 140.0,
                        height: 40.0,
                        child: TextField(
                          controller: _nameEditingController,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: randomName,
                        child: Text(engine.locale('random')),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 100.0,
                        child: Text('${engine.locale('category')}: '),
                      ),
                      DropdownButton<String>(
                        style: GameUI.textTheme.bodyMedium,
                        items: GameData.organizationCategoryNames.keys
                            .map((name) => DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(GameData
                                      .organizationCategoryNames[name]!),
                                ))
                            .toList(),
                        value: selectedCategory,
                        onChanged: (value) => selectedCategory = value!,
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      SizedBox(
                        width: 100.0,
                        child: Text('${engine.locale('genre')}: '),
                      ),
                      DropdownButton<String>(
                        style: GameUI.textTheme.bodyMedium,
                        items: GameData.cultivationGenreNames.keys
                            .map((name) => DropdownMenuItem<String>(
                                  value: name,
                                  child: Text(
                                      GameData.cultivationGenreNames[name]!),
                                ))
                            .toList(),
                        value: selectedGenre,
                        onChanged: (value) => selectedGenre = value!,
                      ),
                    ],
                  ),
                  Row(
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
                        width: 140.0,
                        height: 40.0,
                        child: TextField(
                          controller: _headIdEditingController,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final charactersData =
                              engine.hetu.invoke('getCharacters');
                          final key = await CharacterSelectDialog.show(
                            context: context,
                            title: engine.locale('selectCharacter'),
                            charactersData: charactersData,
                            showCloseButton: true,
                          );
                          _headIdEditingController.text = key ?? '';
                        },
                        child: Text(engine.locale('select')),
                      )
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.only(top: 15.0),
                        width: 100.0,
                        child: Text(
                          '${engine.locale('headquartersId')}: ',
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.only(right: 20.0),
                        width: 140.0,
                        height: 40.0,
                        child: TextField(
                          controller: _headquartersIdEditingController,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: randomName,
                        child: Text(engine.locale('selectLocation')),
                      )
                    ],
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 20.0),
                child: ElevatedButton(
                  onPressed: () {
                    String? id = _idEditingController.text.nonEmptyValue;
                    String? name = _nameEditingController.text.nonEmptyValue;
                    String? category = selectedCategory;
                    String? genre = selectedGenre;
                    String? headquartersId =
                        _headquartersIdEditingController.text.nonEmptyValue;
                    String? headId =
                        _headIdEditingController.text.nonEmptyValue;

                    Navigator.of(context).pop((
                      id,
                      name,
                      category,
                      genre,
                      headquartersId,
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
