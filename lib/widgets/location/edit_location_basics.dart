import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:samsara/extensions.dart' show StringEx;

import '../../engine.dart';
import '../../game/data.dart';
import '../../game/ui.dart';

class EditLocationBasics extends StatefulWidget {
  /// 返回六个值的元组：
  /// category, kind, id, name, image, background
  const EditLocationBasics({
    super.key,
    this.category,
    this.kind,
    this.id,
    this.name,
    this.image,
    this.background,
    this.allowEditCategory = true,
  });

  final String? category;
  final String? kind;
  final String? id;
  final String? name;
  final String? image;
  final String? background;

  final bool allowEditCategory;

  @override
  State<EditLocationBasics> createState() => _EditLocationBasicsState();
}

class _EditLocationBasicsState extends State<EditLocationBasics> {
  final _idEditingController = TextEditingController();
  final _nameEditingController = TextEditingController();
  final _imageEditingController = TextEditingController();
  final _backgroundEditingController = TextEditingController();

  String? _selectedCategory;
  String? _selectedKind;

  Map<String, String> _categories = {};
  Map<String, String> _kinds = {};

  @override
  void initState() {
    super.initState();

    _categories['city'] = engine.locale('city');
    _categories['site'] = engine.locale('site');

    if (widget.category != null) {
      setCategory(category: widget.category!, kind: widget.kind);
    } else {
      setCategory(category: 'city');
    }
  }

  @override
  void dispose() {
    super.dispose();

    _idEditingController.dispose();
    _nameEditingController.dispose();
    _imageEditingController.dispose();
    _backgroundEditingController.dispose();
  }

  void setCategory({String? category, String? kind}) {
    if (category == null && kind == null) {
      return;
    }

    if (category != null) {
      _selectedCategory = category;

      _kinds.clear();
      _kinds['custom'] = engine.locale('custom');

      if (_selectedCategory == 'city') {
        _kinds.addAll(GameData.cityKindNames);
      } else if (_selectedCategory == 'site') {
        _kinds.addAll(GameData.siteKindNames);
      }
    }

    if (kind != null) {
      _selectedKind = kind;
    } else {
      _selectedKind = _kinds.keys.first;
    }

    if (GameData.siteKindNames.containsKey(_selectedKind)) {
      _idEditingController.text = _selectedKind!;
      _nameEditingController.text = engine.locale(_selectedKind);

      if (_selectedCategory == 'city') {
        _imageEditingController.text = '';
        _backgroundEditingController.text = 'city_plain_0_0.png';
      } else if (_selectedCategory == 'site') {
        _imageEditingController.text = 'location/card/$_selectedKind.png';
        _backgroundEditingController.text = 'location/site/$_selectedKind.png';
      }
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 400.0,
      height: 400.0,
      backgroundColor: GameUI.backgroundColor,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('editSite')),
          actions: const [CloseButton2()],
        ),
        body: Container(
          width: 400.0,
          height: 400.0,
          child: Column(
            children: [
              SizedBox(
                width: 320.0,
                height: 50.0,
                child: Row(
                  children: [
                    SizedBox(
                      width: 90.0,
                      child: Text(engine.locale('category')),
                    ),
                    SizedBox(
                      width: 100.0,
                      height: 50,
                      child: DropdownButton<String>(
                        style: GameUI.textTheme.bodyMedium,
                        value: _selectedCategory,
                        items: _categories.keys
                            .map(
                              (key) => DropdownMenuItem<String>(
                                value: key,
                                child: Text(_categories[key]!),
                              ),
                            )
                            .toList(),
                        onChanged: widget.allowEditCategory
                            ? (value) {
                                setCategory(category: value);
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 320.0,
                height: 50.0,
                child: Row(
                  children: [
                    SizedBox(
                      width: 90.0,
                      child: Text(engine.locale('kind')),
                    ),
                    SizedBox(
                      width: 100.0,
                      height: 50,
                      child: DropdownButton<String>(
                          style: GameUI.textTheme.bodyMedium,
                          value: _selectedKind,
                          items: _kinds.keys
                              .map(
                                (key) => DropdownMenuItem<String>(
                                  value: key,
                                  child: Text(_kinds[key]!),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            setCategory(kind: value);
                          }),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 320.0,
                    height: 40.0,
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 90.0,
                          child: Text('ID'),
                        ),
                        SizedBox(
                          width: 230.0,
                          height: 40.0,
                          child: TextField(
                            controller: _idEditingController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 320.0,
                    height: 40.0,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90.0,
                          child: Text('${engine.locale('name')}: '),
                        ),
                        SizedBox(
                          width: 230.0,
                          height: 40.0,
                          child: TextField(
                            controller: _nameEditingController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 320.0,
                    height: 40.0,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90.0,
                          child: Text('${engine.locale('image')}: '),
                        ),
                        SizedBox(
                          width: 230.0,
                          height: 40.0,
                          child: TextField(
                            controller: _imageEditingController,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 320.0,
                    height: 40.0,
                    child: Row(
                      children: [
                        SizedBox(
                          width: 90.0,
                          child: Text('${engine.locale('background')}: '),
                        ),
                        SizedBox(
                          width: 230.0,
                          height: 40.0,
                          child: TextField(
                            controller: _backgroundEditingController,
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
                    String? category = _selectedCategory?.nonEmptyValue;
                    String? kind = _selectedKind?.nonEmptyValue;
                    String? id = _idEditingController.text.nonEmptyValue;
                    String? name = _nameEditingController.text.nonEmptyValue;
                    String? image = _imageEditingController.text.nonEmptyValue;
                    String? background =
                        _backgroundEditingController.text.nonEmptyValue;

                    Navigator.of(context).pop((
                      category,
                      kind,
                      id,
                      name,
                      image,
                      background,
                    ));
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
