import 'package:flutter/material.dart';
import 'package:samsara/ui/responsive_view.dart';
import 'package:samsara/ui/close_button2.dart';
import 'package:samsara/extensions.dart' show StringEx;

import '../../engine.dart';
import '../../game/data.dart';
import '../../game/ui.dart';

/// 返回六个值的元组：
/// category, kind, id, name, image, background
class EditSite extends StatefulWidget {
  const EditSite({
    super.key,
    this.category,
    this.kind,
    this.id,
    this.name,
    this.image,
    this.background,
    this.allowEditType = true,
  });

  final String? category;
  final String? kind;
  final String? id;
  final String? name;
  final String? image;
  final String? background;

  final bool allowEditType;

  @override
  State<EditSite> createState() => _EditSiteState();
}

class _EditSiteState extends State<EditSite> {
  final _idEditingController = TextEditingController();
  final _nameEditingController = TextEditingController();
  final _imageEditingController = TextEditingController();
  final _backgroundEditingController = TextEditingController();

  String? _selectedCategory;
  String? _selectedKind;

  final Map<String, String> _categories = {};
  final Map<String, String> _kinds = {};

  @override
  void initState() {
    super.initState();

    _categories['city'] = engine.locale('city');
    _categories['site'] = engine.locale('site');

    if (widget.category != null) {
      setCategory(category: widget.category!, kind: widget.kind);
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
    if (category == null && category == null) {
      return;
    }

    if (_selectedCategory != category) {
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
      if (GameData.siteKindNames.containsKey(kind)) {
        _idEditingController.text = _selectedKind!;
        _nameEditingController.text = engine.locale(_selectedKind);

        if (_selectedCategory == 'city') {
          _imageEditingController.text = '';
          _backgroundEditingController.text = 'city_plain_0_0.png';
        } else if (_selectedCategory == 'site') {
          _imageEditingController.text = 'location/card/$_selectedKind.png';
          _backgroundEditingController.text =
              'location/site/$_selectedKind.png';
        }
      }
    } else {
      _selectedKind = _kinds.keys.first;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      width: 350.0,
      height: 400.0,
      color: GameUI.backgroundColor,
      alignment: AlignmentDirectional.center,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Text(engine.locale('editSite')),
          actions: const [CloseButton2()],
        ),
        body: Container(
          width: 350.0,
          height: 400.0,
          alignment: AlignmentDirectional.center,
          child: Column(
            children: [
              SizedBox(
                width: 280.0,
                child: Row(
                  children: [
                    SizedBox(
                      width: 80.0,
                      child: Text(engine.locale('category')),
                    ),
                    Container(
                      width: 150.0,
                      height: 80,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 20.0),
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
                          onChanged: (value) {
                            setCategory(category: value);
                          }),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 280.0,
                child: Row(
                  children: [
                    SizedBox(
                      width: 80.0,
                      child: Text(engine.locale('kind')),
                    ),
                    Container(
                      width: 150.0,
                      height: 80,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10.0, vertical: 20.0),
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
                          child: Text('${engine.locale('name')}: '),
                        ),
                        SizedBox(
                          width: 190.0,
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
                          child: Text('${engine.locale('image')}: '),
                        ),
                        SizedBox(
                          width: 190.0,
                          height: 40.0,
                          child: TextField(
                            controller: _imageEditingController,
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
                          child: Text('${engine.locale('background')}: '),
                        ),
                        SizedBox(
                          width: 190.0,
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
